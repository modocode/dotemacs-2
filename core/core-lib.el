;;; core-lib.el --- Custom Emacs Function -*- lexical-binding: t; _*_


(defun my/set-font (font-name size)
  "Set the default face font if FONT-NAME is available.
Returns t if successful, nil otherwise."
  (when (member font-name (font-family-list))
    (set-face-attribute 'default nil :font font-name :height size)
    t)) ; Return t so the 'or' block knows to stop




(provide 'core-lib.el)
