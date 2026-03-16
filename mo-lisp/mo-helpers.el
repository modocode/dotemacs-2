;;; mo-lisp/mo-helpers.el --- Interactive utility functions -*- lexical-binding: t; -*-
;;
;; A library of interactive helpers that are useful across all language modes.
;; Loaded explicitly and early in init.el so they're available everywhere.
;;
;; These are INTERACTIVE commands (callable with M-x), unlike the utility
;; macros in core-lib.el which are building blocks for other config code.

(require 'cl-lib)  ; for cl-some, cl-remove-if

;;; ── Project Root Detection ──────────────────────────────────────────────────

(defvar my/project-root-markers
  '(".git" "pyproject.toml" "CMakeLists.txt" "build.zig" ".project")
  "Files/directories whose presence marks a project root.
`my/find-project-root' walks up the directory tree looking for these.")

(defun my/find-project-root ()
  "Return the nearest project root directory above the current buffer.

Walks up the directory tree from `default-directory', returning the first
ancestor that contains any file in `my/project-root-markers'.

Uses `locate-dominating-file', which is Emacs's built-in upward directory
search. Returns the directory as a string, or nil if no root is found.

You can use this in hooks to auto-configure things per-project:
  (when-let* ((root (my/find-project-root)))
    (setq compile-command (concat \"cd \" root \" && make\")))"
  (cl-some (lambda (marker)
             (locate-dominating-file default-directory marker))
           my/project-root-markers))

;;; ── Config Management ───────────────────────────────────────────────────────

(defun my/open-init ()
  "Open init.el in the other window.
Useful for quickly checking or tweaking startup config without losing
your current buffer position."
  (interactive)
  (find-file-other-window (expand-file-name "init.el" user-emacs-directory)))

(defun my/reload-init ()
  "Reload init.el without restarting Emacs.

Note: this re-evaluates the file top-to-bottom. `defvar' forms will NOT
reset variables that are already bound (that's intentional — it means your
customisations survive a reload). Use `(makunbound 'var)' first if you
need to reset a specific variable."
  (interactive)
  ;; `my/emacs-dir' is defined in init.el and is always the true config directory.
  (load-file (expand-file-name "init.el" my/emacs-dir))
  (message "init.el reloaded."))

;;; ── LSP / Eglot ─────────────────────────────────────────────────────────────

(defun my/toggle-eglot ()
  "Start Eglot in the current buffer if it's off; shut it down if it's running.
Displays a message confirming the new state.

This gives you per-buffer LSP control without touching `my/use-eglot',
which is the startup-time global toggle."
  (interactive)
  (if (and (fboundp 'eglot-current-server) (eglot-current-server))
      (progn
        (eglot-shutdown (eglot-current-server))
        (message "Eglot stopped in %s." (buffer-name)))
    (call-interactively #'eglot)
    (message "Eglot started in %s." (buffer-name))))

;;; ── Language-Aware Debug Printing ──────────────────────────────────────────

(defun my/insert-debug-print ()
  "Insert a debug print statement for the symbol at point.

The statement is inserted on a new line below the current line, indented
correctly. Language-aware: adapts the syntax to the current major mode.

  Python  → print(f\"{var = }\")           (uses f-string self-documenting form)
  C/C++   → printf(\"var = %d\\n\", var);   (generic int format — adjust as needed)
  Zig     → std.debug.print(\"var = {any}\\n\", .{var});

If no symbol is under point, falls back to the placeholder name DEBUG."
  (interactive)
  (let* ((var (or (thing-at-point 'symbol t) "DEBUG"))
         (statement
          (pcase major-mode
            ((or 'python-mode 'python-ts-mode)
             (format "print(f\"{%s = }\")" var))
            ((or 'c-mode 'c++-mode 'c-ts-mode 'c++-ts-mode)
             (format "printf(\"%s = %%d\\n\", %s);" var var))
            ('zig-mode
             (format "std.debug.print(\"{s} = {{any}}\\n\", .{{ \"{s}\", {s} }});"
                     var var var))
            (_ nil))))
    (if statement
        (progn
          (end-of-line)
          (newline-and-indent)
          (insert statement))
      (message "[my/insert-debug-print] No print template for %s." major-mode))))

;;; ── Buffer / File Operations ────────────────────────────────────────────────

(defun my/copy-buffer-path ()
  "Copy the absolute path of the current buffer's file to the kill ring.
Also displays the path in the minibuffer so you can see what was copied.
Works on both file-visiting buffers and `dired' buffers."
  (interactive)
  (let ((path (or (buffer-file-name)
                  (and (eq major-mode 'dired-mode) default-directory))))
    (if path
        (progn
          (kill-new path)
          (message "Copied: %s" path))
      (message "[my/copy-buffer-path] Buffer has no associated file."))))

(defun my/rename-file-and-buffer ()
  "Rename the file the current buffer visits, then update the buffer name.

Prompts for the new filename (defaulting to the current filename so you
can do minor edits). Saves the buffer first to ensure the disk file is
up-to-date before renaming."
  (interactive)
  (let* ((old-path (buffer-file-name)))
    (unless old-path
      (user-error "Buffer '%s' is not visiting a file" (buffer-name)))
    (let* ((old-dir  (file-name-directory old-path))
           (old-name (file-name-nondirectory old-path))
           (new-path (read-file-name "Rename to: " old-dir nil nil old-name)))
      (when (string= old-path (expand-file-name new-path))
        (user-error "New name is the same as the old name"))
      (rename-file old-path new-path 1)          ; 1 = ask before overwriting
      (set-visited-file-name new-path t t)        ; rename buffer, update modeline
      (message "Renamed to %s" new-path))))

(defun my/kill-other-buffers ()
  "Kill every buffer except the current one and *scratch*.

Useful for clearing clutter after a long session. Prompts for confirmation
before proceeding since this affects ALL other open buffers."
  (interactive)
  (when (yes-or-no-p "Kill all other buffers? ")
    (let* ((keep (list (current-buffer)))
           (scratch (get-buffer "*scratch*"))
           (victims (cl-remove-if
                     (lambda (b) (or (memq b keep)
                                     (eq b scratch)))
                     (buffer-list))))
      (mapc #'kill-buffer victims)
      (message "Killed %d buffer(s)." (length victims)))))

(provide 'mo-helpers)
;;; mo-helpers.el ends here
