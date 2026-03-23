;;; core-ui.el --- UI Configuration -*- lexical-binding: t; -*-
(require 'core-lib)

;; Apply fonts after all init files have loaded so that os/*.el overrides
;; in `my/fonts' (set via `my/register-font') are in effect before we read them.
(add-hook 'after-init-hook
  (lambda ()
    (when (display-graphic-p)
      ;; Default face — monospace baseline.  Falls back through known good fonts.
      (or (my/set-face-font 'default
            (my/font-name 'default) (my/font-height 'default))
          (my/set-font "LigaSauceCodePro NF" 110)
          (my/set-font "Hack" 110)
          (my/set-font "IBM Plex Mono" 110))
      ;; Fixed-pitch — used for code in prog-mode and inline code blocks in Org.
      (my/set-face-font 'fixed-pitch
        (my/font-name 'fixed) (my/font-height 'fixed))
      ;; Variable-pitch — used for prose in Org/text modes.
      (or (my/set-face-font 'variable-pitch
            (my/font-name 'variable) (my/font-height 'variable))
          (my/set-face-font 'variable-pitch "Source Serif 4" 130)
          (my/set-face-font 'variable-pitch "Georgia" 130)))))

(load-theme 'modus-vivendi t)

;; Enable variable-pitch-mode in text and Org buffers so prose uses the
;; variable-pitch face while code blocks stay in fixed-pitch.
(add-hook 'text-mode-hook
  (lambda ()
    (variable-pitch-mode 1)))

(provide 'core-ui)
