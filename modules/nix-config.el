;;; modules/nix-config.el --- NixOS/Nix development support -*- lexical-binding: t; -*-
;;
;; PROBLEM THIS MODULE SOLVES
;; ──────────────────────────
;; Three bottlenecks existed between "open a nix project" and "LSP works":
;;
;;   1. TIMING RACE — eglot-ensure fires from the major-mode hook, which runs
;;      BEFORE find-file-hook.  envrc-global-mode hooks into find-file-hook, so
;;      by the time eglot looks for the LSP binary, envrc hasn't applied the
;;      nix devshell's PATH yet.  LSP silently fails to start.
;;
;;   2. NO .envrc — New projects need manual: SPC n e → SPC n a → wait.
;;
;;   3. NO flake.nix — Bootstrapping a new project requires writing nix by hand.
;;
;; WHAT THIS MODULE DOES
;; ──────────────────────
;;   A. envrc→eglot bridge  — advises `envrc--apply'; starts eglot in the same
;;      buffer after the nix env is applied.  Fixes the timing race for ALL
;;      supported modes (Python, C/C++, Zig, Nix).
;;
;;   B. Auto-setup prompt   — on find-file-hook, detects a nix project without
;;      .envrc and offers (once per project, non-blocking) to create + allow it.
;;
;;   C. Flake scaffold      — `my/nix-new-flake' (SPC n N) generates a
;;      language-specific flake.nix using flake-utils for cross-platform devShells.
;;
;;   D. One-shot setup      — `my/nix-project-setup' (SPC n S) wires up a full
;;      project in one command: create .envrc → direnv allow → reload → start eglot.
;;
;; LOAD ORDER
;; ──────────
;; keybindings.el (k) loads before nix-config.el (n), so my/leader is defined.
;; lang-lsp.el (l) loads before nix-config.el (n), so my/use-eglot is defined.

;;; ── nix-mode ─────────────────────────────────────────────────────────────────
;; Syntax highlighting, indentation, and nixfmt integration for .nix files.
;; :mode is a sufficient trigger — no :demand t needed.

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'"
  :custom
  ;; nixfmt is the official formatter as of Nix 2.18+.
  ;; Override to "nixpkgs-fmt" in os/linux.el if your setup uses the older tool.
  (nix-nixfmt-bin "nixfmt"))

;;; ── envrc ────────────────────────────────────────────────────────────────────
;; Integrates direnv with Emacs by setting process-environment buffer-locally.
;; This is the mechanism that makes eglot (and compile, eshell, etc.) find the
;; nix-shell's LSP server and tools instead of whatever's on the system PATH.
;;
;; Guarded by my/with-binary so Emacs boots cleanly without direnv installed.

(my/with-binary "direnv"
  (use-package envrc
    :ensure t
    :demand t   ; envrc-global-mode must activate at startup, not lazily
    :config
    (envrc-global-mode)))

;;; ────────────────────────────────────────────────────────────────────────────
;;; ── A. envrc → eglot Bridge ──────────────────────────────────────────────────
;;; ────────────────────────────────────────────────────────────────────────────
;;
;; WHY THIS IS NEEDED
;; ──────────────────
;; Emacs's find-file sequence:
;;
;;   find-file-noselect
;;     → major-mode function (e.g. python-mode)
;;         → python-mode-hook fires → eglot-ensure runs here
;;     → find-file-hook fires → envrc--update runs here
;;                                  → envrc--apply sets process-environment
;;
;; eglot-ensure sees the *global* PATH (missing nix tools) and either fails
;; silently or picks up a stale system binary.  By the time envrc is done,
;; eglot has already given up.
;;
;; THE FIX
;; ───────
;; Advise envrc--apply with :after.  When envrc successfully applies a nix env
;; (detectable by /nix/store/ on PATH), call eglot-ensure in that buffer.
;; eglot-ensure is idempotent — if a server is already running it's a no-op.

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

(defun my/nix--maybe-start-eglot ()
  "Start eglot if the nix env is loaded and the current mode needs it.
Safe to call repeatedly — eglot-ensure is a no-op when already running."
  (when (and (bound-and-true-p my/use-eglot)
             (fboundp 'eglot-ensure)
             ;; Only if eglot isn't already running in this buffer.
             (not (and (fboundp 'eglot-current-server)
                       (eglot-current-server)))
             ;; Only if a nix devshell is actually on the PATH.
             (my/nix--nix-path-p (my/nix--env-path))
             ;; Only in modes eglot supports (add more here as needed).
             (apply #'derived-mode-p
                    '(python-mode python-ts-mode
                      c-mode c++-mode c-ts-mode c++-ts-mode
                      zig-mode nix-mode)))
    (eglot-ensure)))

(defun my/nix--after-envrc-apply (buf result)
  "After envrc applies env to BUF, start eglot if appropriate.
RESULT is an alist on success, or the symbol \\='none or \\='error on failure.
This function is advised after `envrc--apply'."
  (when (and (buffer-live-p buf)
             (listp result))   ; alist = success; 'none/'error = skip
    (with-current-buffer buf
      (my/nix--maybe-start-eglot))))

;; Add the advice only after envrc loads (it may not load if direnv isn't found).
(with-eval-after-load 'envrc
  (advice-add 'envrc--apply :after #'my/nix--after-envrc-apply))

;;; ────────────────────────────────────────────────────────────────────────────
;;; ── B. Auto-setup: .envrc creation prompt ────────────────────────────────────
;;; ────────────────────────────────────────────────────────────────────────────
;;
;; When visiting a file in a nix project that has no .envrc, offer to create
;; one and run direnv allow automatically.  The prompt is deferred 0.3s so it
;; appears after the buffer is visible (non-blocking find-file).
;;
;; "No" is remembered per project-root for the session so you're not asked again.

(defvar my/nix--declined-setup (make-hash-table :test 'equal)
  "Hash set of project roots where the user declined auto .envrc setup.
Populated by `my/nix--auto-setup-maybe'; cleared on Emacs restart.")

(defun my/nix--auto-setup-maybe ()
  "Offer to create .envrc when visiting a nix project without one.
Runs from find-file-hook.  Skips special buffers, remote files, and
projects where the user already declined this session."
  (when (and buffer-file-name                        ; real file, not scratch
             (not (file-remote-p buffer-file-name))  ; not tramp
             (executable-find "direnv")
             (my/nix-shell-type))                    ; has flake.nix or shell.nix
    (let* ((root (or (locate-dominating-file default-directory "flake.nix")
                     (locate-dominating-file default-directory "shell.nix"))))
      (when (and root
                 (not (locate-dominating-file default-directory ".envrc"))
                 (not (gethash root my/nix--declined-setup)))
        ;; Defer so the buffer is fully displayed before the prompt.
        (run-with-timer
         0.3 nil
         (lambda (root-dir source-buf)
           (when (buffer-live-p source-buf)
             (with-current-buffer source-buf
               (if (yes-or-no-p
                    (format "[nix] %s has no .envrc. Create one and run direnv allow? "
                            (abbreviate-file-name root-dir)))
                   (progn
                     (let ((default-directory root-dir))
                       (my/nix-create-envrc--silent)))
                 (puthash root-dir t my/nix--declined-setup)))))
         root (current-buffer))))))

(add-hook 'find-file-hook #'my/nix--auto-setup-maybe)

;;; ────────────────────────────────────────────────────────────────────────────
;;; ── C. Flake Scaffold ────────────────────────────────────────────────────────
;;; ────────────────────────────────────────────────────────────────────────────
;;
;; `my/nix-new-flake' (SPC n N) generates a starter flake.nix.
;; Templates use flake-utils for cross-platform devShells (works on
;; x86_64-linux, aarch64-linux, aarch64-darwin, x86_64-darwin).
;;
;; After writing the file, offers to create .envrc + direnv allow so the
;; project is ready to use immediately.

(defvar my/nix-flake-templates
  `(("python"
     "Python 3 + basedpyright LSP"
     ,(concat
       "{\n"
       "  inputs = {\n"
       "    nixpkgs.url     = \"github:NixOS/nixpkgs/nixos-unstable\";\n"
       "    flake-utils.url = \"github:numtide/flake-utils\";\n"
       "  };\n"
       "\n"
       "  outputs = { self, nixpkgs, flake-utils }:\n"
       "    flake-utils.lib.eachDefaultSystem (system:\n"
       "      let pkgs = nixpkgs.legacyPackages.${system};\n"
       "      in {\n"
       "        devShells.default = pkgs.mkShell {\n"
       "          packages = with pkgs; [\n"
       "            python3\n"
       "            python3Packages.pip\n"
       "            basedpyright    # LSP — picked up by eglot automatically\n"
       "          ];\n"
       "        };\n"
       "      });\n"
       "}\n"))

    ("c-cpp"
     "C / C++ + clangd LSP"
     ,(concat
       "{\n"
       "  inputs = {\n"
       "    nixpkgs.url     = \"github:NixOS/nixpkgs/nixos-unstable\";\n"
       "    flake-utils.url = \"github:numtide/flake-utils\";\n"
       "  };\n"
       "\n"
       "  outputs = { self, nixpkgs, flake-utils }:\n"
       "    flake-utils.lib.eachDefaultSystem (system:\n"
       "      let pkgs = nixpkgs.legacyPackages.${system};\n"
       "      in {\n"
       "        devShells.default = pkgs.mkShell {\n"
       "          packages = with pkgs; [\n"
       "            gcc\n"
       "            clang-tools    # includes clangd — LSP for eglot\n"
       "            cmake\n"
       "            ninja\n"
       "            bear           # generates compile_commands.json for clangd\n"
       "          ];\n"
       "        };\n"
       "      });\n"
       "}\n"))

    ("zig"
     "Zig + zls LSP"
     ,(concat
       "{\n"
       "  inputs = {\n"
       "    nixpkgs.url     = \"github:NixOS/nixpkgs/nixos-unstable\";\n"
       "    flake-utils.url = \"github:numtide/flake-utils\";\n"
       "  };\n"
       "\n"
       "  outputs = { self, nixpkgs, flake-utils }:\n"
       "    flake-utils.lib.eachDefaultSystem (system:\n"
       "      let pkgs = nixpkgs.legacyPackages.${system};\n"
       "      in {\n"
       "        devShells.default = pkgs.mkShell {\n"
       "          packages = with pkgs; [\n"
       "            zig\n"
       "            zls    # LSP — picked up by eglot automatically\n"
       "          ];\n"
       "        };\n"
       "      });\n"
       "}\n"))

    ("rust"
     "Rust stable + rust-analyzer LSP"
     ,(concat
       "{\n"
       "  inputs = {\n"
       "    nixpkgs.url     = \"github:NixOS/nixpkgs/nixos-unstable\";\n"
       "    flake-utils.url = \"github:numtide/flake-utils\";\n"
       "  };\n"
       "\n"
       "  outputs = { self, nixpkgs, flake-utils }:\n"
       "    flake-utils.lib.eachDefaultSystem (system:\n"
       "      let pkgs = nixpkgs.legacyPackages.${system};\n"
       "      in {\n"
       "        devShells.default = pkgs.mkShell {\n"
       "          packages = with pkgs; [\n"
       "            rustc\n"
       "            cargo\n"
       "            rust-analyzer    # LSP — picked up by eglot automatically\n"
       "            rustfmt\n"
       "            clippy\n"
       "          ];\n"
       "        };\n"
       "      });\n"
       "}\n"))

    ("go"
     "Go + gopls LSP"
     ,(concat
       "{\n"
       "  inputs = {\n"
       "    nixpkgs.url     = \"github:NixOS/nixpkgs/nixos-unstable\";\n"
       "    flake-utils.url = \"github:numtide/flake-utils\";\n"
       "  };\n"
       "\n"
       "  outputs = { self, nixpkgs, flake-utils }:\n"
       "    flake-utils.lib.eachDefaultSystem (system:\n"
       "      let pkgs = nixpkgs.legacyPackages.${system};\n"
       "      in {\n"
       "        devShells.default = pkgs.mkShell {\n"
       "          packages = with pkgs; [\n"
       "            go\n"
       "            gopls       # LSP — picked up by eglot automatically\n"
       "            gotools\n"
       "            delve       # debugger\n"
       "          ];\n"
       "        };\n"
       "      });\n"
       "}\n"))

    ("nix"
     "Nix + nixd LSP (for editing nix files)"
     ,(concat
       "{\n"
       "  inputs = {\n"
       "    nixpkgs.url     = \"github:NixOS/nixpkgs/nixos-unstable\";\n"
       "    flake-utils.url = \"github:numtide/flake-utils\";\n"
       "  };\n"
       "\n"
       "  outputs = { self, nixpkgs, flake-utils }:\n"
       "    flake-utils.lib.eachDefaultSystem (system:\n"
       "      let pkgs = nixpkgs.legacyPackages.${system};\n"
       "      in {\n"
       "        devShells.default = pkgs.mkShell {\n"
       "          packages = with pkgs; [\n"
       "            nixd        # Nix LSP — picked up by eglot automatically\n"
       "            nixfmt-rfc-style\n"
       "            statix      # nix linter\n"
       "            deadnix     # remove dead code\n"
       "          ];\n"
       "        };\n"
       "      });\n"
       "}\n")))
  "Alist of (KEY DESCRIPTION CONTENT) flake.nix templates.
Used by `my/nix-new-flake' (SPC n N).")

(defun my/nix-new-flake ()
  "Scaffold a flake.nix at the current project root.

Prompts for a language template, writes flake.nix, then opens it.
Offers to create .envrc and run direnv allow so the project is ready
immediately after the flake is built by nix."
  (interactive)
  (unless (executable-find "nix")
    (user-error "[nix] `nix' not found on PATH"))
  (let* ((root (or (locate-dominating-file default-directory ".git")
                   default-directory))
         (flake-path (expand-file-name "flake.nix" root)))
    (when (file-exists-p flake-path)
      (user-error "[nix] flake.nix already exists at %s" flake-path))
    (let* ((candidates (mapcar (lambda (entry)
                                 (cons (format "%-8s  %s" (car entry) (cadr entry))
                                       (caddr entry)))
                               my/nix-flake-templates))
           (choice  (completing-read "Flake template: "
                                     (mapcar #'car candidates)
                                     nil t))
           (content (cdr (assoc choice candidates))))
      (unless content
        (user-error "[nix] Unknown template: %s" choice))
      (with-temp-file flake-path
        (insert content))
      (message "[nix] Created %s" flake-path)
      (find-file flake-path)
      ;; Offer immediate .envrc setup so the project is wired up right away.
      (when (and (executable-find "direnv")
                 (not (file-exists-p (expand-file-name ".envrc" root)))
                 (yes-or-no-p "[nix] Also create .envrc and run direnv allow? "))
        (let ((default-directory root))
          (my/nix-create-envrc--silent))))))

;;; ────────────────────────────────────────────────────────────────────────────
;;; ── D. One-shot Project Setup ────────────────────────────────────────────────
;;; ────────────────────────────────────────────────────────────────────────────
;;
;; `my/nix-project-setup' wires up a project from scratch in one command:
;;   1. Creates .envrc if missing
;;   2. Runs direnv allow
;;   3. Reloads envrc so the buffer's process-environment is updated
;;   4. Starts eglot
;;
;; Use this when auto-setup (B) was declined, or when something got out of sync.

(defun my/nix-project-setup ()
  "One-shot: create .envrc → direnv allow → reload env → start eglot.

Idempotent — safe to run on a project that's already partially set up.
Each step is skipped if it's already done."
  (interactive)
  (unless (executable-find "nix")
    (user-error "[nix] `nix' is not on PATH"))
  (let* ((shell-type (my/nix-shell-type))
         (root (or (locate-dominating-file default-directory "flake.nix")
                   (locate-dominating-file default-directory "shell.nix"))))

    ;; Step 1 — .envrc
    (unless root
      (user-error "[nix] No flake.nix or shell.nix found above %s" default-directory))
    (let ((envrc-path (expand-file-name ".envrc" root)))
      (if (file-exists-p envrc-path)
          (message "[nix] .envrc already exists at %s" envrc-path)
        (message "[nix] Creating .envrc…")
        (my/nix-create-envrc--silent)))

    ;; Step 2 — direnv allow (runs direnv allow then envrc-reload)
    (unless (executable-find "direnv")
      (user-error "[nix] `direnv' not found — install it then run again"))
    (my/nix-direnv-allow)

    ;; Step 3 — Start eglot if not already running
    (my/nix--maybe-start-eglot)
    (message "[nix] Project setup complete.  Run `SPC n c' to verify status.")))

;;; ────────────────────────────────────────────────────────────────────────────
;;; ── Helper Functions ─────────────────────────────────────────────────────────
;;; ────────────────────────────────────────────────────────────────────────────

;;; ── Shell Type Detection ─────────────────────────────────────────────────────

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

;;; ── Open Shell File ──────────────────────────────────────────────────────────

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

;;; ── Create .envrc (silent variant for programmatic use) ──────────────────────

(defun my/nix-create-envrc--silent ()
  "Create .envrc at the project root without any interactive prompts.
Writes \\='use flake\\=' or \\='use nix\\=' based on shell type, then runs
`direnv allow' automatically.  Use `my/nix-create-envrc' for interactive use."
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
    (when (executable-find "direnv")
      (my/nix-direnv-allow))))

;;; ── Create .envrc (interactive) ──────────────────────────────────────────────

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

;;; ── direnv allow ─────────────────────────────────────────────────────────────

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

;;; ── Load Nix Environment into Buffer (fallback, no direnv) ───────────────────
;;
;; The primary path is direnv + envrc.  Use my/nix-load-env when you want to
;; load a nix env into one buffer WITHOUT committing a .envrc to the project.
;;
;; For flake.nix : `nix print-dev-env --json'  (fast — no shell spawned)
;; For shell.nix  : `nix-shell --run env -0'   (starts a shell, reads env)
;;
;; Both commands run asynchronously so Emacs stays responsive.
;; With prefix arg (C-u SPC n l), also restarts eglot after loading.

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
      (message "[nix] Loaded %d vars — eglot starting now…" (length env-alist))
      ;; After manually loading the env, start eglot immediately.
      (my/nix--maybe-start-eglot))))

(defun my/nix-load-env (&optional restart-eglot)
  "Load the Nix shell environment into the current buffer's process-environment.

For flake.nix : runs `nix print-dev-env --json' (fast — no shell spawned).
For shell.nix  : runs `nix-shell --run env -0' (null-separated KEY=VAL pairs).

Sets `process-environment' buffer-locally so eglot, compile, M-!, and other
Emacs subprocesses inherit the nix shell PATH and tooling.  Starts eglot
automatically after loading.

With prefix arg (\\[universal-argument]), restarts eglot even if it's already
running (useful after changing flake inputs)."
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
         (stdout-buf (generate-new-buffer " *nix-load-env-stdout*"))
         (stderr-buf (generate-new-buffer "*nix-load-env-error*")))
    (message "[nix] Loading environment… (first run may take a moment)")
    (make-process
     :name     "nix-load-env"
     :buffer   stdout-buf
     :stderr   stderr-buf          ; capture stderr separately so stdout stays parseable
     :command  cmd
     :sentinel
     (lambda (proc event)
       (cond
        ((string-prefix-p "finished" event)
         (let* ((raw (with-current-buffer stdout-buf (buffer-string)))
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
           (kill-buffer stdout-buf)
           (kill-buffer stderr-buf)
           (my/nix--apply-env-alist env-alist buf)
           (when restart-eglot
             (with-current-buffer buf
               (when (fboundp 'eglot-shutdown)
                 (ignore-errors (eglot-shutdown (eglot-current-server))))
               (call-interactively #'eglot)))))
        ((string-prefix-p "exited" event)
         (kill-buffer stdout-buf)
         ;; Rename stderr buf so it survives and is visible, then show it.
         (with-current-buffer stderr-buf
           (rename-buffer "*nix-load-env-error*" t)
           (special-mode)
           (goto-char (point-min)))
         (pop-to-buffer stderr-buf)
         (message "[nix] Command failed: %s — see buffer above for details"
                  (string-join cmd " "))))))))

;;; ── Run Nix Shell ────────────────────────────────────────────────────────────

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

;;; ────────────────────────────────────────────────────────────────────────────
;;; ── Project Environment Status ───────────────────────────────────────────────
;;; ────────────────────────────────────────────────────────────────────────────
;; SPC n c shows a buffer with:
;;   - Project type (flake.nix / shell.nix / none)
;;   - Whether the nix env is loaded (nix/store on PATH)
;;   - Which LSP servers are visible on the current PATH
;;   - eglot's running status
;;   - .envrc / direnv status

(defconst my/nix--lsp-servers
  '(("nixd"               . "Nix")
    ("nil"                . "Nix (nil)")
    ("clangd"             . "C/C++")
    ("basedpyright-langserver" . "Python (basedpyright)")
    ("pyright-langserver" . "Python (pyright)")
    ("pylsp"              . "Python (pylsp)")
    ("rust-analyzer"      . "Rust")
    ("zls"                . "Zig")
    ("gopls"              . "Go"))
  "LSP server binaries checked by `my/nix-env-status'.")

(defun my/nix--status-row (ok label detail &optional fix optional)
  "Insert one status row.  FIX is shown as a hint when OK is nil."
  (insert (propertize (cond (ok       "  ✓  ")
                            (optional "  ⚠  ")
                            (t        "  ✗  "))
                      'face (cond (ok 'success) (optional 'warning) (t 'error))))
  (insert (propertize (format "%-28s" label)
                      'face (if ok 'default (if optional 'warning 'error))))
  (insert (propertize (or detail "") 'face 'shadow))
  (insert "\n")
  (when (and fix (not ok))
    (insert (propertize (format "     └─ %s\n" fix) 'face 'italic))))

(defun my/nix--status-section (title)
  "Insert a bold section header."
  (insert (propertize (concat title "\n") 'face '(:weight bold)))
  (insert (propertize (concat (make-string 66 ?─) "\n") 'face 'shadow)))

(defun my/nix-env-status ()
  "Show the Nix programming environment status for the current buffer.

Displays a *Nix Environment* report covering:
  - Project type (flake.nix / shell.nix / none)
  - Whether the nix env is loaded (process-environment + exec-path)
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
        (insert (propertize (make-string 66 ?━) 'face 'shadow) "\n")
        (insert (propertize "  Nix Environment Status\n"
                            'face '(:weight bold :height 1.3)))
        (insert (propertize (make-string 66 ?─) 'face 'shadow) "\n")
        (insert (format "  %-14s %s\n" "Buffer:" (buffer-name src)))
        (insert (format "  %-14s %s\n" "Directory:" dir))
        (insert (propertize (make-string 66 ?━) 'face 'shadow) "\n\n")

        ;; ── Project ───────────────────────────────────────────────────────────
        (my/nix--status-section "PROJECT")
        (my/nix--status-row
         (not (null shell-type))
         "Shell type"
         (pcase shell-type
           (:flake "flake.nix   →  nix develop")
           (:shell "shell.nix   →  nix-shell")
           (_ "none"))
         (format "SPC n N — scaffold flake.nix in %s" root))
        (my/nix--status-row
         (file-exists-p envrc-path)
         ".envrc"
         (if (file-exists-p envrc-path) envrc-path "not found")
         "SPC n S — full project setup  |  SPC n e — create .envrc only"
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
           "SPC n S — one-shot setup  |  SPC n l — load env manually"))
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
            (insert (propertize "     Add them to your flake.nix devShell packages.\n" 'face 'italic))
            (insert (propertize "     Then run: SPC n S\n" 'face 'italic))))
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
             "M-x eglot — start LSP manually"
           "SPC n S — setup project first, then eglot starts automatically"))
        (insert "\n")

        ;; ── Quick actions ─────────────────────────────────────────────────────
        (my/nix--status-section "QUICK ACTIONS")
        (dolist (row '(("SPC n S     " . "full project setup (create .envrc → allow → eglot)")
                       ("SPC n N     " . "scaffold a new flake.nix")
                       ("SPC n c     " . "refresh this status buffer")
                       ("SPC n o     " . "open flake.nix / shell.nix")
                       ("SPC n e     " . "create .envrc only")
                       ("SPC n a     " . "direnv allow")
                       ("SPC n r     " . "reload direnv env")
                       ("SPC n l     " . "load env manually (no direnv)")
                       ("C-u SPC n l " . "load env + restart eglot")
                       ("SPC n s     " . "open nix shell (eshell)")
                       ("SPC n t     " . "show shell type")))
          (insert (propertize (format "  %s  " (car row)) 'face 'bold))
          (insert (propertize (cdr row) 'face 'shadow))
          (insert "\n"))
        (insert "\n")
        (insert (propertize (make-string 66 ?━) 'face 'shadow) "\n")
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
  "n S" '(my/nix-project-setup       :which-key "⚡ full setup (envrc→eglot)")
  "n N" '(my/nix-new-flake           :which-key "new flake.nix")
  "n c" '(my/nix-env-status          :which-key "env status")
  "n o" '(my/nix-open-shell-file     :which-key "open shell file")
  "n e" '(my/nix-create-envrc        :which-key "create .envrc")
  "n a" '(my/nix-direnv-allow        :which-key "direnv allow")
  "n r" '(envrc-reload               :which-key "reload envrc")
  "n l" '(my/nix-load-env            :which-key "load env (no direnv)")
  "n s" '(my/nix-run-shell           :which-key "nix shell (eshell)")
  "n t" '(my/nix-shell-type          :which-key "show shell type"))

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
