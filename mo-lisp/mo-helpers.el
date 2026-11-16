;;; mo-lisp/mo-helpers.el --- Interactive utility functions -*- lexical-binding: t; -*-
;;
;; A library of interactive helpers that are useful across all language modes.
;; Loaded explicitly and early in init.el so they're available everywhere.
;;
;; These are INTERACTIVE commands (callable with M-x), unlike the utility
;; macros in core-lib.el which are building blocks for other config code.

(require 'cl-lib)  ; for cl-some, cl-remove-if
(require 'core-lib)
(require 'mo-paths)

;;; my custom helpers that i wrote

(defvar my/keyboard-layout "colemak"
  "This represents the keyboard layout i am using on my system"
  )

(defvar my/enable-qwerty nil)



(defun my-process--my-keyboard-layout ()
  (if (and (not (eq my/keyboard-layout "QWERTY")) (eq my/enable-qwerty nil))
      (setq my/enable-qwerty t)))






;;; ── Fonts and Scratch Buffers ──────────────────────────────────────────────

(defun my/choose-font ()
  "Choose a font role, installed family, and point size, then preview it.
Accepting updates `my/fonts' and applies that role.  Declining or quitting
restores the previous font.  Changes are session-only; use
`my/register-font' in your OS config to persist them."
  (interactive)
  (unless (display-graphic-p)
    (user-error "Choose fonts in a graphical frame; terminals manage their own fonts"))
  (let* ((role (intern (completing-read "Font role: "
                                      '("default" "fixed" "variable")
                                      nil t nil nil "default")))
         (face (pcase role ('fixed 'fixed-pitch)
                      ('variable 'variable-pitch) (_ 'default)))
         (family (completing-read "Font family: "
                                  (sort (delete-dups (font-family-list)) #'string-lessp)
                                  nil t nil nil (face-attribute face :family nil t)))
         (size (read-number "Size in points: " (/ (my/font-height role) 10.0)))
         (frame (selected-frame))
         (old-font (face-attribute face :font frame))
         (old-height (face-attribute face :height frame))
         accepted)
    (unless (> size 0)
      (user-error "Font size must be positive"))
    (unwind-protect
        (progn
          (set-face-attribute face frame :family family :height (max 1 (round (* size 10))))
          (redisplay t)
          (setq accepted (yes-or-no-p (format "Keep %s at %g pt for %s? " family size role))))
      (when (frame-live-p frame)
        (set-face-attribute face frame :font old-font :height old-height)))
    (when accepted
      (my/register-font role family (max 1 (round (* size 10))))
      (my/apply-font role)
      (message "Selected %s at %g pt for %s (this session)" family size role))))

(defun my/show-font ()
  "Display active face fonts and, when available, the font at point.
Read the actual frame faces rather than the configured `my/fonts' registry.
The font at point can differ because of buffer styling or glyph fallback."
  (interactive)
  (if (not (display-graphic-p))
      (message "Terminal fonts are controlled by your terminal emulator")
    (let ((font (and (< (point) (point-max)) (font-at (point)))))
      (message "%s%s"
               (mapconcat
                (lambda (face)
                  (format "%s: %s (%g pt)" face
                          (face-attribute face :family nil t)
                          (/ (face-attribute face :height nil t) 10.0)))
                '(default fixed-pitch variable-pitch) "; ")
               (if font (format "; at point: %s" (font-get font :family)) "")))))

(defun my/scratch-buffer ()
  "Create a new scratch buffer using the current major mode and directory.
Special or read-only buffers use `fundamental-mode' for an editable scratch.
Each invocation creates a separate buffer without altering `*scratch*'."
  (interactive)
  (let* ((mode (if (or buffer-read-only (derived-mode-p 'special-mode)
                       (eq (get major-mode 'mode-class) 'special))
                   'fundamental-mode
                 major-mode))
         (directory default-directory)
         (buffer (generate-new-buffer (format "*scratch:%s*" mode))))
    (with-current-buffer buffer
      (setq default-directory directory)
      (funcall mode)
      (setq default-directory directory)
      (setq buffer-read-only nil))
    (pop-to-buffer buffer)
    buffer))

;;; ── Project Root Detection ──────────────────────────────────────────────────

(defvar my/project-root-markers
  '(".git" "pyproject.toml" "CMakeLists.txt" "build.zig" ".project"
    "flake.nix" "shell.nix" ".envrc")
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

;;; ---------------------------------------------------------------------------
;;; Course creation
;;; ---------------------------------------------------------------------------

(defun my/org-slugify (string)
  "Convert STRING into a filesystem-friendly lowercase slug."
  (let ((slug (downcase (string-trim string))))
    (setq slug (replace-regexp-in-string "[^a-z0-9]+" "-" slug))
    (setq slug (replace-regexp-in-string "^-+" "" slug))
    (setq slug (replace-regexp-in-string "-+$" "" slug))
    slug))

(defun my/org-new-course ()
  "Create and open a new course file using the universal course template.

The course is created in `org/courses/' and automatically becomes part
of the Org agenda because course files are discovered recursively."
  (interactive)

  (let* ((courses-dir (my/org-file "courses"))
         (name        (read-string "Course name: "))
         (code        (read-string "Course code: "))
         (instructor  (read-string "Instructor: "))
         (term        (read-string "Term: "
                                   "Fall 2026"))
         (credits     (read-string "Credits: "))
         (location    (read-string "Location: "))
         (schedule    (read-string "Meeting schedule: "))
         (slug        (my/org-slugify
                       (if (string-empty-p code)
                           name
                         code)))
         (file        (expand-file-name
                       (concat slug ".org")
                       courses-dir)))

    ;; Make sure the courses directory exists.
    (make-directory courses-dir t)

    ;; Never silently overwrite an existing course.
    (when (file-exists-p file)
      (user-error "Course already exists: %s" file))

    (with-temp-file file
      (insert "#+title: " name "\n")
      (insert "#+subtitle: " code "\n")
      (insert "#+category: " code "\n")
      (insert "#+filetags: :" (my/org-slugify code) ":\n")
      (insert "\n")

      ;; ---------------------------------------------------------------------
      ;; Course information
      ;; ---------------------------------------------------------------------

      (insert "* Course Information\n")
      (insert ":PROPERTIES:\n")
      (insert ":COURSE-CODE: " code "\n")
      (insert ":INSTRUCTOR: " instructor "\n")
      (insert ":TERM: " term "\n")
      (insert ":CREDITS: " credits "\n")
      (insert ":LOCATION: " location "\n")
      (insert ":SCHEDULE: " schedule "\n")
      (insert ":END:\n\n")

      ;; ---------------------------------------------------------------------
      ;; Course overview
      ;; ---------------------------------------------------------------------

      (insert "* Overview\n\n")
      (insert "** Description\n\n")
      (insert "** Learning Objectives\n")
      (insert "- [ ] \n")
      (insert "- [ ] \n")
      (insert "- [ ] \n\n")

      (insert "** Important Topics\n")
      (insert "- \n")
      (insert "- \n")
      (insert "- \n\n")

      ;; ---------------------------------------------------------------------
      ;; Schedule
      ;; ---------------------------------------------------------------------

      (insert "* Schedule\n\n")
      (insert "| Date | Topic | Reading | Assignment | Notes |\n")
      (insert "|------+-------+---------+------------+-------|\n")
      (insert "|      |       |         |            |       |\n\n")

      ;; ---------------------------------------------------------------------
      ;; Assignments
      ;; ---------------------------------------------------------------------

      (insert "* Assignments\n\n")
      (insert "** Upcoming\n\n")
      (insert "** Completed\n\n")

      ;; ---------------------------------------------------------------------
      ;; Labs
      ;; ---------------------------------------------------------------------

      (insert "* Labs\n\n")
      (insert "** Upcoming\n\n")
      (insert "** Completed\n\n")

      ;; ---------------------------------------------------------------------
      ;; Exams
      ;; ---------------------------------------------------------------------

      (insert "* Exams\n\n")
      (insert "** Upcoming\n\n")
      (insert "** Completed\n\n")

      ;; ---------------------------------------------------------------------
      ;; Lecture notes
      ;; ---------------------------------------------------------------------

      (insert "* Lecture Notes\n\n")
      (insert "** Topics\n\n")

      ;; ---------------------------------------------------------------------
      ;; Questions
      ;; ---------------------------------------------------------------------

      (insert "* Questions\n\n")
      (insert "** Open Questions\n\n")
      (insert "** Resolved Questions\n\n")

      ;; ---------------------------------------------------------------------
      ;; Review
      ;; ---------------------------------------------------------------------

      (insert "* Review Queue\n\n")
      (insert "** Weak Concepts\n\n")
      (insert "** Formulas / Procedures\n\n")
      (insert "** Problems to Revisit\n\n")

      ;; ---------------------------------------------------------------------
      ;; Problem-solving / practice
      ;; ---------------------------------------------------------------------

      (insert "* Practice\n\n")
      (insert "** Problem Sets\n\n")
      (insert "** Important Problems\n\n")
      (insert "** Mistakes / Error Log\n\n")

      ;; ---------------------------------------------------------------------
      ;; Projects
      ;; ---------------------------------------------------------------------

      (insert "* Projects\n\n")

      ;; ---------------------------------------------------------------------
      ;; Resources
      ;; ---------------------------------------------------------------------

      (insert "* Resources\n\n")
      (insert "** Textbook\n\n")
      (insert "** Professor Resources\n\n")
      (insert "** Online Resources\n\n")
      (insert "** Reference Material\n\n")

      ;; ---------------------------------------------------------------------
      ;; Formula sheet
      ;; ---------------------------------------------------------------------

      (insert "* Formula Sheet\n\n")
      (insert "#+begin_src latex\n")
      (insert "% Important equations for " code "\n")
      (insert "#+end_src\n\n")

      ;; ---------------------------------------------------------------------
      ;; Grade tracker
      ;; ---------------------------------------------------------------------

      (insert "* Grade Tracker\n\n")
      (insert "| Assessment | Weight | Score | Notes |\n")
      (insert "|------------+--------+-------+-------|\n")
      (insert "|            |        |       |       |\n")
      (insert "|------------+--------+-------+-------|\n")
      (insert "| Total      | 100%   |       |       |\n\n")

      ;; ---------------------------------------------------------------------
      ;; Semester review
      ;; ---------------------------------------------------------------------

      (insert "* Semester Review\n\n")
      (insert "** What I Learned\n\n")
      (insert "** What I Struggled With\n\n")
      (insert "** Important Concepts to Retain\n\n")
      (insert "** Final Resources\n\n"))

    ;; Open the new course.
    (find-file file)

    ;; Refresh the agenda and refile system so the new course is immediately
    ;; recognized.
    (when (fboundp 'my/org-refresh-agenda-files)
      (my/org-refresh-agenda-files))

    (when (fboundp 'my/org-refresh-refile-targets)
      (my/org-refresh-refile-targets))

    (message "Created course: %s (%s)" name code)))




(provide 'mo-helpers)
;;; mo-helpers.el ends here
