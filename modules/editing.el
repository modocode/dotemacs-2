;;; modules/editing.el --- Packages that help with editing files in emacs -*- lexical-binding: t; -*-

(use-package smartparens
  :ensure smartparens  ;; install the package
  :hook (prog-mode text-mode markdown-mode) ;; add `smartparens-mode` to these hooks
  :config
  ;; load default config
  (require 'smartparens-config))



(use-package yasnippet
  :ensure t
  :config
  (use-package yasnippet-snippets :ensure t)
  (yas-reload-all)
  (setq yas-triggers-in-field t)

  )
(yas-global-mode 1)



;; auto-complete removed — corfu (modules/completion.el) handles in-buffer
;; completion via CAPF. Running both causes conflicting popups.
