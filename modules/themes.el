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


(provide 'themes)

