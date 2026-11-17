
;;; keybindings.el ---simple keybinds for emacs -*- lexical-binding: t; -*-

;; (use-package god-mode
;;   :ensure t
;;   :bind ("<escape>" . god-local-mode))
;; (define-key god-local-mode-map (kbd ".") #'repeat)


(add-to-list 'load-path "~/git/devil")
(require 'devil)
(global-devil-mode)
(global-set-key (kbd "C-,") 'global-devil-mode)



(defvar-keymap my/consult-map
  :doc "Consult search and navigation commands."
  "b" #'consult-buffer
  "r" #'consult-recent-file
  "l" #'consult-line
  "g" #'consult-grep
  "s" #'consult-ripgrep
  "f" #'consult-find
  "i" #'consult-imenu
  "o" #'consult-outline
  "m" #'consult-bookmark)


(defvar-keymap mo-prefix-window-map
  :doc "Prefix for window managment"
  )


(defvar-keymap my-mo-file-prefix
  :doc "Prefix Mappings for Files"
  :prefix 'mo-prefix-file
  "f" #'find-file
  "F" #'find-file-other-window
  "d" #'dired
  "b" #'consult-buffer
  )

(defvar-keymap mo-prefix-insert-map
  :doc "Prefix keymap for character insertion."
  :name "Insert"
  :prefix 'mo-prefix-insert
  "i" #'insert-char
  "e" #'emoji-search
  "q" #'quoted-insert
  "s" #'emoji-search
  "l" #'emoji-list)

(defvar-keymap mo-prefix-map
  :doc "global keymaps with C-z"
  "i" mo-prefix-insert
  "f" mo-prefix-file 
  "s" my/consult-map
  )

(which-key-add-keymap-based-replacements mo-prefix-map
  "s" `("Searching" . ,my/consult-map)
  "i" `("insert" . ,mo-prefix-insert)
  "f" `("File" . ,mo-prefix-file)
  )


(keymap-set global-map "C-z" mo-prefix-map 
)

(provide 'keybindings)
;;; keybindings.el ends here
