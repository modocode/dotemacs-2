;;; mo-modal.el --- Personal modal editing on top of God mode -*- lexical-binding: t; -*-

;;; Commentary:
;; No external packages are loaded until the mode is enabled.  This lets init
;; and General create shared maps before Elpaca activates God mode.

;;; Code:
(require 'cl-lib)

(autoload 'mo-modal-tutor "mo-modal-tutor"
  "Open a fresh buffer of hands-on modal editing lessons." t)

(defgroup mo-modal nil "Personal modal editing." :group 'editing)
(defcustom my/modal-backend 'mo-modal
  "Editing backend to activate at startup.  Restart after changing this."
  :type '(choice (const mo-modal) (const meow) (const evil) (const nil)))
(defcustom mo-modal-excluded-modes
  '(org-agenda-mode org-capture-mode git-commit-mode with-editor-mode
    comint-mode eshell-mode term-mode vterm-mode special-mode minibuffer-mode)
  "Major or minor modes in which modal editing should not start automatically."
  :type '(repeat symbol))

(defvar mo-modal-mode)
(defvar god-local-mode)
(defvar god-local-mode-map)
(defvar expand-region-fast-keys-enabled)
(declare-function god-local-mode "god-mode" (&optional arg))
(declare-function er/expand-region "expand-region" (arg))
(declare-function er/contract-region "expand-region" (arg))
(declare-function corfu-quit "corfu" ())

(defvar-local mo-modal-state 'write "Current state: write, command, or select.")
(defvar-local mo-modal--command-active nil)
(defvar-local mo-modal--select-active nil)
(defvar-local mo-modal--saved-cursor nil)
(defvar-local mo-modal--saved-transient-mark nil)
(defvar-local mo-modal--saved-god nil)
(defvar mo-modal-command-map (make-sparse-keymap))
(defvar mo-modal-select-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map mo-modal-command-map)
    map))
(defvar mo-modal-mode-map (make-sparse-keymap))
(defvar mo-modal--emulation-maps
  `((mo-modal--select-active . ,mo-modal-select-map)
    (mo-modal--command-active . ,mo-modal-command-map)))

(defun mo-modal-indicator ()
  "Return the state label for the current buffer."
  (when mo-modal-mode
    (pcase mo-modal-state
      ('write " WRITE ") ('command " CMD ") ('select " SELECT "))))

(defun mo-modal--update ()
  "Update keymap flags and cursor for the current state."
  (setq mo-modal--command-active
        (and mo-modal-mode god-local-mode (eq mo-modal-state 'command))
        mo-modal--select-active
        (and mo-modal-mode god-local-mode (eq mo-modal-state 'select)))
  (when mo-modal-mode
    (setq-local cursor-type (if (eq mo-modal-state 'write) 'bar 'box)))
  (force-mode-line-update))

(defun mo-modal--require-mode ()
  (unless mo-modal-mode (user-error "Enable mo-modal-mode in this buffer first")))

(defun mo-modal-enter-write ()
  "Enter Write at point, clearing the selection without editing it."
  (interactive)
  (mo-modal--require-mode)
  (setq mo-modal-state 'write)
  (deactivate-mark)
  (god-local-mode -1)
  (mo-modal--update))

(defun mo-modal-enter-command ()
  "Enter Command and clear the selection.  Repeated calls are harmless."
  (interactive)
  (mo-modal--require-mode)
  (setq mo-modal-state 'command)
  (deactivate-mark)
  (god-local-mode 1)
  (mo-modal--update))

(defun mo-modal-cancel ()
  "Dismiss completion first; otherwise enter Command and clear the region.
Search and other overriding UI maps retain their own cancellation bindings."
  (interactive)
  (if (and (bound-and-true-p corfu-mode)
           (bound-and-true-p completion-in-region-mode)
           (fboundp 'corfu-quit))
      (corfu-quit)
    (mo-modal-enter-command)))

(defun mo-modal-enter-select ()
  "Enter Select, preserving an active region or anchoring at point."
  (interactive)
  (mo-modal--require-mode)
  (unless (region-active-p) (push-mark (point) t t))
  (setq mo-modal-state 'select deactivate-mark nil)
  (activate-mark)
  (god-local-mode 1)
  (mo-modal--update))

(defun mo-modal--sync-region ()
  "Follow native mark activation only outside Write."
  (when (and mo-modal-mode (not (eq mo-modal-state 'write)))
    (setq mo-modal-state (if (region-active-p) 'select 'command))
    (mo-modal--update)))

(defun mo-modal-expand (count)
  "Expand the region COUNT times and enter Select."
  (interactive "p")
  (mo-modal--require-mode)
  (require 'expand-region)
  ;; Its temporary repeat map would steal modal digit arguments and resets.
  (let ((expand-region-fast-keys-enabled nil))
    (er/expand-region count))
  (setq this-command 'er/expand-region)
  (when (region-active-p) (mo-modal-enter-select)))

(defun mo-modal-contract (count)
  "Contract the region COUNT times."
  (interactive "p")
  (mo-modal--require-mode)
  (require 'expand-region)
  (let ((expand-region-fast-keys-enabled nil))
    (er/contract-region count))
  (setq this-command 'er/contract-region)
  (mo-modal--sync-region))

(defun mo-modal--bounds ()
  "Return nonempty selection bounds, or signal a user error."
  (mo-modal--require-mode)
  (unless (and (region-active-p) (/= (point) (mark)))
    (user-error "Select some text first"))
  (cons (region-beginning) (region-end)))

(defun mo-modal-copy ()
  "Copy the selection and return to Command."
  (interactive)
  (pcase-let ((`(,beg . ,end) (mo-modal--bounds)))
    (kill-ring-save beg end))
  (mo-modal-enter-command))

(defun mo-modal-cut ()
  "Cut the selection and return to Command."
  (interactive)
  (pcase-let ((`(,beg . ,end) (mo-modal--bounds)))
    ;; Delete successfully before touching the kill ring.  `kill-region' copies
    ;; protected text even when it cannot delete it, including text properties.
    (barf-if-buffer-read-only)
    (let ((text (filter-buffer-substring beg end)))
      (atomic-change-group
        (delete-region beg end)
        (kill-new text))))
  (mo-modal-enter-command))

(defun mo-modal-delete ()
  "Delete the selection without changing the kill ring; enter Command."
  (interactive)
  (pcase-let ((`(,beg . ,end) (mo-modal--bounds)))
    (barf-if-buffer-read-only)
    (atomic-change-group (delete-region beg end)))
  (mo-modal-enter-command))

(defun mo-modal-change ()
  "Cut the selection, then immediately enter Write."
  (interactive)
  (mo-modal-cut)
  (mo-modal-enter-write))

(defun mo-modal--transform (function)
  "Call FUNCTION with region bounds, preserving selection and orientation.
Edits are atomic.  On failure, restore point and mark as well as the text."
  (pcase-let* ((`(,beg . ,end) (mo-modal--bounds))
               (old-point (point)) (old-mark (mark))
               (forward (> old-point old-mark))
               (start (copy-marker beg)) (finish (copy-marker end t)))
    (barf-if-buffer-read-only)
    (unwind-protect
        (condition-case err
            (progn
              (atomic-change-group (funcall function beg end))
              (goto-char (if forward finish start))
              (set-mark (if forward start finish))
              (mo-modal-enter-select))
          (error
           (goto-char old-point)
           (set-mark old-mark)
           (mo-modal-enter-select)
           (signal (car err) (cdr err))))
      (set-marker start nil)
      (set-marker finish nil))))

(defun mo-modal-surround (open close)
  "Surround the selection with OPEN and CLOSE and keep it selected."
  (interactive (let ((open (read-string "Opening delimiter: ")))
                 (list open (read-string "Closing delimiter: " open))))
  (mo-modal--transform
   (lambda (beg end)
     (goto-char end) (insert close)
     (goto-char beg) (insert open))))

(defun mo-modal-indent-right (count)
  "Indent the selection COUNT tab widths to the right."
  (interactive "p")
  (mo-modal--transform
   (lambda (beg end) (indent-rigidly beg end (* count tab-width)))))

(defun mo-modal-indent-left (count)
  "Indent the selection COUNT tab widths to the left."
  (interactive "p")
  (mo-modal-indent-right (- count)))

(defun mo-modal--restore-local (symbol saved)
  "Restore SYMBOL from SAVED, a pair of localness and value."
  (if (car saved) (set (make-local-variable symbol) (cdr saved))
    (kill-local-variable symbol)))

(define-minor-mode mo-modal-mode
  "Edit with Write, God-powered Command, and Select states."
  :lighter nil :keymap mo-modal-mode-map
  (if mo-modal-mode
      (progn
        (require 'god-mode)
        (when (or (bound-and-true-p meow-mode) (bound-and-true-p evil-local-mode))
          (setq mo-modal-mode nil)
          (user-error "Disable the other modal backend first"))
        (unless mo-modal--saved-cursor
          (setq mo-modal--saved-cursor (cons (local-variable-p 'cursor-type) cursor-type)
                mo-modal--saved-transient-mark
                (cons (local-variable-p 'transient-mark-mode) transient-mark-mode)
                mo-modal--saved-god god-local-mode))
        (setq-local transient-mark-mode t)
        (add-to-list 'emulation-mode-map-alists 'mo-modal--emulation-maps)
        (add-hook 'activate-mark-hook #'mo-modal--sync-region nil t)
        (add-hook 'deactivate-mark-hook #'mo-modal--sync-region nil t)
        (add-hook 'god-mode-enabled-hook #'mo-modal--update nil t)
        (add-hook 'god-mode-disabled-hook #'mo-modal--update nil t)
        (add-hook 'change-major-mode-hook #'mo-modal--disable nil t)
        (mo-modal-enter-command))
    (remove-hook 'activate-mark-hook #'mo-modal--sync-region t)
    (remove-hook 'deactivate-mark-hook #'mo-modal--sync-region t)
    (remove-hook 'god-mode-enabled-hook #'mo-modal--update t)
    (remove-hook 'god-mode-disabled-hook #'mo-modal--update t)
    (remove-hook 'change-major-mode-hook #'mo-modal--disable t)
    (setq mo-modal-state 'write
          mo-modal--command-active nil mo-modal--select-active nil)
    (when mo-modal--saved-cursor
      (god-local-mode (if mo-modal--saved-god 1 -1))
      (mo-modal--restore-local 'cursor-type mo-modal--saved-cursor)
      (mo-modal--restore-local 'transient-mark-mode mo-modal--saved-transient-mark)
      (setq mo-modal--saved-cursor nil mo-modal--saved-transient-mark nil))
    (force-mode-line-update)))

(defun mo-modal--disable ()
  (when mo-modal-mode (mo-modal-mode -1)))

(defun mo-modal--eligible-p ()
  "Whether this buffer should automatically use modal editing."
  (and (not (minibufferp))
       (derived-mode-p 'text-mode 'prog-mode)
       (not (cl-some (lambda (mode)
                       (or (derived-mode-p mode)
                           (and (boundp mode) (symbol-value mode))))
                     mo-modal-excluded-modes))))

(defun mo-modal--maybe-enable ()
  (when (mo-modal--eligible-p) (mo-modal-mode 1)))

(define-globalized-minor-mode mo-modal-global-mode
  mo-modal-mode mo-modal--maybe-enable)

(provide 'mo-modal)
;;; mo-modal.el ends here
