;;; modules/modeline-config.el --- Mode line configuration -*- lexical-binding: t; -*-

(use-package nerd-icons
  :ensure t
  :demand t)

;; doom modeline 
(use-package doom-modeline
  :ensure t
  :demand t
  :after nerd-icons
  :init
  (setq doom-modeline-height              28
        doom-modeline-bar-width            4
        doom-modeline-icon                 t
        doom-modeline-major-mode-icon      t
        ;; Show truncated path relative to project root (e.g. src/foo.el)
        doom-modeline-buffer-file-name-style 'truncate-upto-project
        ;; Show word count in text/org modes
        doom-modeline-enable-word-count    t
        ;; Don't clutter the mode line with minor modes
        doom-modeline-minor-modes          nil)
  :config
  (doom-modeline-mode 1))

(provide 'modeline-config)
;;; modeline-config.el ends here
