;;; os/macos.el --- macOS-specific configuration -*- lexical-binding: t; -*-
;;
;; Loaded automatically on macOS/Darwin by init.el.
;; Put anything macOS-specific here: modifier key remapping,
;; path-from-shell fixes, native fullscreen behaviour, etc.

;; Example: swap Option and Command so muscle memory from terminal works
;; (setq mac-option-modifier  'super
;;       mac-command-modifier 'meta)

;; (my/with-binary "zsh"
;;   (use-package exec-path-from-shell
;;     :ensure t
;;     :demand t
;;     :config (exec-path-from-shell-initialize)))
;; (my/register-font 'default  "Inconsolata"    110)
;; (my/register-font 'fixed    "Inconsolata"    110)
;; (my/register-font 'variable "ETBembo"        130)
;;

(provide 'macos)
;;; macos.el ends here
