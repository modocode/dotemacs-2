;;; mo-modal-tutor.el --- Hands-on modal editing lessons -*- lexical-binding: t; -*-

(require 'mo-modal)
(require 'general)

(defconst mo-modal-tutor--lessons
  '((:title "Movement and counts"
     :instructions "In CMD, f/b move a character and n/p move a line.
a/e move to the beginning/end of the line. Digits give a count.

TASK: Move down twice, up once, two characters right, one left,
then to the beginning and end of that line. Finish after south."
     :practice "north\nsouth\neast\nwest\n"
     :keys "n n p 2 f b a e"
     :result "north\nsouth\neast\nwest\n"
     :note "The text stays unchanged; the cursor finishes after south.")
    (:title "Start writing"
     :instructions "i enters WRITE. Letters now insert text. Escape returns to CMD.
In a terminal, C-c C-g is the portable alternative to Escape.
o moves forward a word; u moves backward a word. Both are single keys.
Counts work too: 3 o moves forward three words.

TASK: Add red between The and fox."
     :practice "The fox is quick.\n"
     :keys "o i SPC r e d <escape>"
     :result "The red fox is quick.\n"
     :note "After i, type a space and red. The existing space stays in place.")
    (:title "Grow and shrink a selection"
     :instructions "v selects a syntactic unit. Another v expands; V contracts.
The modeline changes from CMD to SELECT. Escape clears the region.

TASK: Move one character right, select red, expand to red green,
then contract back to red. Clear the selection when finished."
     :practice "(red green)\n"
     :keys "f v v V <escape>"
     :result "(red green)\n"
     :note "Watch the highlight after each key. Selection alone changes no text.")
    (:title "Change a word"
     :instructions "In SELECT, h cuts the region and enters WRITE immediately.
This is the central loop: select, change, type, return to CMD.

TASK: Replace slow with fast."
     :practice "slow fox\n"
     :keys "v h f a s t <escape>"
     :result "fast fox\n"
     :note "No extra i is needed after h. The old word goes into the kill ring.")
    (:title "Select manually, cut, and paste"
     :instructions "C-SPC anchors a selection at point in CMD. Movement extends it.
In SELECT, s cuts; in CMD, y yanks (pastes).
Selecting through the start of the next line includes the newline.

TASK: Move the entire first line below the second line."
     :practice "first\nsecond\n"
     :keys "C-SPC n s n y"
     :result "second\nfirst\n"
     :note "After cutting, n moves to the blank line after second. Then y pastes.")
    (:title "Copy without removing anything"
     :instructions "In SELECT, c copies and returns to CMD. Use y to paste.
The same kill ring is used by ordinary Emacs commands.

TASK: Make the line say echo echo, with one space between the words."
     :practice "echo\n"
     :keys "v c e i SPC <escape> y"
     :result "echo echo\n"
     :note "Copy, move to line end, insert a space in WRITE, return to CMD, paste.")
    (:title "Delete without copying"
     :instructions "In SELECT, d deletes without copying. Unlike s, it leaves the
kill ring alone. Counts also work while extending a selection.

TASK: Remove the first five characters, oops!, leaving keep."
     :practice "oops!keep\n"
     :keys "C-SPC 5 f d"
     :result "keep\n"
     :note "Use d to throw text away and keep your previous copy.")
    (:title "Move the other end of a selection"
     :instructions "A region has two ends: point (the cursor) and mark (the anchor).
In SELECT, ; exchanges them. Movement then adjusts the other end.

TASK: Select abcd, exchange the ends, move one character right,
then delete only bcd. Leave aef."
     :practice "abcdef\n"
     :keys "C-SPC 4 f ; f d"
     :result "aef\n"
     :note "After ; f, a is outside the highlight and survives the deletion.")
    (:title "Surround a selection"
     :instructions "In SELECT, ( surrounds with parentheses. Likewise [, {, a double
quote, or a single quote surrounds with that matching pair.
The result stays selected so you can transform it again.

TASK: Put signal inside parentheses, then clear the selection."
     :practice "signal\n"
     :keys "v ( <escape>"
     :result "(signal)\n"
     :note "Press only the opening delimiter; mo-modal inserts both sides.")
    (:title "Undo an edit"
     :instructions "In CMD, / invokes undo through God's translation to C-/.
Use Escape first if you want ordinary undo with no active selection.

TASK: Select and delete keep, then undo the deletion."
     :practice "keep\n"
     :keys "v d /"
     :result "keep\n"
     :note "The final text matches the original. Watch it disappear and return.")
    (:title "Search, then change the match"
     :instructions "In CMD, s starts forward search. Type the search text, then RET.
u moves backward a word. Explicit C-s also searches in SELECT,
where the plain s key means cut instead.

TASK: Find gamma and replace it with delta."
     :practice "alpha beta gamma\n"
     :keys "s g a m m a RET u v h d e l t a <escape>"
     :result "alpha beta delta\n"
     :note "During search, letters are search input. RET returns to CMD.")
    (:title "Final challenge"
     :instructions "Try this before reading the hint below.

TASK: Change slow to quick, surround fox with double quotes,
and delete the entire bad line, including its newline.

BONUS: Select the finished line with C-SPC and n. Try > to indent,
then < to move it back. Escape clears the selection."
     :practice "slow fox\nbad\n"
     :keys "v h q u i c k <escape> o u v \" <escape> n a C-SPC n d"
     :result "quick \"fox\"\n"
     :note "Use h for replacement, a quote to surround, and d to discard a line.")
    (:title "ADVANCED: choose the exact text object"
     :instructions "The comma prefix adds tools without changing your existing keys.
, w selects a word; , s a code symbol; , l whole lines; , p a paragraph;
, e an expression. A count works with lines: 2 , l selects two lines.

TASK: Select and delete the entire first line, including its newline."
     :practice "discard this line\nkeep\n"
     :keys ", l d"
     :result "keep\n"
     :note "The object selector enters SELECT. Your usual s/c/d/h actions apply.")
    (:title "Edit inside a surrounding pair"
     :instructions ", i selects inside the nearest balanced pair or string.
, a includes the delimiters. These use the current mode's syntax.
Use them from inside an enclosure or on its opening delimiter.

TASK: Replace the contents of the parentheses with blue, keeping the pair."
     :practice "(red green)\n"
     :keys ", i h b l u e <escape>"
     :result "(blue)\n"
     :note "Try , a afterward to select the parentheses along with their contents.")
    (:title "Edit matching text one occurrence at a time"
     :instructions ", / pins the selected text as an occurrence target.
, n and , N select its next/previous literal, case-sensitive match.
, u uppercases a selection. , . repeats the last region transformation.

TASK: Uppercase all three occurrences of red, reviewing each one."
     :practice "red red red\n"
     :keys ", w , / , u , n , . , n , . <escape>"
     :result "RED RED RED\n"
     :note "The pinned target stays red even after you edit it. , / pins a new one.")
    (:title "Repeat a surround on another selection"
     :instructions ", . also repeats surrounds, indentation, case changes, comments,
and replacement from the kill ring. It uses your current selection.
The remembered transformation belongs to this buffer.

TASK: Put each word in its own pair of parentheses."
     :practice "alpha beta\n"
     :keys ", w ( <escape> o u , w , . <escape>"
     :result "(alpha) (beta)\n"
     :note "The second surround reuses the first one's delimiters on a new word.")
    (:title "Duplicate and change the copy"
     :instructions ", d duplicates your selection, or the current line when nothing
is selected. The new copy is selected immediately.

TASK: Duplicate the line, then replace the copy with two and a newline."
     :practice "one\n"
     :keys ", d h t w o RET <escape>"
     :result "one\ntwo\n"
     :note "h changes the selected copy. RET restores its newline as you type.")
    (:title "Reuse copied text across several matches"
     :instructions ", r replaces a selection with the latest kill-ring entry and keeps
the replacement selected. It preserves the kill ring. , . remembers
that replacement even if you subsequently copy something else.

TASK: Copy new, then use it to replace both occurrences of old."
     :practice "new old old\n"
     :keys ", w c o u , w , / , r , n , . <escape>"
     :result "new new new\n"
     :note "You decide when to advance and when to replace. Nothing runs in bulk.")
    (:title "Focus a region and work only inside it"
     :instructions ", z temporarily narrows the buffer to your selection. The rest is
hidden, and searches stay inside this region. , Z shows everything again.
The modeline displays FOCUS while narrowed.

TASK: Uppercase red inside the parentheses, leaving the next line alone."
     :practice "(red red)\nred\n"
     :keys ", a , z a f , w , / , u , n , . <escape> , Z"
     :result "(RED RED)\nred\n"
     :note "Focus also works on a selected function, paragraph, or group of lines.")
    (:title "Open space to write above and below"
     :instructions ", O opens an indented line above; , o opens one below.
Both enter WRITE immediately. Plain u/o still move by word.

TASK: Write top above middle, then bottom below middle."
     :practice "middle\n"
     :keys ", O t o p <escape> n , o b o t t o m <escape>"
     :result "top\nmiddle\nbottom\n"
     :note "Use these to add code or prose without first positioning at a line end."))
  "Lessons with editable practice text, expected results, and key hints.")

(defvar-local mo-modal-tutor--positions nil
  "List of (HEADING-MARKER . PRACTICE-MARKER) for this tutor copy.")

(define-derived-mode mo-modal-tutor-mode text-mode "Modal Tutor"
  "Editable practice for mo-modal.  Each launch creates a fresh buffer."
  (setq-local header-line-format
              "  Tutor | C-c C-j practice | C-c C-n/p lessons | C-c C-a advanced | C-c C-r new")
  (setq-local auto-fill-function nil)
  (setq-local buffer-offer-save nil))

(defun mo-modal-tutor--index ()
  "Return the index of the lesson at point."
  (unless mo-modal-tutor--positions (user-error "This is not a tutor buffer"))
  (let ((index 0) (found -1))
    (dolist (positions mo-modal-tutor--positions)
      (when (<= (car positions) (point)) (setq found index))
      (setq index (1+ index)))
    found))

(defun mo-modal-tutor--go (position)
  "Clear the selection, enter CMD, and move to POSITION."
  (mo-modal-enter-command)
  (widen)
  (goto-char position)
  (when (get-buffer-window (current-buffer)) (recenter 2)))

(defun mo-modal-tutor-next ()
  "Go to the next lesson."
  (interactive)
  (let ((index (1+ (mo-modal-tutor--index))))
    (if (>= index (length mo-modal-tutor--positions))
        (message "Last lesson! C-c C-r opens a fresh copy for another round.")
      (mo-modal-tutor--go (car (nth index mo-modal-tutor--positions))))))

(defun mo-modal-tutor-previous ()
  "Go to the previous lesson."
  (interactive)
  (mo-modal-tutor--go (car (nth (max 0 (1- (mo-modal-tutor--index)))
                              mo-modal-tutor--positions))))

(defun mo-modal-tutor-practice ()
  "Enter CMD at the start of this lesson's practice text."
  (interactive)
  (mo-modal-tutor--go (cdr (nth (max 0 (mo-modal-tutor--index))
                              mo-modal-tutor--positions))))

(defun mo-modal-tutor-skip-basics ()
  "Jump to the advanced lessons, widening any focused practice region."
  (interactive)
  (unless (> (length mo-modal-tutor--positions) 12)
    (user-error "Open a fresh tutor with C-c C-r for the advanced lessons"))
  (mo-modal-tutor--go (car (nth 12 mo-modal-tutor--positions))))

;;;###autoload
(defun mo-modal-tutor-advanced ()
  "Open a fresh tutor and jump directly to the advanced workflows."
  (interactive)
  (let ((buffer (mo-modal-tutor)))
    (mo-modal-tutor-skip-basics)
    buffer))

(general-define-key :keymaps 'mo-modal-tutor-mode-map
  "C-c C-n" #'mo-modal-tutor-next
  "C-c C-p" #'mo-modal-tutor-previous
  "C-c C-j" #'mo-modal-tutor-practice
  "C-c C-a" #'mo-modal-tutor-skip-basics
  "C-c C-r" #'mo-modal-tutor)

;;;###autoload
(defun mo-modal-tutor ()
  "Open a fresh editable tutor buffer with twenty hands-on lessons.
Existing attempts are kept.  The guide is never edited on disk."
  (interactive)
  (require 'god-mode)
  (require 'expand-region)
  (require 'mo-modal-tools)
  (unless (eq (lookup-key mo-modal-command-map (kbd "i")) 'mo-modal-enter-write)
    (user-error "Load modules/keybindings.el before starting the modal tutor"))
  (let ((buffer (generate-new-buffer "*Mo Modal Tutor*")))
    (with-current-buffer buffer
      (mo-modal-tutor-mode)
      ;; Keep automatic writing assistants from changing the practice examples.
      (dolist (mode '(corfu-mode yas-minor-mode smartparens-mode
                     meow-mode evil-local-mode selected-minor-mode))
        (when (and (boundp mode) (symbol-value mode)) (funcall mode -1)))
      (insert "MO MODAL TUTOR\n==============\n\n"
              "Learn by editing this buffer: 20 minutes for basics, 15 for advanced.\n"
              "This is a disposable practice copy, with no file to save.\n"
              "Other tutor copies and the original guide are left alone.\n\n"
              "HOW TO USE THIS TUTOR\n"
              "  Read a lesson, then C-c C-j jumps to its practice text in CMD.\n"
              "  Edit under PRACTICE. Compare with EXPECTED below.\n"
              "  C-c C-n / C-c C-p: next / previous lesson.\n"
              "  C-c C-a: skip to the advanced tools.\n"
              "  C-c C-r: open a fresh copy to start over.\n"
              "  These shortcuts work in all three states.\n\n"
              "KEY NOTATION\n"
              "  C-c C-j: hold Control and press c, then j.\n"
              "  x s: press x, release it, then press s.\n"
              "  SPC = Space; RET = Enter; V = uppercase (Shift-v).\n"
              "  <escape> = Escape. Use C-c C-g instead in a terminal.\n"
              "  Hints list keystrokes; do not type the separating spaces.\n\n"
              "YOUR THREE STATES\n"
              "  WRITE: i from CMD; type normally. Escape returns to CMD.\n"
              "  CMD: God mode commands without holding Control.\n"
              "  SELECT: motion extends the highlight; s/c/d/h act on it.\n"
              "  Escape clears a selection. C-g keeps normal Emacs cancellation.\n\n"
              "Read Lesson 1 below, then press C-c C-j.\n\n")
      (cl-loop for lesson in mo-modal-tutor--lessons for number from 1 do
               (let ((heading (point-marker)))
                 (insert (propertize (format "LESSON %d: %s\n" number (plist-get lesson :title))
                                     'face 'font-lock-function-name-face)
                         (make-string 68 ?-) "\n"
                         (plist-get lesson :instructions) "\n\nPRACTICE\n")
                 (let ((practice (point-marker)))
                   (insert (plist-get lesson :practice))
                   (push (cons heading practice) mo-modal-tutor--positions))
                 (insert "\nEXPECTED\n" (plist-get lesson :result)
                         "\nHINT (start with C-c C-j on an untouched exercise)\n  "
                         (plist-get lesson :keys) "\n"
                         (plist-get lesson :note) "\n\n\n")))
      (setq mo-modal-tutor--positions (nreverse mo-modal-tutor--positions))
      (insert "YOU FINISHED\n============\n\n"
              "BONUS: JUMP TO WHAT YOU SEE\n"
              "  , j starts an Avy text jump: type visible text, pause, then type\n"
              "  the label shown on your target. , J labels visible lines.\n"
              "  In SELECT, jumping extends your region to that target.\n"
              "  Try jumping between these visible targets: ORBIT  LANTERN  RIVER.\n\n"
              "OTHER TRANSFORMATIONS\n"
              "  , c lowercase     , t capitalize     , ; toggle comment\n"
              "  , = reindent using your major mode   , . repeat transformation\n\n"
              "Try the final challenge again without the hint.\n"
              "In everyday buffers, SPC opens your leader menu; M-SPC also works\n"
              "while writing. SPC h t opens another tutor. SPC h k describes a key.\n"
              "M-x god-mode-describe-key explains a God-translated command.\n\n"
              "Close this copy with C-x k RET. Open a new one any time with\n"
              "M-x mo-modal-tutor.\n")
      (setq buffer-undo-list nil)
      (set-buffer-modified-p nil)
      (goto-char (point-min))
      (mo-modal-mode 1))
    (pop-to-buffer buffer)
    buffer))

(provide 'mo-modal-tutor)
;;; mo-modal-tutor.el ends here
