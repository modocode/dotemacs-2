;;; modules/nix-config.el --- NixOS/Nix development support -*- lexical-binding: t; -*-
;;
;; Provides:
;;   nix-mode    — syntax highlighting, indentation, nixfmt on save
;;   envrc       — buffer-local direnv integration (guarded by direnv binary)
;;   Helpers     — open shell file, create .envrc, direnv allow, run nix shell
;;   SPC n       — leader prefix for all nix commands
;;
;; Load order: modules/ is loaded alphabetically. keybindings.el (k) loads
;; before nix-config.el (n), so my/leader is defined when we call it here.

;;; ── nix-mode ─────────────────────────────────────────────────────────────────
;; Syntax highlighting, indentation, and nixfmt integration for .nix files.
;; No :demand t needed — the :mode auto-load trigger is sufficient.

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'"
  :custom
  ;; nixfmt is the official formatter as of Nix 2.18+.
  ;; Override to "nixpkgs-fmt" in os/linux.el if your setup uses the older tool.
  (nix-nixfmt-bin "nixfmt"))

;;; ── envrc ────────────────────────────────────────────────────────────────────
;; Integrates direnv with Emacs by setting process-environment buffer-locally.
;; This is the critical detail: eglot (and compile, eshell, etc.) inherit the
;; buffer's environment, so they find the nix-shell's LSP server and tools —
;; not whatever happens to be on the system PATH.
;;
;; Guarded by my/with-binary so Emacs boots cleanly without direnv installed.

(my/with-binary "direnv"
  (use-package envrc
    :ensure t
    :demand t   ; envrc-global-mode must activate at startup, not lazily
    :config
    (envrc-global-mode)))

;;; ── Helper: Shell Type ───────────────────────────────────────────────────────

(defun my/nix-shell-type ()
  "Return the Nix shell type for the current project.

Searches upward from `default-directory' for flake.nix then shell.nix.
Returns :flake, :shell, or nil.  When called interactively (SPC n t),
also prints the result to the minibuffer."
  (interactive)
  (let ((type (cond
               ((locate-dominating-file default-directory "flake.nix") :flake)
               ((locate-dominating-file default-directory "shell.nix")  :shell)
               (t nil))))
    (when (called-interactively-p 'any)
      (message "[nix] Shell type: %s" (or type "none (no flake.nix or shell.nix found)")))
    type))

;;; ── Helper: Open Shell File ──────────────────────────────────────────────────

(defun my/nix-open-shell-file ()
  "Open flake.nix or shell.nix for the current project.

Prefers flake.nix (modern standard).  Signals a user-error if neither
exists above `default-directory'."
  (interactive)
  (let* ((flake-root (locate-dominating-file default-directory "flake.nix"))
         (shell-root (locate-dominating-file default-directory "shell.nix"))
         (file (cond
                (flake-root (expand-file-name "flake.nix" flake-root))
                (shell-root (expand-file-name "shell.nix" shell-root))
                (t nil))))
    (if file
        (find-file file)
      (user-error "[nix] No flake.nix or shell.nix found above %s"
                  default-directory))))

;;; ── Helper: Create .envrc ────────────────────────────────────────────────────

(defun my/nix-create-envrc ()
  "Create a .envrc at the project root with the appropriate nix directive.

  flake.nix project  →  use flake
  shell.nix project  →  use nix
  neither found      →  use flake  (sane default)

Refuses to overwrite an existing .envrc.  Offers to run `direnv allow'
immediately after writing."
  (interactive)
  (let* ((root (or (locate-dominating-file default-directory "flake.nix")
                   (locate-dominating-file default-directory "shell.nix")
                   default-directory))
         (envrc-path (expand-file-name ".envrc" root))
         (content (pcase (my/nix-shell-type)
                    (:flake "use flake\n")
                    (:shell "use nix\n")
                    (_      "use flake\n"))))
    (when (file-exists-p envrc-path)
      (user-error "[nix] .envrc already exists at %s" envrc-path))
    (with-temp-file envrc-path
      (insert content))
    (message "[nix] Created %s" envrc-path)
    (when (and (executable-find "direnv")
               (yes-or-no-p "Run `direnv allow' now? "))
      (my/nix-direnv-allow))))

;;; ── Helper: direnv allow ─────────────────────────────────────────────────────

(defun my/nix-direnv-allow ()
  "Run `direnv allow' at the project root containing .envrc.

Searches upward from `default-directory'.  Runs synchronously (fast op —
direnv allow just writes to .direnv/) and reports success or failure.
Refreshes the current buffer's environment via envrc-reload on success."
  (interactive)
  (unless (executable-find "direnv")
    (user-error "[nix] `direnv' is not on PATH"))
  (let ((root (locate-dominating-file default-directory ".envrc")))
    (unless root
      (user-error "[nix] No .envrc found above %s" default-directory))
    (let* ((default-directory root)
           (exit-code (call-process "direnv" nil nil nil "allow")))
      (if (zerop exit-code)
          (progn
            (message "[nix] direnv allow succeeded in %s" root)
            (when (fboundp 'envrc-reload)
              (envrc-reload)))
        (user-error "[nix] `direnv allow' failed (exit %d) in %s"
                    exit-code root)))))

;;; ── Helper: Load Nix Environment into Buffer ─────────────────────────────────
;;
;; The core problem: eglot runs as an Emacs subprocess and inherits the Emacs
;; process's PATH — not whatever nix-shell you opened in a terminal.  The fix is
;; to pull the nix shell's env vars into `process-environment' buffer-locally,
;; the same mechanism `envrc' uses for direnv, but driven directly by nix.
;;
;; For flake.nix : `nix print-dev-env --json'
;;   — Fast: evaluates the devShell without starting a shell process.
;;   — Output: JSON with all exported variables and their values.
;;
;; For shell.nix  : `nix-shell --run "env -0"'
;;   — Starts a nix-shell, runs env(1) with null-byte separators, exits.
;;   — Null separation handles values that contain newlines or spaces.
;;
;; Both commands run asynchronously so Emacs stays responsive during the
;; potentially multi-second Nix evaluation.

(defun my/nix--parse-dev-env-json (json-str)
  "Extract exported variables from `nix print-dev-env --json' output.
Returns an alist of (NAME . VALUE) strings, or signals a user-error."
  (condition-case err
      (let* ((data      (json-parse-string json-str :object-type 'alist))
             (variables (alist-get 'variables data)))
        (delq nil
              (mapcar (lambda (entry)
                        (let* ((name  (symbol-name (car entry)))
                               (props (cdr entry))
                               (type  (alist-get 'type  props))
                               (value (alist-get 'value props)))
                          (when (and (stringp type)
                                     (string= type "exported")
                                     (stringp value))
                            (cons name value))))
                      variables)))
    (error
     (user-error "[nix] Failed to parse nix print-dev-env output: %s" err))))

(defun my/nix--apply-env-alist (env-alist buf)
  "Apply ENV-ALIST to BUF's buffer-local `process-environment' and `exec-path'.
Vars in ENV-ALIST override matching existing entries; others are kept.
`exec-path' is also updated so `executable-find' and eglot locate tools
from the nix shell rather than the system PATH."
  (with-current-buffer buf
    (let* ((override-names (mapcar #'car env-alist))
           (kept (cl-remove-if
                  (lambda (entry)
                    (let ((eq-pos (string-search "=" entry)))
                      (and eq-pos
                           (member (substring entry 0 eq-pos) override-names))))
                  process-environment))
           (new-entries (mapcar (lambda (pair)
                                  (concat (car pair) "=" (cdr pair)))
                                env-alist)))
      (setq-local process-environment (append new-entries kept))
      ;; Sync exec-path from the new PATH so executable-find (used by eglot to
      ;; locate the LSP binary) searches the nix shell's directories first.
      (when-let* ((path-entry (cl-find-if (lambda (e) (string-prefix-p "PATH=" e))
                                          process-environment))
                  (path-str   (substring path-entry 5)))
        (setq-local exec-path (append (split-string path-str ":" t)
                                      (list exec-directory))))
      (message "[nix] Loaded %d vars — run M-x eglot (or C-u SPC n l) to start LSP"
               (length env-alist)))))

(defun my/nix-load-env (&optional restart-eglot)
  "Load the Nix shell environment into the current buffer's process-environment.

For flake.nix : runs `nix print-dev-env --json' (fast — no shell spawned).
For shell.nix  : runs `nix-shell --run env -0' (null-separated KEY=VAL pairs).

Sets `process-environment' buffer-locally so eglot, compile, M-!, and other
Emacs subprocesses inherit the nix shell PATH and tooling.

With prefix arg (\\[universal-argument]), also restarts eglot after loading so
the LSP server is picked up from the nix shell immediately."
  (interactive "P")
  (unless (executable-find "nix")
    (user-error "[nix] `nix' not found on PATH"))
  (let* ((shell-type (my/nix-shell-type))
         (root (or (locate-dominating-file default-directory "flake.nix")
                   (locate-dominating-file default-directory "shell.nix")))
         (default-directory (or root default-directory))
         (buf (current-buffer))
         (cmd (pcase shell-type
                (:flake (list "nix" "print-dev-env" "--json"))
                (:shell (list "nix-shell" "--run" "env -0"))
                (_ (user-error "[nix] No flake.nix or shell.nix found above %s"
                               default-directory))))
         (out-buf (generate-new-buffer " *nix-load-env-output*")))
    (message "[nix] Loading environment… (may take a moment on first run)")
    (make-process
     :name     "nix-load-env"
     :buffer   out-buf
     :command  cmd
     :sentinel
     (lambda (proc event)
       (cond
        ((string-prefix-p "finished" event)
         (let* ((raw (with-current-buffer out-buf (buffer-string)))
                (env-alist
                 (pcase shell-type
                   (:flake (my/nix--parse-dev-env-json raw))
                   (:shell
                    (delq nil
                          (mapcar (lambda (entry)
                                    (let ((eq-pos (string-search "=" entry)))
                                      (when eq-pos
                                        (cons (substring entry 0 eq-pos)
                                              (substring entry (1+ eq-pos))))))
                                  (split-string raw "\0" t)))))))
           (kill-buffer out-buf)
           (my/nix--apply-env-alist env-alist buf)
           (when restart-eglot
             (with-current-buffer buf
               (when (fboundp 'eglot-shutdown)
                 (ignore-errors (eglot-shutdown (eglot-current-server))))
               (call-interactively #'eglot)))))
        ((string-prefix-p "exited" event)
         (kill-buffer out-buf)
         (user-error "[nix] env loading failed — check *Messages* for details")))))))

;;; ── Helper: Run Nix Shell ────────────────────────────────────────────────────

(defun my/nix-run-shell ()
  "Open an eshell buffer at the project root and start an interactive nix shell.

Uses `nix develop' for flake.nix projects and `nix-shell' for shell.nix.
The eshell buffer is named *nix-shell:PROJECTNAME* and is reused if already
open, so repeated calls don't create duplicate shells."
  (interactive)
  (unless (executable-find "nix")
    (user-error "[nix] `nix' is not on PATH"))
  (let* ((shell-type (my/nix-shell-type))
         (root (or (locate-dominating-file default-directory "flake.nix")
                   (locate-dominating-file default-directory "shell.nix")))
         (cmd (pcase shell-type
                (:flake "nix develop")
                (:shell "nix-shell")
                (_ (user-error "[nix] No flake.nix or shell.nix found")))))
    (let* ((default-directory (or root default-directory))
           (project-name (file-name-nondirectory
                          (directory-file-name default-directory)))
           (buf-name (format "*nix-shell:%s*" project-name)))
      (if-let* ((existing (get-buffer buf-name)))
          (pop-to-buffer existing)
        (let ((eshell-buffer-name buf-name))
          (eshell)))
      (with-current-buffer (get-buffer buf-name)
        (goto-char (point-max))
        (insert cmd)
        (eshell-send-input)))))

;;; ── Project Environment Status ───────────────────────────────────────────────
;; Like SPC X (Emacs health check) but scoped to the current buffer/project:
;; shows what nix shell is present, whether the env is loaded, which LSP
;; servers are visible on the current PATH, and eglot's status.

(defconst my/nix--lsp-servers
  '(("nixd"               . "Nix")
    ("nil"                . "Nix (nil)")
    ("clangd"             . "C/C++")
    ("pyright-langserver" . "Python")
    ("pylsp"              . "Python (pylsp)")
    ("rust-analyzer"      . "Rust")
    ("zls"                . "Zig")
    ("gopls"              . "Go"))
  "LSP server binaries checked by `my/nix-env-status'.")

(defun my/nix--env-path ()
  "Return the PATH string from the current buffer's process-environment."
  (when-let* ((e (cl-find-if (lambda (s) (string-prefix-p "PATH=" s))
                              process-environment)))
    (substring e 5)))

(defun my/nix--nix-path-p (path-str)
  "Return t if PATH-STR contains any /nix/store/ entries."
  (and path-str
       (cl-some (lambda (d) (string-prefix-p "/nix/store/" d))
                (split-string path-str ":" t))))

(defun my/nix--status-row (ok label detail &optional fix optional)
  "Insert one status row.  FIX is shown as a hint when OK is nil."
  (insert (propertize (cond (ok       "  ✓  ")
                            (optional "  ⚠  ")
                            (t        "  ✗  "))
                      'face (cond (ok 'success) (optional 'warning) (t 'error))))
  (insert (propertize (format "%-24s" label)
                      'face (if ok 'default (if optional 'warning 'error))))
  (insert (propertize (or detail "") 'face 'shadow))
  (insert "\n")
  (when (and fix (not ok))
    (insert (propertize (format "     └─ %s\n" fix) 'face 'italic))))

(defun my/nix--status-section (title)
  "Insert a bold section header."
  (insert (propertize (concat title "\n") 'face '(:weight bold)))
  (insert (propertize (concat (make-string 62 ?─) "\n") 'face 'shadow)))

(defun my/nix-env-status ()
  "Show the Nix programming environment status for the current buffer.

Displays a *Nix Environment* report covering:
  - Project type (flake.nix / shell.nix / none)
  - Whether the nix env is loaded into this buffer (process-environment + exec-path)
  - Which LSP servers are visible on the current PATH
  - eglot's running status and which server it connected to
  - .envrc / direnv status

Press g to refresh, q to close."
  (interactive)
  ;; Snapshot all data while still in the source buffer's dynamic environment.
  (let* ((src          (current-buffer))
         (dir          default-directory)
         (shell-type   (my/nix-shell-type))
         (root         (or (locate-dominating-file dir "flake.nix")
                           (locate-dominating-file dir "shell.nix")
                           dir))
         (envrc-path   (expand-file-name ".envrc" root))
         (env-local    (local-variable-p 'process-environment))
         (cur-path     (my/nix--env-path))
         (nix-on-path  (my/nix--nix-path-p cur-path))
         (lsp-results  (mapcar (lambda (pair)
                                 (list (car pair) (cdr pair)
                                       (executable-find (car pair))))
                               my/nix--lsp-servers))
         (eglot-srv    (and (fboundp 'eglot-current-server)
                            (ignore-errors (eglot-current-server))))
         (eglot-name   (when eglot-srv
                         (ignore-errors (jsonrpc-name eglot-srv))))
         (direnv-dir   (ignore-errors
                         (buffer-local-value 'envrc--envrc-directory src)))
         (rep          (get-buffer-create "*Nix Environment*")))

    (with-current-buffer rep
      (let ((inhibit-read-only t))
        (erase-buffer)

        ;; ── Header ────────────────────────────────────────────────────────────
        (insert (propertize (make-string 62 ?━) 'face 'shadow) "\n")
        (insert (propertize "  Nix Environment Status\n"
                            'face '(:weight bold :height 1.3)))
        (insert (propertize (make-string 62 ?─) 'face 'shadow) "\n")
        (insert (format "  %-14s %s\n" "Buffer:" (buffer-name src)))
        (insert (format "  %-14s %s\n" "Directory:" dir))
        (insert (propertize (make-string 62 ?━) 'face 'shadow) "\n\n")

        ;; ── Project ───────────────────────────────────────────────────────────
        (my/nix--status-section "PROJECT")
        (my/nix--status-row
         (not (null shell-type))
         "Shell type"
         (pcase shell-type
           (:flake "flake.nix   →  nix develop")
           (:shell "shell.nix   →  nix-shell")
           (_ "none"))
         (format "Create flake.nix or shell.nix in %s" root))
        (my/nix--status-row
         (file-exists-p envrc-path)
         ".envrc"
         (if (file-exists-p envrc-path) envrc-path "not found")
         "SPC n e — create .envrc"
         t)
        (insert "\n")

        ;; ── Environment ───────────────────────────────────────────────────────
        (my/nix--status-section "ENVIRONMENT")
        (my/nix--status-row
         (and env-local nix-on-path)
         "Nix env loaded"
         (cond
          ((and env-local nix-on-path) "yes — /nix/store/ on PATH")
          (env-local "partial — buffer-local env set but no nix paths")
          (t "no — using system PATH"))
         (when shell-type
           "SPC n l — load env  |  C-u SPC n l — load + restart eglot"))
        (my/nix--status-row
         (not (null direnv-dir))
         "direnv"
         (cond
          (direnv-dir (format "active (%s)" direnv-dir))
          ((executable-find "direnv") "installed — not active in this buffer")
          (t "not installed"))
         (when (and (executable-find "direnv")
                    (not direnv-dir)
                    (file-exists-p envrc-path))
           "SPC n a — run direnv allow")
         t)
        (insert "\n")

        ;; ── LSP Servers ───────────────────────────────────────────────────────
        (my/nix--status-section "LSP SERVERS  (visible on current PATH)")
        (let ((any-found nil))
          (dolist (entry lsp-results)
            (cl-destructuring-bind (bin lang path) entry
              (when path (setq any-found t))
              (my/nix--status-row
               (not (null path))
               bin
               (if path (format "%s  [%s]" path lang) (format "not found  [%s]" lang))
               nil t)))
          (unless any-found
            (insert (propertize "     No LSP servers found on current PATH.\n" 'face 'warning))
            (insert (propertize "     Load the nix env first: SPC n l\n" 'face 'italic))))
        (insert "\n")

        ;; ── eglot ─────────────────────────────────────────────────────────────
        (my/nix--status-section "EGLOT")
        (my/nix--status-row
         (not (null eglot-srv))
         "LSP connection"
         (if eglot-srv
             (format "running — %s" (or eglot-name "server"))
           "stopped")
         (if (and env-local nix-on-path)
             "M-x eglot — start LSP"
           "Load nix env first (SPC n l), then M-x eglot"))
        (insert "\n")

        ;; ── Quick actions ─────────────────────────────────────────────────────
        (my/nix--status-section "QUICK ACTIONS")
        (dolist (row '(("SPC n l     " . "load nix env into this buffer")
                       ("C-u SPC n l " . "load nix env + restart eglot")
                       ("SPC n c     " . "refresh this status buffer")
                       ("SPC n e     " . "create .envrc")
                       ("SPC n a     " . "direnv allow")
                       ("SPC n r     " . "reload direnv")))
          (insert (propertize (format "  %s  " (car row)) 'face 'bold))
          (insert (propertize (cdr row) 'face 'shadow))
          (insert "\n"))
        (insert "\n")
        (insert (propertize (make-string 62 ?━) 'face 'shadow) "\n")
        (insert (propertize (format "  [%s]  g = refresh  q = close\n"
                                    (format-time-string "%H:%M:%S"))
                            'face 'shadow)))

      (goto-char (point-min))
      (special-mode)
      (let ((source src))
        (local-set-key (kbd "g") (lambda ()
                                   (interactive)
                                   (with-current-buffer source
                                     (my/nix-env-status))))
        (local-set-key (kbd "q") #'quit-window)))
    (pop-to-buffer rep)))

;;; ── eglot: Nix LSP Registration ─────────────────────────────────────────────
;; Registers nixd (preferred) or nil (NIx Language server) with eglot.
;; Both are optional — nix-mode stays useful without either (highlighting,
;; indentation, nixfmt still work).

(with-eval-after-load 'eglot
  (cond
   ((executable-find "nixd")
    (add-to-list 'eglot-server-programs '(nix-mode . ("nixd"))))
   ((executable-find "nil")
    (add-to-list 'eglot-server-programs '(nix-mode . ("nil"))))))

;;; ── Keybindings ──────────────────────────────────────────────────────────────

(my/leader
  "n"   '(:ignore t                  :which-key "nix")
  "n o" '(my/nix-open-shell-file     :which-key "open shell file")
  "n e" '(my/nix-create-envrc        :which-key "create .envrc")
  "n a" '(my/nix-direnv-allow        :which-key "direnv allow")
  "n c" '(my/nix-env-status          :which-key "env status")
  "n l" '(my/nix-load-env            :which-key "load env → eglot")
  "n s" '(my/nix-run-shell           :which-key "run nix shell")
  "n t" '(my/nix-shell-type          :which-key "show shell type")
  "n r" '(envrc-reload               :which-key "reload envrc"))

;;; ── Health Registration ───────────────────────────────────────────────────────

(with-eval-after-load 'mo-health
  (add-to-list 'my/health-check-features 'nix-config t)

  (add-to-list 'my/health-check-binaries
               '(:bin "nix"
                 :desc "Nix package manager"
                 :optional t
                 :linux   "sh <(curl -L https://nixos.org/nix/install) --daemon"
                 :macos   "sh <(curl -L https://nixos.org/nix/install)"
                 :windows "WSL2 + Linux install recommended")
               t)

  (add-to-list 'my/health-check-binaries
               '(:bin "direnv"
                 :desc "direnv — auto-loads nix shells via envrc"
                 :optional t
                 :linux   "nix profile install nixpkgs#direnv  # or: sudo apt install direnv"
                 :macos   "brew install direnv"
                 :windows "scoop install direnv")
               t)

  (add-to-list 'my/health-check-binaries
               '(:bin "nixd"
                 :desc "nixd — Nix language server for eglot (preferred over nil)"
                 :optional t
                 :linux   "nix profile install nixpkgs#nixd"
                 :macos   "nix profile install nixpkgs#nixd"
                 :windows "N/A — use WSL2")
               t))

(provide 'nix-config)
;;; nix-config.el ends here
