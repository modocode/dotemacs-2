;;; core-ui.el --- UI Configuration -*- lexical-binding: t; -*-
(require 'core-lib)


(when (display-graphic-p)
  (or (my/set-font "LigaSauceCodePro NF" 100)
	  (my/set-font "Hack" 100)
	  (my/set-font "IBM Plex Mono" 100)
	  ))



(load-theme 'modus-vivendi t)


(add-hook 'text-mode-hook
	(lambda ()
		(variable-pitch-mode 1)))


(provide 'core-ui)
