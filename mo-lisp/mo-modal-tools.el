;;; mo-modal-tools.el --- Composable selection tools -*- lexical-binding: t; -*-

(require 'mo-modal)
(require 'general)
(require 'thingatpt)
(require 'newcomment)

(defvar mo-modal-tools-map (make-sparse-keymap))
(defvar-local mo-modal-match-text nil
  "Literal, case-sensitive text used by occurrence navigation in this buffer.")
(defvar avy-all-windows)
(defvar avy-dispatch-alist)
(declare-function avy-goto-char-timer "avy" (&optional arg))
(declare-function avy-goto-line "avy" (&optional arg))

(defun mo-modal-select-bounds (beg end)
  "Select BEG through END, with point at END."
  (mo-modal--require-mode)
  (unless (< beg end) (user-error "There is no text to select here"))
  (goto-char beg)
  (push-mark beg t t)
  (goto-char end)
  (mo-modal-enter-select))

(defun mo-modal-select-thing (thing)
  "Select THING at point, or report that it is absent."
  (let ((bounds (bounds-of-thing-at-point thing)))
    (unless bounds (user-error "No %s at point" thing))
    (mo-modal-select-bounds (car bounds) (cdr bounds))))

(defun mo-modal-select-word ()
  "Select the whole word at point."
  (interactive)
  (mo-modal-select-thing 'word))

(defun mo-modal-select-symbol ()
  "Select the whole symbol at point, according to the major mode."
  (interactive)
  (mo-modal-select-thing 'symbol))

(defun mo-modal-select-expression ()
  "Select the expression at point."
  (interactive)
  (mo-modal-select-thing 'sexp))

(defun mo-modal-select-paragraph ()
  "Select the paragraph at point."
  (interactive)
  (mo-modal-select-thing 'paragraph))

(defun mo-modal-select-lines (count)
  "Select COUNT complete lines, starting with the current line."
  (interactive "p")
  (unless (> count 0) (user-error "Use a positive line count"))
  (let ((beg (line-beginning-position))
        (end (save-excursion (forward-line count) (point))))
    (mo-modal-select-bounds beg end)))

(defun mo-modal--enclosure-bounds (inner)
  "Return the nearest syntactic enclosure bounds, omitting delimiters if INNER.
Point may be inside a string or list, or on its opening delimiter."
  (save-excursion
    (let* ((state (syntax-ppss))
           (start (cond ((nth 3 state) (nth 8 state))
                        ((and (char-after)
                              (memq (char-syntax (char-after)) '(?\( ?\")))
                         (point))
                        (t (nth 1 state))))
           (end (and start (condition-case nil (scan-sexps start 1)
                             (scan-error nil)))))
      (unless (and start end) (user-error "No balanced enclosure at point"))
      (cons (+ start (if inner 1 0)) (- end (if inner 1 0))))))

(defun mo-modal-select-inner ()
  "Select inside the nearest balanced list or string."
  (interactive)
  (pcase-let ((`(,beg . ,end) (mo-modal--enclosure-bounds t)))
    (mo-modal-select-bounds beg end)))

(defun mo-modal-select-around ()
  "Select the nearest balanced list or string, including delimiters."
  (interactive)
  (pcase-let ((`(,beg . ,end) (mo-modal--enclosure-bounds nil)))
    (mo-modal-select-bounds beg end)))

(defun mo-modal-pin-match ()
  "Remember the selection as a literal target for occurrence navigation."
  (interactive)
  (pcase-let ((`(,beg . ,end) (mo-modal--bounds)))
    (setq mo-modal-match-text (buffer-substring-no-properties beg end)))
  (message "Occurrence target: %s" (truncate-string-to-width mo-modal-match-text 60 nil nil t)))

(defun mo-modal--match (count backward)
  "Select the COUNTth occurrence of the pinned text, searching BACKWARD if non-nil."
  (mo-modal--require-mode)
  (unless (> count 0) (user-error "Use a positive occurrence count"))
  (let* ((seed-bounds (and (not mo-modal-match-text) (not (use-region-p))
                           (bounds-of-thing-at-point 'symbol)))
         (case-fold-search nil)
         (_seed (unless mo-modal-match-text
                  (if (use-region-p)
                      (mo-modal-pin-match)
                    (when seed-bounds
                      (setq mo-modal-match-text
                            (buffer-substring-no-properties (car seed-bounds)
                                                            (cdr seed-bounds)))))))
         (_valid (unless (and mo-modal-match-text (> (length mo-modal-match-text) 0))
                   (user-error "Select text and press , / to choose an occurrence target")))
         (bounds
          (save-excursion
            (when seed-bounds (goto-char (if backward (car seed-bounds) (cdr seed-bounds))))
            (when (use-region-p)
              (goto-char (if backward (region-beginning) (region-end))))
            (when (funcall (if backward #'search-backward #'search-forward)
                           mo-modal-match-text nil t count)
              (cons (match-beginning 0) (match-end 0))))))
    (unless bounds (user-error "No %s occurrence of %s in this buffer/restriction"
                               (if backward "previous" "next") mo-modal-match-text))
    (mo-modal-select-bounds (car bounds) (cdr bounds))))

(defun mo-modal-next-match (count)
  "Select the COUNTth next occurrence.  Pin a new target with , /."
  (interactive "p")
  (mo-modal--match count nil))

(defun mo-modal-previous-match (count)
  "Select the COUNTth previous occurrence.  Pin a new target with , /."
  (interactive "p")
  (mo-modal--match count t))

(defun mo-modal-repeat-transform ()
  "Apply the last successful transformation to the current selection.
This repeats region transformations, not arbitrary typing, cuts, or macros."
  (interactive)
  (unless mo-modal-last-transform (user-error "No region transformation to repeat yet"))
  (mo-modal--transform mo-modal-last-transform))

(defun mo-modal-upcase ()
  "Uppercase the selection and keep it selected."
  (interactive)
  (mo-modal--transform #'upcase-region))

(defun mo-modal-downcase ()
  "Lowercase the selection and keep it selected."
  (interactive)
  (mo-modal--transform #'downcase-region))

(defun mo-modal-capitalize ()
  "Capitalize the selection and keep it selected."
  (interactive)
  (mo-modal--transform #'capitalize-region))

(defun mo-modal-comment ()
  "Toggle comments on the selected region and keep it selected."
  (interactive)
  (mo-modal--transform #'comment-or-uncomment-region))

(defun mo-modal-reindent ()
  "Reindent the selected region according to its major mode."
  (interactive)
  (mo-modal--transform #'indent-region))

(defun mo-modal-replace-from-kill ()
  "Replace the selection with the latest kill, without overwriting the kill ring.
Repeating this action reuses the same replacement even if the kill ring changes."
  (interactive)
  (let ((replacement (copy-sequence (current-kill 0 t))))
    (mo-modal--transform
     (lambda (beg end)
       (delete-region beg end)
       (goto-char beg)
       (insert-for-yank replacement)))))

(defun mo-modal-duplicate ()
  "Duplicate the selection, or the current line; select the new copy."
  (interactive)
  (mo-modal--require-mode)
  (barf-if-buffer-read-only)
  (let* ((region (use-region-p))
         (beg (if region (region-beginning) (line-beginning-position)))
         (end (if region (region-end) (save-excursion (forward-line 1) (point))))
         (text (buffer-substring-no-properties beg end))
         start finish)
    (when (= beg end) (user-error "There is no text to duplicate"))
    (save-excursion
      (atomic-change-group
        (goto-char end)
        (when (and (not region) (not (bolp))) (insert "\n"))
        (setq start (point))
        (insert text)
        (setq finish (point))))
    (mo-modal-select-bounds start finish)))

(defun mo-modal--open-line (above)
  "Insert an indented line ABOVE the current one if non-nil, otherwise below."
  (mo-modal--require-mode)
  (barf-if-buffer-read-only)
  (let (destination)
    (save-excursion
      (atomic-change-group
        (if above
            (progn (beginning-of-line) (insert "\n") (forward-line -1)
                   (indent-according-to-mode))
          (end-of-line)
          (newline-and-indent))
        (setq destination (point))))
    (goto-char destination)
    (mo-modal-enter-write)))

(defun mo-modal-open-below ()
  "Open an indented line below and enter Write."
  (interactive)
  (mo-modal--open-line nil))

(defun mo-modal-open-above ()
  "Open an indented line above and enter Write."
  (interactive)
  (mo-modal--open-line t))

(defun mo-modal-focus ()
  "Narrow the buffer to the selected region.  Use , Z to widen again."
  (interactive)
  (pcase-let ((`(,beg . ,end) (mo-modal--bounds)))
    (narrow-to-region beg end)
    (mo-modal-enter-command)))

(defun mo-modal-unfocus ()
  "Show the entire buffer again."
  (interactive)
  (widen))

(defun mo-modal--jump (command)
  "Use Avy COMMAND in this window, preserving a selection's anchor."
  (mo-modal--require-mode)
  (require 'avy)
  (let ((avy-all-windows nil)
        (avy-dispatch-alist nil)
        (anchor (and (region-active-p) (copy-marker (mark)))))
    (unwind-protect
        (funcall command)
      (when anchor
        (set-mark anchor)
        (set-marker anchor nil)
        (mo-modal-enter-select)))))

(defun mo-modal-jump ()
  "Jump to visible text in this window; in Select, extend to that target."
  (interactive)
  (mo-modal--jump #'avy-goto-char-timer))

(defun mo-modal-jump-line ()
  "Jump to a visible line in this window, extending any selection."
  (interactive)
  (mo-modal--jump #'avy-goto-line))

;; A single additional prefix keeps the established motions and God prefixes.
(general-define-key :keymaps 'mo-modal-command-map "," mo-modal-tools-map)
(general-define-key :keymaps 'mo-modal-tools-map
  "w" '(mo-modal-select-word :which-key "word")
  "s" '(mo-modal-select-symbol :which-key "symbol")
  "l" '(mo-modal-select-lines :which-key "whole lines")
  "p" '(mo-modal-select-paragraph :which-key "paragraph")
  "e" '(mo-modal-select-expression :which-key "expression")
  "i" '(mo-modal-select-inner :which-key "inside pair/string")
  "a" '(mo-modal-select-around :which-key "around pair/string")
  "/" '(mo-modal-pin-match :which-key "pin occurrence target")
  "n" '(mo-modal-next-match :which-key "next occurrence")
  "N" '(mo-modal-previous-match :which-key "previous occurrence")
  "." '(mo-modal-repeat-transform :which-key "repeat transformation")
  "u" '(mo-modal-upcase :which-key "uppercase")
  "c" '(mo-modal-downcase :which-key "lowercase")
  "t" '(mo-modal-capitalize :which-key "capitalize")
  ";" '(mo-modal-comment :which-key "toggle comment")
  "=" '(mo-modal-reindent :which-key "reindent")
  "r" '(mo-modal-replace-from-kill :which-key "replace from kill ring")
  "d" '(mo-modal-duplicate :which-key "duplicate selection/line")
  "o" '(mo-modal-open-below :which-key "write below")
  "O" '(mo-modal-open-above :which-key "write above")
  "z" '(mo-modal-focus :which-key "focus selection")
  "Z" '(mo-modal-unfocus :which-key "show whole buffer")
  "j" '(mo-modal-jump :which-key "jump to visible text")
  "J" '(mo-modal-jump-line :which-key "jump to visible line"))

(provide 'mo-modal-tools)
;;; mo-modal-tools.el ends here
