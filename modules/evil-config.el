;;; modules/evil.el --- Vim emulation -*- lexical-binding: t; -*-
;;
;; Set my/use-evil to t (e.g. in init.el) to re-enable evil instead of meow.

(defvar my/use-evil nil
  "When non-nil, load evil instead of meow for modal editing.")

(when my/use-evil

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

) ; end (when my/use-evil)

(provide 'evil-config)
;;; evil.el ends here
