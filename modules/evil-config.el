;;; modules/evil.el --- Vim emulation -*- lexical-binding: t; -*-

(use-package evil
  :ensure t
  :demand t   ; must load at startup — use-package-always-defer is set globally
  :init
  (setq evil-auto-indent               t
        evil-respect-visual-line-mode  t
        evil-want-keybinding           nil) ; required before evil loads, for evil-collection
  :config
  (evil-mode 1))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

(use-package evil-escape
  :ensure t
  :after evil
  :init
  (setq-default evil-escape-key-sequence "jk"
                evil-escape-delay        0.2)
  :config
  (evil-escape-mode 1))

(provide 'evil-config)
;;; evil.el ends here
