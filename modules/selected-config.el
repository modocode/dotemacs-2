;;; selected-config.el --- Legacy selection bindings for Meow -*- lexical-binding: t; -*-

(require 'mo-modal)

(when (eq my/modal-backend 'meow)
(defun my/surround-region (open close)
  "Surround the active region with OPEN and CLOSE."
  (interactive)
  (let ((beg (region-beginning))
        (end (region-end)))
    (goto-char end)
    (insert close)
    (goto-char beg)
    (insert open)))


(use-package selected
  :ensure t
  :demand t

  :config
  (selected-global-mode 1)

  (general-define-key
   :keymaps 'selected-keymap

   ;; Exit selection
   "q" #'selected-off
   "g" #'selected-off

   ;; Selection transformation
   "SPC u" #'upcase-region
   "SPC l" #'downcase-region

   ;; Clipboard / deletion
   "y" #'kill-ring-save
   "d" #'delete-region
   "x" #'kill-region

   ;; Editing
   ";" #'comment-dwim
   ">" #'my/indent-right
   "<" #'my/indent-left

   ;; Information
   "=" #'count-words-region
   "*" (lambda ()
         (interactive)
         (my/surround-region "*" "*"))

   ;; Surround
   "(" (lambda ()
         (interactive)
         (my/surround-region "(" ")"))
   "[" (lambda ()
         (interactive)
         (my/surround-region "[" "]"))
   "{" (lambda ()
         (interactive)
         (my/surround-region "{" "}"))
   "\"" (lambda ()
          (interactive)
          (my/surround-region "\"" "\""))
   "'" (lambda ()
         (interactive)
         (my/surround-region "'" "'"))))
) ; Meow backend

(provide 'selected-config)
;;; selected-config.el ends here
