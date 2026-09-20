;;; modules/themes.el --- My Favorite Themes for Emacs -*- lexical-binding: t; -*-

(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" user-emacs-directory))

(use-package ubuntu-theme   :ensure t)
(use-package poet-theme     :ensure t)
(use-package solarized-theme :ensure t)
(use-package gruvbox-theme  :ensure t)

(use-package doric-themes
  :ensure t
  :demand t
  :config
  ;; These are the default values.
  (setq doric-themes-to-toggle '(doric-light doric-dark))
  (setq doric-themes-to-rotate doric-themes-collection)
)

  
(use-package base16-theme
  :ensure t
  :demand t
  :config
  ;; (load-theme 'base16-default-dark t)
  )

(use-package zenburn-theme
  :ensure t
  :custom
  (zenburn-scale-org-headlines t)
  (zenburn-scale-outline-headlines t))

;; Use the elpaca-managed modus-themes (not the built-in Emacs 29 copy).
;; ef-themes calls `modus-themes-declare' at load time, which only exists in
;; the newer elpaca version.  The old :ensure nil / macro-mismatch concern is
;; moot now that all stale .elc files have been cleared.
(use-package modus-themes
  :ensure t
  :custom
  (modus-themes-mixed-fonts t)
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-variable-pitch-ui t)
  (modus-themes-headings '((1 1.5) (2 1.17))))

(use-package ef-themes
  :ensure t)

(use-package ample-theme
  :init (progn (load-theme 'ample t t)
               (load-theme 'ample-flat t t)
               (load-theme 'ample-light t t)
               )
  :defer t
  :ensure t)


(provide 'themes)

