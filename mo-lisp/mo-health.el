;;; mo-lisp/mo-health.el --- Setup verification and machine diagnostics -*- lexical-binding: t; -*-
;;
;; PURPOSE
;; ───────
;; Provides `my/health-check' — an interactive report that tells you whether
;; every part of your Emacs config is working correctly on the current machine.
;;
;; When something is wrong it tells you WHICH machine is the culprit, WHAT is
;; missing, and WHERE in the config to fix it.
;;
;; QUICK USAGE
;; ───────────
;;   M-x my/health-check          — run the full report
;;   M-x my/health-check-auto     — run silently, open report only if failures
;;   g  (in the report buffer)    — re-run the checks
;;   q  (in the report buffer)    — close the buffer
;;
;; ADDING CUSTOM CHECKS
;; ────────────────────
;;   (my/health-register-check
;;     (lambda ()
;;       (list :label  "My check"
;;             :ok     (file-exists-p "~/important-file")
;;             :detail "~/important-file"
;;             :fix    "Create ~/important-file")))
;;
;; ADDING PACKAGES OR BINARIES TO MONITOR
;; ───────────────────────────────────────
;;   In your os/*.el or any module, call:
;;   (add-to-list 'my/health-check-features 'my-new-feature)
;;   (add-to-list 'my/health-check-binaries
;;                '(:bin "mytool" :desc "does X"
;;                  :linux "apt install mytool"
;;                  :macos "brew install mytool"
;;                  :windows "winget install mytool"))

(require 'cl-lib)

;;; ── Registries ──────────────────────────────────────────────────────────────
;; All lists are defvar so you can override them in os/*.el per machine.
;; E.g. to add a binary only relevant on one machine:
;;   (add-to-list 'my/health-check-binaries
;;                '(:bin "adb" :desc "Android debug bridge" ...))

(defvar my/health-check-binaries
  ;; Each entry is a plist.  :optional t means a WARN rather than a FAIL.
  ;; The Python LSP entry is built dynamically at check time — see
  ;; `my/health--python-lsp-entry' below.
  `((:bin "git"
     :desc "version control — required by elpaca"
     :linux   "sudo apt install git"
     :macos   "brew install git  # or: xcode-select --install"
     :windows "winget install Git.Git")

    (:bin "rg"
     :desc "ripgrep — used by consult-grep and rg.el"
     :optional t
     :linux   "sudo apt install ripgrep"
     :macos   "brew install ripgrep"
     :windows "winget install BurntSushi.ripgrep.MSVC")

    (:bin "clangd"
     :desc "C/C++ language server (lang-lsp.el)"
     :optional t
     :linux   "sudo apt install clangd"
     :macos   "brew install llvm && brew link llvm"
     :windows "winget install LLVM.LLVM")

    (:bin "zls"
     :desc "Zig language server (lang-lsp.el)"
     :optional t
     :linux   "https://github.com/zigtools/zls/releases"
     :macos   "https://github.com/zigtools/zls/releases"
     :windows "https://github.com/zigtools/zls/releases")

    (:bin "zig"
     :desc "Zig compiler — needed for zig fmt on save"
     :optional t
     :linux   "https://ziglang.org/download/ or snap install zig --classic"
     :macos   "brew install zig"
     :windows "winget install zig.zig"))
  "Plists of binaries verified by `my/health-check'.
Each plist: (:bin STRING :desc STRING [:optional t] :linux STRING :macos STRING :windows STRING)
Add machine-specific tools in your os/*.el with `add-to-list'.")

(defvar my/health-check-fonts
  ;; Sourced directly from core/core-ui.el so this list stays in sync.
  '("LigaSauceCodePro NF"
    "Hack"
    "IBM Plex Mono")
  "Fonts verified by `my/health-check' (GUI frames only).
At least one of these should be present for core-ui.el to set a font correctly.
Add machine-specific fonts in your os/*.el.")

(defvar my/health-check-features
  ;; Every file that calls (provide 'SYMBOL) should appear here.
  ;; Symbols are checked with `featurep', which returns t only if the file
  ;; loaded without error.  A missing symbol = the module failed silently.
  '(;; mo-lisp library
    mo-paths
    mo-helpers
    ;; core
    core-packages
    core-lib
    core-ui
    ;; modules
    completion-config
    project-setup
    lang-lsp
    lang-python
    lang-c
    lang-zig
    org-config)
  "Feature symbols verified by `my/health-check'.
Add your own modules here or in os/*.el with `add-to-list'.")

(defvar my/health-check-extra nil
  "Additional check functions registered via `my/health-register-check'.
Each function takes no args and returns a result plist:
  (:label STRING :ok BOOL :detail STRING [:fix STRING])")

;;; ── Registration API ────────────────────────────────────────────────────────

(defun my/health-register-check (fn)
  "Register FN as a custom health check run by `my/health-check'.

FN takes no arguments and returns a plist:
  :label   — short name shown in the report
  :ok      — t if the check passed, nil if it failed
  :detail  — string shown next to the result (path, version, etc.)
  :fix     — (optional) hint shown below the line when :ok is nil

Example — verify a specific config file exists:
  (my/health-register-check
    (lambda ()
      (let ((f \"~/.ssh/config\"))
        (list :label  \"SSH config\"
              :ok     (file-exists-p f)
              :detail (expand-file-name f)
              :fix    \"Create ~/.ssh/config\"))))"
  (add-to-list 'my/health-check-extra fn t))

;;; ── Internal: Check Runners ─────────────────────────────────────────────────
;; Each function returns a list of result plists.

(defun my/health--os-file-label ()
  "Return the short os/*.el filename for the current machine."
  (cond (my/is-mac     "os/macos.el")
        (my/is-linux   "os/linux.el")
        (my/is-windows "os/windows.el")
        (t             "os/???.el")))

(defun my/health--install-hint (entry)
  "Return the OS-appropriate install string from binary ENTRY plist."
  (or (cond (my/is-mac     (plist-get entry :macos))
            (my/is-linux   (plist-get entry :linux))
            (my/is-windows (plist-get entry :windows)))
      "check your system package manager"))

(defun my/health--python-lsp-entry ()
  "Build a binary plist for whichever Python LSP server is configured."
  (let* ((server   (if (boundp 'my/python-lsp-server)
                       my/python-lsp-server
                     "pyright"))
         (bin      (if (string= server "pylsp") "pylsp" "pyright-langserver"))
         (install  "pip install pyright  # or: pip install python-lsp-server"))
    `(:bin ,bin :desc ,(format "Python LSP (%s) — set my/python-lsp-server to change"
                               server)
           :optional t
           :linux ,install :macos ,install :windows ,install)))

(defun my/health--check-paths ()
  "Check every entry in `my/paths' against the filesystem."
  (when (boundp 'my/paths)
    (mapcar
     (lambda (entry)
       (let* ((key      (car entry))
              (raw      (cdr entry))
              (expanded (expand-file-name raw))
              (exists   (file-directory-p expanded)))
         (list :label  (symbol-name key)
               :ok     exists
               :detail expanded
               :fix    (unless exists
                         (format "Add (my/register-path '%s \"REAL/PATH\") to %s on %s"
                                 key
                                 (my/health--os-file-label)
                                 (system-name))))))
     my/paths)))

(defun my/health--check-binaries ()
  "Check every binary in `my/health-check-binaries' plus the Python LSP."
  (let ((all (append my/health-check-binaries
                     (list (my/health--python-lsp-entry)))))
    (mapcar
     (lambda (entry)
       (let* ((bin      (plist-get entry :bin))
              (found    (executable-find bin))
              (optional (plist-get entry :optional)))
         (list :label    bin
               :ok       (not (null found))
               :optional optional
               :detail   (or found "not found")
               :desc     (plist-get entry :desc)
               :fix      (unless found
                           (format "Install: %s"
                                   (my/health--install-hint entry))))))
     all)))

(defun my/health--check-fonts ()
  "Check each font in `my/health-check-fonts'. Returns nil in terminal frames."
  (when (display-graphic-p)
    (let ((available (font-family-list)))  ; cache the list once
      (mapcar
       (lambda (font)
         (let ((found (member font available)))
           (list :label  font
                 :ok     (not (null found))
                 :detail (if found "installed" "not installed")
                 :fix    (unless found
                           (format "Install \"%s\" system-wide and restart Emacs" font)))))
       my/health-check-fonts))))

(defun my/health--check-features ()
  "Check each symbol in `my/health-check-features' with `featurep'."
  (mapcar
   (lambda (feat)
     (let ((loaded (featurep feat)))
       (list :label  (symbol-name feat)
             :ok     loaded
             :detail (if loaded "loaded" "NOT loaded")
             :fix    (unless loaded
                       (format "Open modules/%s.el and check for errors (M-x view-echo-area-messages)"
                               feat)))))
   my/health-check-features))

;;; ── Internal: Renderer ──────────────────────────────────────────────────────

(defconst my/health--pass   "  ✓  ")
(defconst my/health--fail   "  ✗  ")
(defconst my/health--warn   "  ⚠  ")
(defconst my/health--sep    (make-string 62 ?─))
(defconst my/health--sep-hv (make-string 62 ?━))

(defun my/health--face (ok optional)
  "Return the face to use for a check result."
  (cond (ok               'success)
        (optional         'warning)
        (t                'error)))

(defun my/health--insert-header ()
  "Insert the machine identity block at the top of the report."
  (let* ((os-label (cond (my/is-mac     "macOS")
                         (my/is-linux   "GNU/Linux")
                         (my/is-windows "Windows")
                         (t (symbol-name system-type))))
         (os-file  (and (boundp 'my/system-config-path) my/system-config-path))
         (os-live  (and os-file (file-exists-p os-file))))
    (insert (propertize my/health--sep-hv 'face 'shadow) "\n")
    (insert (propertize "  Emacs Health Report\n" 'face '(:weight bold :height 1.3)))
    (insert (propertize my/health--sep 'face 'shadow) "\n")
    (insert (format "  %-12s %s\n" "Machine:"
                    (propertize (system-name) 'face 'bold)))
    (insert (format "  %-12s %s\n" "OS:" os-label))
    (insert (format "  %-12s %s\n" "Emacs:" emacs-version))
    (insert (format "  %-12s %s\n" "Config dir:"
                    (if (boundp 'my/emacs-dir)
                        my/emacs-dir
                      (propertize "UNKNOWN — my/emacs-dir not set" 'face 'error))))
    (insert (format "  %-12s %s  %s\n" "OS config:"
                    (or os-file (propertize "nil" 'face 'error))
                    (if os-live
                        (propertize "[loaded]" 'face 'success)
                      (propertize "[MISSING — create this file]" 'face 'warning))))
    (insert (propertize my/health--sep-hv 'face 'shadow) "\n\n")))

(defun my/health--insert-section (title results)
  "Insert section TITLE with RESULTS. Returns (pass . fail) counts."
  (let ((pass 0) (fail 0) (warn 0))
    (insert (propertize (concat title "\n") 'face '(:weight bold)))
    (insert (propertize (concat my/health--sep "\n") 'face 'shadow))
    (dolist (r results)
      (let* ((ok       (plist-get r :ok))
             (optional (plist-get r :optional))
             (label    (plist-get r :label))
             (detail   (plist-get r :detail))
             (desc     (plist-get r :desc))
             (fix      (plist-get r :fix))
             (face     (my/health--face ok optional))
             (mark     (cond (ok       my/health--pass)
                             (optional my/health--warn)
                             (t        my/health--fail))))
        (if ok
            (cl-incf pass)
          (if optional (cl-incf warn) (cl-incf fail)))
        ;; Main result line
        (insert (propertize mark   'face face))
        (insert (propertize (format "%-28s" label) 'face (if ok 'default face)))
        (insert (propertize (or detail "") 'face (if ok 'shadow face)))
        (when desc
          (insert (propertize (format "  — %s" desc) 'face 'shadow)))
        (insert "\n")
        ;; Fix hint on the line below (indented)
        (when (and fix (not ok))
          (insert (propertize (format "     └─ %s\n" fix) 'face 'italic)))))
    (insert "\n")
    (cons pass (+ fail warn))))   ; warnings count toward "needs attention"

;;; ── Public API ──────────────────────────────────────────────────────────────

(defun my/health-check ()
  "Run all health checks and display a diagnostics report.

SECTIONS
  Machine   — hostname, OS type, which os/*.el was loaded
  Paths     — every entry in `my/paths' checked against the filesystem
  Binaries  — git, rg, LSP servers, language toolchains
  Fonts     — required fonts (GUI mode only; skipped in terminal)
  Modules   — whether each module's (provide ...) was reached at startup
  Custom    — any checks registered via `my/health-register-check'

INTERPRETING FAILURES
  ✗ (red)    — hard failure: something that will break functionality
  ⚠ (yellow) — optional tool missing: degrades experience but not fatal
  ✓ (green)  — all good

FIXING PATH FAILURES
  Path failures mean the directory doesn't exist on THIS machine.
  The fix hint tells you exactly which os/*.el file to edit and what
  `my/register-path' call to add.  The culprit is always machine-specific.

KEY BINDINGS (in the report buffer)
  g — re-run all checks
  q — close buffer"
  (interactive)
  (let* ((buf        (get-buffer-create "*Emacs Health*"))
         (pass       0)
         (fail       0)
         ;; Helper: run one section, accumulate totals
         (run-section (lambda (title results)
                        (when results
                          (let ((counts (my/health--insert-section title results)))
                            (cl-incf pass (car counts))
                            (cl-incf fail (cdr counts)))))))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)

        ;; ── Header ──────────────────────────────────────────────────────────
        (my/health--insert-header)

        ;; ── Paths ────────────────────────────────────────────────────────────
        (funcall run-section
                 (format "PATHS  (configured in %s on %s)"
                         (my/health--os-file-label) (system-name))
                 (my/health--check-paths))

        ;; ── Binaries ────────────────────────────────────────────────────────
        (funcall run-section "BINARIES" (my/health--check-binaries))

        ;; ── Fonts ────────────────────────────────────────────────────────────
        (let ((font-results (my/health--check-fonts)))
          (if font-results
              (funcall run-section "FONTS  (GUI only)" font-results)
            (insert (propertize "FONTS  (skipped — terminal frame)\n\n" 'face 'shadow))))

        ;; ── Modules ─────────────────────────────────────────────────────────
        (funcall run-section "MODULES" (my/health--check-features))

        ;; ── Custom ──────────────────────────────────────────────────────────
        (when my/health-check-extra
          (let ((extra-results
                 (delq nil
                       (mapcar (lambda (fn)
                                 (condition-case err
                                     (funcall fn)
                                   (error
                                    (list :label  (format "%s" fn)
                                          :ok     nil
                                          :detail (error-message-string err)
                                          :fix    "Fix the check function itself"))))
                               my/health-check-extra))))
            (funcall run-section "CUSTOM CHECKS" extra-results)))

        ;; ── Summary ──────────────────────────────────────────────────────────
        (insert (propertize my/health--sep-hv 'face 'shadow) "\n")
        (insert "  Summary: ")
        (insert (propertize (format "%d passed" pass) 'face 'success))
        (insert "  ")
        (insert (if (> fail 0)
                    (propertize (format "%d need attention" fail) 'face 'error)
                  (propertize "0 issues" 'face 'success)))
        (insert "\n")
        (when (> fail 0)
          (insert (propertize
                   (format "  Culprit: edit %s on machine \"%s\"\n"
                           (my/health--os-file-label) (system-name))
                   'face '(:slant italic))))
        (insert (propertize my/health--sep-hv 'face 'shadow) "\n")
        (insert (propertize (format "\n  [Last run: %s]\n"
                                    (format-time-string "%Y-%m-%d %H:%M:%S"))
                            'face 'shadow))

        ;; ── Buffer setup ─────────────────────────────────────────────────────
        (goto-char (point-min))
        (special-mode)
        ;; `g' re-runs the full check, same as `revert-buffer' convention.
        (local-set-key (kbd "g") #'my/health-check)))

    (pop-to-buffer buf)
    ;; Return t = all good, nil = something failed (useful for hooks/scripts)
    (zerop fail)))

(defun my/health-check-auto ()
  "Run health checks silently at startup; only open the report if failures exist.

Add to `emacs-startup-hook' for passive monitoring:

  (add-hook 'emacs-startup-hook #'my/health-check-auto)

On a healthy machine this does nothing visible.  On a broken one it opens
the *Emacs Health* buffer immediately so you see what's wrong."
  (unless (my/health-check)
    (message "[health] Issues detected on %s — see *Emacs Health* buffer"
             (system-name))))

(provide 'mo-health)
;;; mo-health.el ends here
