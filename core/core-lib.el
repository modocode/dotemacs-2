;;; core/core-lib.el --- Helper macros and functions -*- lexical-binding: t; -*-
;;
;; This file provides utilities that any other module may use.
;; It is loaded early in init.el so macros defined here are available
;; everywhere else.

;;; ── my/with-binary ──────────────────────────────────────────────────────────
;;
;; A macro is used (rather than a function) so the BODY forms are only
;; evaluated when the binary check passes.  If we used a function, Emacs
;; would evaluate all arguments before calling it — meaning `use-package'
;; blocks inside would still run even when the binary is absent.
;;
;; (declare (indent 1)) tells `emacs-lisp-mode' to indent BODY one level in,
;; just like `when' or `with-current-buffer'.

(defmacro my/with-binary (binary &rest body)
  "Execute BODY only if BINARY exists on the system PATH.

BINARY is a string naming a CLI executable (e.g. \"rg\", \"git\", \"node\").
`executable-find' searches every directory in `exec-path' for it.

Use this to guard `use-package' blocks that depend on an external tool,
so Emacs still boots cleanly on machines that don't have that tool installed.

Example:

  ;; Only configure ripgrep integration when `rg' is installed.
  (my/with-binary \"rg\"
    (use-package rg
      :bind (\"C-c s\" . rg-menu)))

  ;; Guard an LSP server that requires node on PATH.
  (my/with-binary \"node\"
    (use-package lsp-mode
      :hook (typescript-mode . lsp-deferred)))"
  (declare (indent 1) (doc-string 2))
  `(when (executable-find ,binary)
     ,@body))

;;; ── my/set-font ─────────────────────────────────────────────────────────────
;; Try to set FONT-NAME at SIZE (in units of 1/10 pt, so 100 = 10pt).
;; Returns t on success so callers can chain attempts with `or':
;;
;;   (or (my/set-font "Preferred Font" 120)
;;       (my/set-font "Fallback Font"  120))

(defun my/set-font (font-name size)
  "Set the default face to FONT-NAME at SIZE if FONT-NAME is available.
SIZE is in units of 1/10 point (e.g. 120 = 12pt).
Returns t if successful, nil if the font was not found."
  (when (member font-name (font-family-list))
    (set-face-attribute 'default nil :font font-name :height size)
    t))

;;; ── Directory Helpers (no-littering companions) ─────────────────────────────
;; Wrappers around no-littering's expansion functions so modules can resolve
;; paths without depending on the package symbol directly.  Both functions
;; fall back to plain subdirectories of `user-emacs-directory' on first-run
;; (before no-littering is installed), so Emacs still boots cleanly.

(defun my/etc-dir (name)
  "Return an absolute path for NAME under no-littering's etc directory.
Use this for package *config* files that no-littering does not handle
automatically.

Falls back to ~/.emacs.d/etc/NAME if no-littering is not yet loaded.

Example:
  (setq lsp-session-file (my/etc-dir \"lsp-session\"))"
  (if (fboundp 'no-littering-expand-etc-file-name)
      (no-littering-expand-etc-file-name name)
    (expand-file-name (concat "etc/" name) user-emacs-directory)))

(defun my/var-dir (name)
  "Return an absolute path for NAME under no-littering's var directory.
Use this for package *state/data* files that no-littering does not handle
automatically.

Falls back to ~/.emacs.d/var/NAME if no-littering is not yet loaded.

Example:
  (setq persist-file (my/var-dir \"persist/data\"))"
  (if (fboundp 'no-littering-expand-var-file-name)
      (no-littering-expand-var-file-name name)
    (expand-file-name (concat "var/" name) user-emacs-directory)))

(provide 'core-lib)
;;; core-lib.el ends here
