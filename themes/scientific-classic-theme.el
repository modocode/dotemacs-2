(deftheme scientific-classic
  "Classic white scientific-programming editor theme.")

(custom-theme-set-faces
 'scientific-classic

 ;; Main editor
 '(default
   ((t (:background "#ffffff"
        :foreground "#000000"
        :family "DejaVu Sans Mono"))))

 '(cursor
   ((t (:background "#000000"))))

 '(fringe
   ((t (:background "#ffffff"
        :foreground "#000000"))))

 '(line-number
   ((t (:background "#ffffff"
        :foreground "#444444"))))

 '(line-number-current-line
   ((t (:background "#ffffff"
        :foreground "#000000"
        :weight bold))))

 ;; Syntax
 '(font-lock-comment-face
   ((t (:foreground "#0000ff"
        :weight bold))))

 '(font-lock-comment-delimiter-face
   ((t (:foreground "#0000ff"
        :weight bold))))

 '(font-lock-string-face
   ((t (:foreground "#ff0000"))))

 '(font-lock-constant-face
   ((t (:foreground "#ff00aa"))))

 '(font-lock-number-face
   ((t (:foreground "#ff00aa"))))

 '(font-lock-keyword-face
   ((t (:foreground "#000000"
        :weight bold))))

 '(font-lock-function-name-face
   ((t (:foreground "#000000"))))

 '(font-lock-variable-name-face
   ((t (:foreground "#000000"))))

 '(font-lock-type-face
   ((t (:foreground "#000000"
        :weight bold))))

 '(font-lock-builtin-face
   ((t (:foreground "#000000"))))

 '(font-lock-warning-face
   ((t (:foreground "#ff0000"
        :weight bold)))))

(provide-theme 'scientific-classic)
