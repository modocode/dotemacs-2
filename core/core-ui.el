;;; core-ui.el --- UI Configuration -*- lexical-binding: t; -*-
(require 'core-lib)

;; Apply fonts after all init files have loaded so that os/*.el overrides
;; in `my/fonts' (set via `my/register-font') are in effect before we read them.
(add-hook 'after-init-hook #'my/apply-font)

;; Always skip the "Really load?" and "Treat as safe?" prompts.
;; custom-safe-themes='all suppresses the check, but if something resets it
;; between early-init and an interactive M-x load-theme call, Emacs tries
;; (cons new-hash 'all) → improper list → apply error.  This advice ensures
;; no-confirm is always t regardless of custom-safe-themes state.
(advice-add 'load-theme :around
  (lambda (fn theme &optional _no-confirm no-enable)
    (funcall fn theme t no-enable)))

;; Enable variable-pitch-mode in text and Org buffers so prose uses the
;; variable-pitch face while code blocks stay in fixed-pitch.
(add-hook 'text-mode-hook
  (lambda ()
    (variable-pitch-mode 1)))

(provide 'core-ui)
