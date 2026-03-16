;;; modules/themes.el --- My Favorite Themes for Emacs -*- lexical-binding: t; -*-

;; Ubuntu Theme
(use-package ubuntu-theme)

;; Poet Theme
(use-package poet-theme)

;; Solarized Theme
(use-package solarized-theme)


;; Zenburn Theme
(use-package zenburn-theme
  :config
  (setq zenburn-scale-org-headlines t)
  ;; scale headings in outline-mode
  (setq zenburn-scale-outline-headlines t)
  )

;; Gruvbox

(use-package gruvbox-theme)

(use-package modus-themes
  :ensure t
  :demand t
  :custom
  (modus-themes-mixed-fonts t)
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-variable-pitch-ui t)
  (modus-themes-headings (quote ((1 1.5) (2 1.17))))
  )



;; Ef-Themes

(use-package ef-themes
  :ensure t
  :config
  (modus-themes-include-derivatives-mode 1)
  (setq modus-themes-mixed-fonts t)
  (setq modus-themes-italic-constructs t)

  ;(modus-themes-load-random-light)
  )


(provide 'themes)

