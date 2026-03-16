;;; modules/lang-c.el --- C and C++ language support -*- lexical-binding: t; -*-
;;
;; Configures the built-in cc-mode for C and C++.
;; LSP (eglot-ensure) is NOT called here — see modules/lang-lsp.el.

;;; ── Indentation Constants ───────────────────────────────────────────────────

(defvar my/c-indent-width 4
  "Indentation width for C and C++ files.")

(defvar my/c-style "k&r"
  "Base indentation style for C/C++. Options: \"k&r\", \"bsd\", \"linux\", \"gnu\".
\"k&r\" gives 4-space indentation without GNU's extra-brace-on-own-line style.
Override in os/*.el for project-specific style conventions.")

;;; ── cc-mode (C / C++) ───────────────────────────────────────────────────────
;; cc-mode provides both c-mode and c++-mode. It ships with Emacs.
;;
;; We use `c-mode-common-hook' rather than separate hooks for c-mode and
;; c++-mode because c-basic-offset is the same setting for both, and
;; cc-mode's hook hierarchy means c-mode-common-hook fires for both.

(use-package cc-mode
  :ensure nil   ; built-in
  :mode
  (("\\.c\\'"   . c-mode)
   ("\\.h\\'"   . c++-mode)   ; treat .h as C++ by default (header-only libs)
   ("\\.cpp\\'" . c++-mode)
   ("\\.cc\\'"  . c++-mode)
   ("\\.cxx\\'" . c++-mode)
   ("\\.hpp\\'" . c++-mode))
  :hook
  (c-mode-common . my/c-setup)
  :config

  (defun my/c-setup ()
    "Apply sensible defaults to any c-mode or c++-mode buffer."
    ;; c-basic-offset is buffer-local; setting it here (in a hook) is correct.
    (setq c-basic-offset  my/c-indent-width
          tab-width        my/c-indent-width
          indent-tabs-mode nil)    ; spaces only — tabs cause misalignment
    ;; Apply the base style, then our offset overrides it.
    (c-set-style my/c-style)
    (setq c-basic-offset my/c-indent-width))  ; re-set after style resets it

  ;; Tell Emacs which style to fall back to for files that don't match a
  ;; project-specific EditorConfig or .dir-locals.el.
  (setq c-default-style
        `((c-mode   . ,my/c-style)
          (c++-mode . ,my/c-style)
          (other    . "gnu"))))

;;; ── Compilation ─────────────────────────────────────────────────────────────
;; compile.el is built-in; we just set a smarter default command.
;; `my/find-project-root' (from mo-helpers.el) finds the Makefile/CMakeLists.
;; We set `compile-command' in a hook so it reflects the actual buffer's root.

(add-hook 'c-mode-common-hook
          (lambda ()
            (when-let* ((root (my/find-project-root)))
              (setq-local compile-command
                          (cond
                           ((file-exists-p (expand-file-name "Makefile" root))
                            (format "make -C %s" root))
                           ((file-exists-p (expand-file-name "CMakeLists.txt" root))
                            (format "cmake --build %s/build" root))
                           (t "make"))))))

(provide 'lang-c)
;;; lang-c.el ends here
