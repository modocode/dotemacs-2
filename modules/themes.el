;;; modules/themes.el --- My Favorite Themes for Emacs -*- lexical-binding: t; -*-

(use-package ubuntu-theme   :ensure t)
(use-package poet-theme     :ensure t)
(use-package solarized-theme :ensure t)
(use-package gruvbox-theme  :ensure t)

(use-package zenburn-theme
  :ensure t
  :custom
  (zenburn-scale-org-headlines t)
  (zenburn-scale-outline-headlines t))

;; modus-themes ships built-in with Emacs 29+.  Using :ensure nil prevents
;; elpaca from installing a second copy, which would cause a byte-compiled
;; macro mismatch and break startup with an eager-macroexpand error.
(use-package modus-themes
  :ensure nil
  :custom
  (modus-themes-mixed-fonts t)
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-variable-pitch-ui t)
  (modus-themes-headings '((1 1.5) (2 1.17))))

(use-package ef-themes
  :ensure t)


(provide 'themes)

