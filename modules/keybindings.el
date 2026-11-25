
;;; keybindings.el ---simple keybinds for emacs -*- lexical-binding: t; -*-

(defmacro my/bind-keys (feature keymap &rest bindings)
  "Bind alternating KEY and COMMAND pairs in KEYMAP after FEATURE loads.
FEATURE and KEYMAP are unquoted symbols.  A nil FEATURE applies bindings
immediately.  KEY is a key-description string; COMMAND is an expression
such as #'find-file or a keymap variable.

A literal nil COMMAND removes the entry from KEYMAP, allowing a parent
or lower-priority keymap binding to take effect.  Changes apply to every
buffer using KEYMAP.

Examples:
  (my/bind-keys org org-mode-map
    \"C-c j\" #'org-goto
    \"C-c x\" nil)
  (my/bind-keys nil global-map
    \"M-SPC\" #'cycle-spacing)"
  (declare (indent 2) (debug (sexp sexp &rest sexp)))
  (unless (zerop (% (length bindings) 2))
    (error "my/bind-keys requires KEY COMMAND pairs"))
  (let (forms)
    (while bindings
      (let ((key (pop bindings))
            (command (pop bindings)))
        (push (if command
                  `(keymap-set ,keymap ,key ,command)
                `(keymap-unset ,keymap ,key t))
              forms)))
    (if feature
        `(with-eval-after-load ',feature ,@(nreverse forms))
      `(progn ,@(nreverse forms)))))



(require 'thingatpt)

;; Highlight the active region.
(transient-mark-mode 1)


;; Typing replaces a selected region.
(delete-selection-mode 1)

;; Make C-k at the beginning of a line
;; kill the whole line.
(setq kill-whole-line t)


;; Allow mark commands to extend an active region.
(setq mark-even-if-inactive nil)

;; Enable repeatable command sequences.
(repeat-mode 1)


;; -----------------------------------------------
;; Selection primitives
;; -----------------------------------------------

(defun my/select-bounds (beg end)
  "Activate the region between BEG and END."
  (goto-char beg)
  (push-mark end nil t))

(defun my/select-thing (thing)
  "Select THING at point."
  (let ((bounds (bounds-of-thing-at-point thing)))
    (unless bounds
      (user-error "No %s at point" thing))
    (my/select-bounds (car bounds) (cdr bounds))))


(defun my/select-word ()
  "Select the word at point."
  (interactive)
  (my/select-thing 'word))


(defun my/select-line ()
  "Select the current line, including its newline."
  (interactive)
  (my/select-bounds
   (line-beginning-position)
   (save-excursion (forward-line 1) (point))))

(defun my/select-defun ()
  "Select the current function or defun."
  (interactive)
  (let ((beg (save-excursion
               (beginning-of-defun)
               (point)))
        (end (save-excursion
               (end-of-defun)
               (point))))
    (my/select-bounds beg end)))



(defun my/copy-defun-and-paste ()
  "Select the current function or defun."
  (interactive)
  (let ((beg (save-excursion
               (beginning-of-defun)
               (point)))
        (end (save-excursion
               (end-of-defun)
               (point))))
    (progn
      (my/select-bounds beg end)
      (kill-ring-save beg end)
      (end-of-defun)
      (yank)
      )))


(defun my/select-sexp ()
  "Select the next syntactic expression."
  (interactive)
  (let ((beg (point))
        (end (save-excursion
               (forward-sexp 1)
               (point))))
    (my/select-bounds beg end)))


(defun my/select-parens (&optional around)
  "Select enclosing parentheses.
With AROUND non-nil, include the delimiters."
  (interactive "P")
  (let* ((open
          (cond
           ((looking-at-p "\\s(") (point))
           ((nth 1 (syntax-ppss)))
           (t nil))))
    (unless open
      (user-error "Not inside a parenthesized expression"))
    (let ((close (scan-sexps open 1)))
      (unless close
        (user-error "Unbalanced expression"))
      (my/select-bounds
       (if around open (1+ open))
       (if around close (1- close))))))

(defun my/select-parens-around ()
  "Select surrounding parentheses and contents."
  (interactive)
  (my/select-parens t))


(defun my/target-bounds ()
  "Return active region bounds, or current line bounds."
  (if (use-region-p)
      (cons (region-beginning) (region-end))
    (cons (line-beginning-position)
          (save-excursion
            (forward-line 1)
            (point)))))

(defun my/kill ()
  "Kill active region, otherwise kill current line."
  (interactive)
  (pcase-let ((`(,beg . ,end) (my/target-bounds)))
    (kill-region beg end)))

(defun my/delete ()
  "Delete active region or current line without saving it."
  (interactive)
  (pcase-let ((`(,beg . ,end) (my/target-bounds)))
    (delete-region beg end)))

(defun my/copy ()
  "Copy active region or current line."
  (interactive)
  (pcase-let ((`(,beg . ,end) (my/target-bounds)))
    (kill-ring-save beg end)
    (message "Copied")))

(defun my/block-bounds ()
  "Return complete line bounds covering region or point."
  (let* ((selected (use-region-p))
         (beg (if selected (region-beginning) (point)))
         (end (if selected (region-end) (point))))
    (cons
     (save-excursion
       (goto-char beg)
       (line-beginning-position))
     (save-excursion
       (goto-char end)
       ;; A region ending at column zero does not
       ;; include the following line.
       (when (and selected (> end beg) (bolp))
         (forward-line -1))
       (forward-line 1)
       (point)))))

(defun my/move-block (direction)
  "Move current line or selected lines by DIRECTION.
DIRECTION is -1 for up and 1 for down."
  (let* ((selected (use-region-p))
         (bounds (my/block-bounds))
         (beg (car bounds))
         (end (cdr bounds))
         (length (- end beg))
         (column (current-column))
         (new-beg nil))
    (cond
     ((< direction 0)
      (when (= beg (point-min))
        (user-error "Already at beginning of buffer"))
      (let ((prev (save-excursion
                    (goto-char beg)
                    (forward-line -1)
                    (point))))
        (transpose-regions prev beg beg end)
        (setq new-beg prev)))

     ((> direction 0)
      (when (= end (point-max))
        (user-error "Already at end of buffer"))
      (let ((next (save-excursion
                    (goto-char end)
                    (forward-line 1)
                    (point))))
        (transpose-regions beg end end next)
        (setq new-beg (+ beg (- next end))))))

    (if selected
        (my/select-bounds new-beg (+ new-beg length))
      (goto-char new-beg)
      (move-to-column column))))

(defun my/move-up ()
  "Move active lines or current line up."
  (interactive)
  (my/move-block -1))

(defun my/move-down ()
  "Move active lines or current line down."
  (interactive)
  (my/move-block 1))



(my/bind-keys nil global-map
  "C-c w" #'my/select-word
  "C-c l" #'my/select-line
  "C-c d" #'my/select-defun
  "C-c e" #'my/select-sexp
  "C-c D" #'my/copy-defun-and-paste
  "C-c p" #'my/select-parens-around
  "C-c P" #'my/select-parens
  "M-n"   #'my/move-down
  "M-p"   #'my/move-up
  "C-="   #'er/expand-region
  )





;; Examples To adapt:
;; (my/bind-keys org org-mode-map
;;   "C-c j" #'org-goto
;;   "C-c x" nil)
;;   "M-SPC" #'cycle-spacing)
;; (my/bind-keys nil global-map


;; (use-package god-mode
;;   :ensure t
;;   :bind ("<escape>" . god-local-mode))
;; (define-key god-local-mode-map (kbd ".") #'repeat)



(add-to-list 'load-path "~/git/devil")
(add-to-list 'load-path "~/git/unbound")
(add-to-list 'load-path "~/git/free-keys")
(add-to-list 'load-path "~/git/substitute")
(require 'unbound)
(require 'devil)
(require 'free-keys)
(global-devil-mode)
(global-set-key (kbd "C-,") 'global-devil-mode)



(use-package substitute
  :ensure t
  :config
  ;; Set this to nil if you do not like visual feedback on the matching
  ;; target.  Default is t.
  (setq substitute-highlight nil)

  ;; Set this to t if you want to always treat the letter casing
  ;; literally.  Otherwise each command accepts a `C-u' prefix
  ;; argument to do this on-demand.
  (setq substitute-fixed-letter-case t)

  ;; If you want a message reporting the matches that changed in the
  ;; given context.  We don't do it by default.
  (add-hook 'substitute-post-replace-functions #'substitute-report-operation)

  ;; Use C-c s as a prefix for all Substitute commands.
  (define-key global-map (kbd "C-c s") #'substitute-prefix-map))



(defun move-nth-new-line ()
  (interactive)
  (end-of-line)
  (newline))


;; unmappings 
(my/bind-keys nil global-map
  "M-u" nil
  "C-h h" nil 
  )
;; embark keys
(my/bind-keys nil global-map
  "C-c C-c" #'embark-collect
  "C-c C-e" #'embark-export
  "C-c C-a" #'embark-act
  "C-c C-S-A" #'embark-act-all
  "C-c C-b" #'embark-become
  )



;; capitializations and additional help 
(my/bind-keys nil global-map
  "M-c" #'capitalize-dwim
  "M-l" #'downcase-dwim ; "lower" case
  "M-u" #'upcase-dwim
  "M-=" #'count-words 
  "C-h u" #'apropos-user-option
  "C-h F" #'apropos-function ; lower case is `describe-function'
  "C-h V" #'apropos-variable ; lower case is `describe-variable'
  "C-h L" #'apropos-library ; lower case is `view-lossage'
  )


;; process lines
(my/bind-keys nil global-map
  "C-S-t"   #'transpose-lines
  "M-t"     #'transpose-words
  "C-M-t"   #'transpose-sexps
  "C-S-k" #'duplicate-dwim

  )


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
  "m" #'maximize-window
  "r" #'rotate-window
  "s" #'shrink-window
  )


(defvar-keymap mo-org-prefix-map
  :doc "Prefix for Org Mode"
  "c" #'org-capture
  "A" #'org-agenda
  "R" #'my/org-refile-to-heading
  "i" #'my/org-process-inbox
  "t" #'org-todo
  "C i" #'org-clock-in
  "C o" #'org-clock-out
  )

(my/bind-keys org org-agenda-mode-map
  "n" #'org-agenda-next-item
  "p" #'org-agenda-previous-item
  )

(defvar-keymap mo-email-news-prefix
  :doc "Prefix for My Mail And RSS"
  :prefix 'mo-email-news
  "e" #'elfeed
  "n" #'notmuch
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
  "0" #'delete-window
  "1" #'delete-other-windows
  "!" #'delete-other-windows-vertically
  "^" #'tear-off-window
  "2" #'split-window-below
  "@" #'split-root-window-below
  "3" #'split-window-right
  "#" #'split-root-window-right
  "O" #'other-window
  "E" #'mo-email-news
  "o" #'mo-org-prefix-map
  "w" #'mo-prefix-window-map
  "g" #'magit-status
  "Q" #'my/reload-init 
  )

(which-key-add-keymap-based-replacements mo-prefix-map
  "s" `("Searching" . ,my/consult-map)
  "i" `("insert" . ,mo-prefix-insert)
  "f" `("File" . ,mo-prefix-file)
  "o" `("Org" . ,mo-org-prefix-map)
  "w" `("Window" . ,mo-prefix-window-map)
  "E" `("News/Email" . ,mo-email-news)
  )


(keymap-set global-map "C-z" mo-prefix-map 
)



(provide 'keybindings)
;;; keybindings.el ends here
