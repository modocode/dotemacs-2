;;; os/macos.el --- macOS-specific configuration -*- lexical-binding: t; -*-
;;
;; Loaded automatically on macOS/Darwin by init.el.
;; Put anything macOS-specific here: modifier key remapping,
;; path-from-shell fixes, native fullscreen behaviour, etc.

;; Example: swap Option and Command so muscle memory from terminal works
;; (setq mac-option-modifier  'super
;;       mac-command-modifier 'meta)

;; Example: use the exec-path-from-shell package to inherit $PATH from
;; your shell profile (needed because macOS app bundles don't source .zshrc)
;; (my/with-binary "zsh"
;;   (use-package exec-path-from-shell
;;     :ensure t
;;     :demand t
;;     :config (exec-path-from-shell-initialize)))

(provide 'macos)
;;; macos.el ends here
