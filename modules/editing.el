;;; modules/editing.el --- Packages that help with editing files in emacs -*- lexical-binding: t; -*-


(use-package smartparens
  :ensure smartparens  ;; install the package
  :hook (prog-mode text-mode markdown-mode) ;; add `smartparens-mode` to these hooks
  :config
  ;; load default config
  (require 'smartparens-config))


(use-package yasnippet
  :ensure t
  :demand t   ; yas-global-mode in :config requires eager load
  :config
  (use-package yasnippet-snippets :ensure t)

  ;; Add the repo-tracked custom snippets dir (not gitignored like etc/).
  ;; Prepend so our snippets take priority over yasnippet-snippets on collision.
  ;; #'string= prevents duplicates if editing.el is reloaded.
  (add-to-list 'yas-snippet-dirs
               (expand-file-name "snippets" my/emacs-dir)
               nil #'string=)

  (yas-reload-all)
  (setq yas-triggers-in-field t)
  (yas-global-mode 1))


(use-package browse-kill-ring
  :ensure t
  :demand t
  )


(use-package vundo :ensure t  )


(use-package simpleclip :ensure t
  :config
  (simpleclip-mode 1))




;; auto-complete removed — corfu (modules/completion.el) handles in-buffer
;; completion via CAPF. Running both causes conflicting popups.
