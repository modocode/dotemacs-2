;;; modules/lang-zig.el --- Zig language support -*- lexical-binding: t; -*-
;;
;; Installs zig-mode from MELPA and sets sensible defaults.
;; LSP (eglot-ensure) is NOT called here — see modules/lang-lsp.el.

;;; ── Indentation Constants ───────────────────────────────────────────────────

(defvar my/zig-indent-width 4
  "Indentation width for Zig files. Matches the Zig style guide.")

;;; ── zig-mode ────────────────────────────────────────────────────────────────
;; zig-mode provides syntax highlighting, indentation, and a few helpers.
;; It is NOT built-in — requires MELPA (elpaca handles the install).

(use-package zig-mode
  :ensure t
  :mode "\\.zig\\'"
  :custom
  (zig-indent-offset my/zig-indent-width)
  ;; When non-nil, zig-mode runs `zig fmt' on save via zig-format-on-save-mode.
  ;; zig fmt is idempotent and enforces the official style — highly recommended.
  (zig-format-on-save t)
  :hook
  ;; Warn if `zig' binary isn't on PATH — zig fmt and build commands need it.
  (zig-mode . (lambda ()
                (unless (executable-find "zig")
                  (message "[lang-zig] `zig' not found on PATH. Formatting and build disabled.")))))

;;; ── Build Command ───────────────────────────────────────────────────────────
;; Set the compile command when visiting a Zig project that has a build.zig.

(add-hook 'zig-mode-hook
          (lambda ()
            (when-let* ((root (my/find-project-root))
                        ((file-exists-p (expand-file-name "build.zig" root))))
              (setq-local compile-command
                          (format "cd %s && zig build" root)))))

(provide 'lang-zig)
;;; lang-zig.el ends here
