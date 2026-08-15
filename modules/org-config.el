;;; modules/org.el --- Universal Org-mode life system -*- lexical-binding: t; -*-
;;
;; Universal Org architecture:
;;
;;   org/
;;   ├── inbox.org
;;   ├── agenda.org
;;   ├── projects.org
;;   ├── someday.org
;;   ├── reference.org
;;   ├── journal.org
;;   ├── areas/
;;   │   ├── education.org
;;   │   ├── finance.org
;;   │   ├── career.org
;;   │   ├── health.org
;;   │   ├── personal.org
;;   │   ├── relationships.org
;;   │   └── home.org
;;   ├── courses/
;;   │   ├── circuits.org
;;   │   ├── digital-systems.org
;;   │   ├── physics.org
;;   │   └── chemistry.org
;;   └── archive/
;;
;; Machine-specific paths are resolved through the mo-paths registry.
;; Example:
;;   (my/register-path 'org-dir   "~/org/")
;;   (my/register-path 'notes-dir "~/notes/")
;;
;; Philosophy:
;;
;;   Areas      = ongoing responsibilities.
;;   Projects   = finite outcomes requiring multiple actions.
;;   Actions    = things that can actually be done.
;;   Reference  = information with no action attached.
;;   Someday    = deliberately inactive possibilities.
;;   Agenda     = time-sensitive and recurring commitments.
;;   Journal    = historical record.
;;   Denote     = durable knowledge / permanent notes.
;;
;; Workflow:
;;
;;   capture -> inbox -> clarify -> refile -> agenda -> execute -> review -> archive
;;

;;; ---------------------------------------------------------------------------
;;; Paths
;;; ---------------------------------------------------------------------------

(defun my/org-file (name)
  "Return the full path to NAME within the registered org-dir.
Falls back through `my/path' according to the rest of this configuration."
  (expand-file-name name (my/path 'org-dir)))

(defun my/org-files-recursively (directory)
  "Return all .org files recursively beneath DIRECTORY."
  (when (file-directory-p directory)
    (directory-files-recursively directory "\\.org\\'")))

(defun my/org-active-files ()
  "Return files that should participate in the active Org agenda."
  (delete-dups
   (append
    (mapcar #'my/org-file
            '("inbox.org"
              "agenda.org"
              "projects.org"))
    (my/org-files-recursively (my/org-file "areas"))
    (my/org-files-recursively (my/org-file "courses")))))

(defun my/org-refile-files ()
  "Return every file that may receive an Org refile."
  (delete-dups
   (append
    (mapcar #'my/org-file
            '("projects.org"
              "someday.org"
              "reference.org"
              "agenda.org"))
    (my/org-files-recursively (my/org-file "areas"))
    (my/org-files-recursively (my/org-file "courses")))))

(defun my/org-refresh-agenda-files ()
  "Rebuild `org-agenda-files' from the universal Org system."
  (interactive)
  (setq org-agenda-files (my/org-active-files))
  (message "Org agenda files refreshed (%d files)." (length org-agenda-files)))

(defun my/org-refresh-refile-targets ()
  "Rebuild `org-refile-targets' from active Org destinations."
  (interactive)
  (setq org-refile-targets
        (mapcar (lambda (file)
                  (cons file '(:maxlevel . 4)))
                (my/org-refile-files)))
  (when (fboundp 'org-refile-cache-clear)
    (org-refile-cache-clear))
  (message "Org refile targets refreshed."))

(defun my/org-create-system-directories ()
  "Create the standard Org directories if they do not already exist."
  (interactive)
  (dolist (directory
           (list (my/org-file "areas")
                 (my/org-file "courses")
                 (my/org-file "archive")))
    (make-directory directory t))
  (message "Org system directories are ready."))

;;; ---------------------------------------------------------------------------
;;; Core Org
;;; ---------------------------------------------------------------------------

(use-package org
  :ensure nil
  :init

  (setq org-directory (my/path 'org-dir))

  :config

  ;; Create the directory skeleton, but never overwrite files.
  (my/org-create-system-directories)

  ;; Resolve dynamic file sets only after the machine-specific path registry
  ;; has been initialized.
  (add-hook 'emacs-startup-hook #'my/org-refresh-agenda-files)
  (add-hook 'emacs-startup-hook #'my/org-refresh-refile-targets)

  ;; Editing behavior.
  (setq org-M-RET-may-split-line '((default . nil))
        org-insert-heading-respect-content t
        org-log-into-drawer t
        org-log-done 'time
        org-log-reschedule 'time
        org-log-redeadline 'time
        org-use-fast-todo-selection t
        org-enforce-todo-dependencies t
        org-enforce-todo-checkbox-dependencies t)

  ;; Agenda semantics.
  (setq org-agenda-span 7
        org-agenda-start-on-weekday nil
        org-deadline-warning-days 14
        org-agenda-skip-deadline-if-done t
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-timestamp-if-done t)

  ;; Persistent IDs make links survive refiles and file moves.
  (setq org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)

  ;; Appearance / editing.
  (setq org-adapt-indentation t
        org-hide-leading-stars t
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-ellipsis " ▼ "
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 0
        org-highlight-latex-and-related '(native script entities))

  ;; Standard effort estimates.
  (setq org-global-properties
        '(("Effort_ALL" .
           "0:05 0:10 0:15 0:25 0:30 0:45 1:00 1:30 2:00 3:00 4:00")))

  ;; Clocking.
  (setq org-clock-into-drawer t
        org-clock-out-remove-zero-time-clocks t
        org-clock-persist t
        org-clock-history-length 30
        org-clock-in-resume t
        org-clock-report-include-clocking-task t)

  (org-clock-persistence-insinuate)

  ;; Habits.
  (require 'org-habit)
  (add-to-list 'org-modules 'org-habit)
  (setq org-habit-graph-column 50
        org-habit-preceding-days 21
        org-habit-following-days 7)

  ;; Refile behavior.
  (setq org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm
        org-refile-use-cache t)

  ;; Archive each source file into org/archive/.
  ;;
  ;; Example:
  ;;   courses/circuits.org
  ;;       -> archive/circuits.org_archive
  ;;
  ;; `%s' expands to the source filename.
  (setq org-archive-location
        (concat
         (file-name-as-directory (my/org-file "archive"))
         "%s_archive::"))

  ;; Babel.
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python     . t)
     (C          . t)
     (shell      . t)
     (octave     . t))))

;;; ---------------------------------------------------------------------------
;;; TODO workflows
;;; ---------------------------------------------------------------------------

(setq org-todo-keywords
      '((sequence
         "TODO(t)"
         "NEXT(n)"
         "WAIT(w@/!)"
         "HOLD(h@/!)"
         "|"
         "DONE(d!)"
         "CANCELLED(c@/!)")

        (sequence
         "QUESTION(q)"
         "|"
         "ANSWERED(a!)")

        (sequence
         "REVIEW(r)"
         "|"
         "REVIEWED(R!)")))

(setq org-todo-keyword-faces
      '(("TODO"      . (:foreground "orange"  :weight bold))
        ("NEXT"      . (:foreground "cyan"    :weight bold))
        ("WAIT"      . (:foreground "yellow"  :weight bold))
        ("HOLD"      . (:foreground "gray"    :weight bold))
        ("QUESTION"  . (:foreground "magenta" :weight bold))
        ("ANSWERED"  . (:foreground "green"   :weight bold))
        ("REVIEW"    . (:foreground "magenta" :weight bold))
        ("REVIEWED"  . (:foreground "green"   :weight bold))
        ("DONE"      . (:foreground "green"   :weight bold))
        ("CANCELLED" . (:foreground "gray"    :weight bold))))

;;; ---------------------------------------------------------------------------
;;; Tags
;;; ---------------------------------------------------------------------------

;; Tags describe context/type.  The file/category describes the domain.
;;
;; Examples:
;;   circuits.org      => Circuits
;;   finance.org       => Finance
;;
;; Tags answer orthogonal questions such as:
;;   Where can this be done?
;;   What sort of attention does it require?

(setq org-tag-alist
      '((:startgroup)
        ("@home"     . ?h)
        ("@campus"   . ?c)
        ("@computer" . ?o)
        ("@lab"      . ?l)
        ("@errand"   . ?e)
        ("@phone"    . ?p)
        (:endgroup)

        ("deep"       . ?d)
        ("quick"      . ?q)
        ("reading"    . ?r)
        ("exam"       . ?x)
        ("assignment" . ?a)
        ("project"    . ?j)
        ("meeting"    . ?m)
        ("routine"    . ?u)))

;;; ---------------------------------------------------------------------------
;;; Capture
;;; ---------------------------------------------------------------------------

;; Capture is intentionally context-light.
;; Most items enter inbox.org and are classified during inbox processing.

(setq org-capture-templates
      `(
        ;; Actions -------------------------------------------------------------

        ("t" "Task"
         entry
         (file ,(my/org-file "inbox.org"))
         "* TODO %^{Task}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
         :empty-lines 1)

        ("n" "Next Action"
         entry
         (file ,(my/org-file "inbox.org"))
         "* NEXT %^{Action}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
         :empty-lines 1)

        ;; Education accelerators ---------------------------------------------

        ("a" "Assignment"
         entry
         (file ,(my/org-file "inbox.org"))
         "* TODO %^{Assignment} :assignment:\nDEADLINE: %^t\n:PROPERTIES:\n:COURSE: %^{Course}\n:CREATED: %U\n:Effort: %^{Estimated effort|1:00}\n:END:\n%?"
         :empty-lines 1)

        ("x" "Exam"
         entry
         (file ,(my/org-file "inbox.org"))
         "* TODO %^{Exam} :exam:\nDEADLINE: %^t\n:PROPERTIES:\n:COURSE: %^{Course}\n:CREATED: %U\n:END:\n%?"
         :empty-lines 1)

        ;; Learning / knowledge gaps ------------------------------------------

        ("q" "Question"
         entry
         (file ,(my/org-file "inbox.org"))
         "* QUESTION %^{Question}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
         :empty-lines 1)

        ("r" "Review / Weakness"
         entry
         (file ,(my/org-file "inbox.org"))
         "* REVIEW %^{Topic}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
         :empty-lines 1)

        ("l" "Reading / Link"
         entry
         (file ,(my/org-file "inbox.org"))
         "* TODO Read: %:description :reading:\n:PROPERTIES:\n:CREATED: %U\n:END:\n%a\n%?"
         :empty-lines 1)

        ;; Events --------------------------------------------------------------

        ("e" "Event"
         entry
         (file ,(my/org-file "inbox.org"))
         "* %^{Event}\n%^T\n%?"
         :empty-lines 1)

        ;; Reference -----------------------------------------------------------

        ("i" "Information"
         entry
         (file ,(my/org-file "reference.org"))
         "* %^{Title}\n:PROPERTIES:\n:CAPTURED: %U\n:SOURCE: %^{Source|Manual}\n:END:\n%?"
         :empty-lines 1)

        ;; Journal -------------------------------------------------------------

        ("j" "Journal"
         entry
         (file+olp+datetree ,(my/org-file "journal.org"))
         "* %<%H:%M> %^{Title}\n%?"
         :tree-type week)

        ;; Someday -------------------------------------------------------------

        ("s" "Someday"
         entry
         (file ,(my/org-file "someday.org"))
         "* %^{Idea}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
         :empty-lines 1)

        ;; Projects ------------------------------------------------------------

        ("p" "Projects")

        ("pp" "Normal Project"
         entry
         (file+headline ,(my/org-file "projects.org") "Active")
         "* TODO %^{Outcome} :project:\n:PROPERTIES:\n:CREATED: %U\n:AREA: %^{Area}\n:END:\n\n** NEXT %?"
         :empty-lines 1)

        ;; Your systems-engineering / portfolio-oriented project template.
        ("pe" "Engineering Project"
         entry
         (file+headline ,(my/org-file "projects.org") "Engineering")
         "* TODO %^{Project Name} :project:SYSTEMS_ENG:\n:PROPERTIES:\n:ID: %(org-id-new)\n:CREATED: %U\n:STATUS: INITIATING\n:CATEGORY: %^{Category|Lab|Invention|Personal|Software|Hardware|Research}\n:END:\n\n** 1. CONOPS (Concept of Operations)\n- *Primary Intent:* %^{What is the singular purpose of this creation?}\n- *Operating Environment:* %^{Where/when will this exist?}\n- *Primary Constraint:* %^{What is the main bottleneck or constraint?}\n\n** 2. ARCHITECTURAL DECOMPOSITION\n- [ ] [MODULE-A]: %^{Physical or logic layer 1}\n- [ ] [MODULE-B]: %^{Physical or logic layer 2}\n- [ ] [INTERFACE]: %^{How do these modules exchange energy/data/force?}\n\n** 3. PERFORMANCE REQUIREMENTS\n| Parameter              | Target/Baseline | Actual Result | Status |\n|------------------------+-----------------+---------------+--------|\n| Metric 1 (Primary)     | %^{Target}      |               | PEND   |\n| Metric 2 (Constraint)  |                 |               | PEND   |\n| Metric 3 (Efficiency)  |                 |               | PEND   |\n\n** 4. EXECUTION / ENGINEERING LOG\n%?\n\n** 5. VERIFICATION & VALIDATION\n- [ ] *Verification:* Did the implementation match the specification?\n- [ ] *Validation:* Does the resulting system solve the intended problem?\n- [ ] *Next Iteration:* What would materially improve the next version?\n\n** 6. KNOWLEDGE EXTRACTION / PORTFOLIO\n- *Challenge:* %^{The core problem faced}\n- *Action:* %^{What was implemented and how?}\n- *Result:* %^{Quantifiable outcome}\n"
         :empty-lines 1)))

;;; ---------------------------------------------------------------------------
;;; Refile helpers
;;; ---------------------------------------------------------------------------

(defun my/org-refile-reset-cache ()
  "Clear the Org refile target cache."
  (interactive)
  (org-refile-cache-clear)
  (message "Org refile cache cleared."))

(defun my/org-refile-to-heading (file heading)
  "Refile the entry at point to HEADING in FILE without prompts."
  (let* ((buf (find-file-noselect file))
         (pos
          (with-current-buffer buf
            (save-excursion
              (goto-char (point-min))
              (when (re-search-forward
                     (format "^\\*+ %s" (regexp-quote heading))
                     nil t)
                (match-beginning 0))))))
    (if pos
        (org-refile nil nil (list heading file nil pos))
      (user-error "Heading %S not found in %s"
                  heading
                  (file-name-nondirectory file)))))

(defun my/org-refile-to-someday ()
  "Refile the current heading into someday.org."
  (interactive)
  (org-refile nil nil
              (list nil
                    (my/org-file "someday.org")
                    nil
                    (with-current-buffer
                        (find-file-noselect (my/org-file "someday.org"))
                      (point-min)))))

(defun my/org-refile-to-inbox ()
  "Refile the current heading into inbox.org."
  (interactive)
  (org-refile nil nil
              (list nil
                    (my/org-file "inbox.org")
                    nil
                    (with-current-buffer
                        (find-file-noselect (my/org-file "inbox.org"))
                      (point-min)))))

(defun my/org-process-inbox ()
  "Open the universal Org inbox for clarification and refiling."
  (interactive)
  (find-file (my/org-file "inbox.org"))
  (widen)
  (goto-char (point-min))
  (org-overview)
  (message
   "Inbox: clarify -> state -> effort -> deadline/schedule if needed -> refile"))

(defun my/org-archive-done-items ()
  "Archive all completed/cancelled subtrees beneath the heading at point."
  (interactive)
  (save-excursion
    (org-map-entries
     (lambda ()
       (org-archive-subtree)
       (setq org-map-continue-from (outline-previous-heading)))
     "/DONE|/CANCELLED|/ANSWERED|/REVIEWED"
     'tree)))

;;; ---------------------------------------------------------------------------
;;; Structure templates
;;; ---------------------------------------------------------------------------

(with-eval-after-load 'org
  (dolist (template
           '(("el"    . "src emacs-lisp")
             ("py"    . "src python")
             ("c"     . "src C")
	     ("nix"   . "src nix")
             ("cpp"   . "src C++")
             ("sh"    . "src shell")
             ("oct"   . "src octave")
             ("latex" . "src latex")
             ("rs"    . "src rust")
             ("spice" . "src spice")))
    (add-to-list 'org-structure-template-alist template)))

;;; ---------------------------------------------------------------------------
;;; Org Modern
;;; ---------------------------------------------------------------------------

(use-package org-modern
  :ensure t
  :demand t
  :custom
  (org-auto-align-tags t)
  (org-tags-column 0)
  (org-fold-catch-invisible-edits 'show-and-error)
  (org-special-ctrl-a/e t)
  (org-insert-heading-respect-content t)
  ;; org-superstar handles these.
  (org-modern-tag nil)
  (org-modern-priority nil)
  (org-modern-todo nil)
  :config
  (global-org-modern-mode))

;;; ---------------------------------------------------------------------------
;;; Org Superstar
;;; ---------------------------------------------------------------------------

(use-package org-superstar
  :ensure t
  :hook (org-mode . org-superstar-mode)
  :config

  (setq org-superstar-item-bullet-alist
        '((?* . ?•)
          (?+ . ?➤)
          (?- . ?•)))

  (setq org-superstar-headline-bullets-list
        '("◉" "◈" "○" "▷"))

  (setq org-superstar-special-todo-items t
        org-superstar-remove-leading-stars t
        org-hide-leading-stars t)

  (setq org-superstar-todo-bullet-alist
        '(("TODO"      . ?☐)
          ("NEXT"      . ?▶)
          ("WAIT"      . ?◌)
          ("HOLD"      . ?Ⅱ)
          ("QUESTION"  . ??)
          ("ANSWERED"  . ?✓)
          ("REVIEW"    . ?↻)
          ("REVIEWED"  . ?✓)
          ("DONE"      . ?✔)
          ("CANCELLED" . ?✘))))

;;; ---------------------------------------------------------------------------
;;; Org Super Agenda
;;; ---------------------------------------------------------------------------

(use-package org-super-agenda
  :ensure t
  :demand t
  :config
  (org-super-agenda-mode 1))

(setq org-super-agenda-groups
      '((:name "🔥 Overdue"
               :deadline past)

        (:name "⚡ Due Today"
               :deadline today)

        (:name "🚨 Priority"
               :priority "A")

        (:name "▶ Next Actions"
               :todo "NEXT")

        (:name "⏳ Waiting"
               :todo "WAIT")

        (:name "❓ Open Questions"
               :todo "QUESTION")

        (:name "↻ Review"
               :todo "REVIEW")

        (:auto-category t)))

;;; ---------------------------------------------------------------------------
;;; Universal Agenda
;;; ---------------------------------------------------------------------------

(setq org-agenda-custom-commands
      '(

        ;; Daily command center ------------------------------------------------

        ("d" "Dashboard"

         ((agenda ""
                  ((org-agenda-span 1)
                   (org-agenda-overriding-header "📅 Calendar")))

          (todo "NEXT"
                ((org-agenda-overriding-header "▶ Next Actions")
                 (org-super-agenda-groups
                  '((:name "🚨 Critical"
                           :priority "A")

                    (:name "🧠 Deep Work"
                           :tag "deep")

                    (:name "⚡ Quick Actions"
                           :tag "quick")

                    (:auto-category t)))))

          (todo "WAIT"
                ((org-agenda-overriding-header "⏳ Waiting")))

          (todo "QUESTION"
                ((org-agenda-overriding-header "❓ Open Questions")))

          (todo "REVIEW"
                ((org-agenda-overriding-header "↻ Review Queue")))))

        ;; Weekly review -------------------------------------------------------

        ("w" "Weekly Overview"

         ((agenda ""
                  ((org-agenda-span 7)
                   (org-agenda-start-on-weekday nil)
                   (org-agenda-overriding-header "📅 Coming Week")))

          (todo "NEXT"
                ((org-agenda-overriding-header "▶ Active Next Actions")))

          (todo "WAIT"
                ((org-agenda-overriding-header "⏳ Waiting / Delegated")))

          (todo "QUESTION"
                ((org-agenda-overriding-header "❓ Questions to Resolve")))

          (todo "REVIEW"
                ((org-agenda-overriding-header "↻ Topics to Review")))))

        ;; Focused views -------------------------------------------------------

        ("n" "Next Actions"
         todo "NEXT")

        ("q" "Open Questions"
         todo "QUESTION")

        ("r" "Review Queue"
         todo "REVIEW")

        ("W" "Waiting"
         todo "WAIT")

        ("x" "Exams"
         tags-todo "exam"
         ((org-agenda-sorting-strategy '(deadline-up priority-down))))

        ("a" "Assignments"
         tags-todo "assignment"
         ((org-agenda-sorting-strategy '(deadline-up priority-down))))

        ("p" "Projects"
         tags-todo "project"
         ((org-agenda-sorting-strategy
           '(priority-down deadline-up todo-state-up))))

        ;; Context views -------------------------------------------------------

        ("c" . "Contexts")

        ("ch" "@home"
         tags-todo "@home/NEXT")

        ("cc" "@campus"
         tags-todo "@campus/NEXT")

        ("co" "@computer"
         tags-todo "@computer/NEXT")

        ("cl" "@lab"
         tags-todo "@lab/NEXT")

        ("ce" "@errand"
         tags-todo "@errand/NEXT")

        ("cp" "@phone"
         tags-todo "@phone/NEXT")))

;;; ---------------------------------------------------------------------------
;;; Evil Org
;;; ---------------------------------------------------------------------------

(use-package evil-org
  :ensure t
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme
   '(navigation insert textobjects additional calendar)))

;;; ---------------------------------------------------------------------------
;;; Org QL
;;; ---------------------------------------------------------------------------

(use-package org-ql
  :ensure t
  :bind ("M-s a" . my-consult-org-ql-agenda-jump))

;;; ---------------------------------------------------------------------------
;;; Denote
;;; ---------------------------------------------------------------------------

;; Boundary:
;;
;;   Org    = responsibilities, actions, projects, deadlines, courses, reviews.
;;   Denote = durable knowledge, permanent notes, research, technical concepts.
;;
;; They may link to one another, but notes-dir is deliberately NOT part of the
;; agenda file set.

(use-package denote
  :ensure t
  :hook (dired-mode . denote-dired-mode)
  :bind
  (("C-c n n" . denote)
   ("C-c n r" . denote-rename-file)
   ("C-c n l" . denote-link)
   ("C-c n b" . denote-backlinks)
   ("C-c n d" . denote-dired)
   ("C-c n g" . denote-grep))
  :config

  (setq denote-directory (my/path 'notes-dir "~/notes/"))

  (setq denote-known-keywords
        '("school"
          "engineering"
          "project"
          "philosophy"
          "self"
          "research"
          "reference"))

  (denote-rename-buffer-mode 1))

;;; ---------------------------------------------------------------------------
;;; Bootstrap helpers
;;; ---------------------------------------------------------------------------

(defun my/org-initialize-file (file title category &optional filetags)
  "Create FILE with TITLE, CATEGORY and optional FILETAGS if it does not exist."
  (unless (file-exists-p file)
    (with-temp-file file
      (insert "#+title: " title "\n")
      (insert "#+category: " category "\n")
      (when filetags
        (insert "#+filetags: " filetags "\n"))
      (insert "\n"))))

(defun my/org-bootstrap ()
  "Create the basic universal Org file structure without overwriting data."
  (interactive)

  (my/org-create-system-directories)

  (my/org-initialize-file
   (my/org-file "inbox.org")
   "Inbox"
   "Inbox")

  (my/org-initialize-file
   (my/org-file "agenda.org")
   "Agenda"
   "Routine")

  (my/org-initialize-file
   (my/org-file "projects.org")
   "Projects"
   "Projects")

  (my/org-initialize-file
   (my/org-file "someday.org")
   "Someday / Maybe"
   "Someday")

  (my/org-initialize-file
   (my/org-file "reference.org")
   "Reference"
   "Reference")

  (my/org-initialize-file
   (my/org-file "journal.org")
   "Journal"
   "Journal")

  ;; Add required project headings only when absent.
  (let ((file (my/org-file "projects.org")))
    (with-current-buffer (find-file-noselect file)
      (goto-char (point-min))
      (unless (re-search-forward "^\\* Active$" nil t)
        (goto-char (point-max))
        (insert "\n* Active\n"))
      (goto-char (point-min))
      (unless (re-search-forward "^\\* Engineering$" nil t)
        (goto-char (point-max))
        (insert "\n* Engineering\n"))
      (save-buffer)))

  ;; Seed agenda.org with universal recurring-review examples only when empty
  ;; beyond its metadata.
  (let ((file (my/org-file "agenda.org")))
    (with-current-buffer (find-file-noselect file)
      (goto-char (point-min))
      (unless (re-search-forward "^\\* Reviews$" nil t)
        (goto-char (point-max))
        (insert
         "\n* Reviews\n\n"
         "** TODO Daily Review :routine:\n"
         ":PROPERTIES:\n"
         ":STYLE: habit\n"
         ":END:\n\n"
         "** TODO Weekly Review :routine:\n\n"
         "** TODO Monthly Financial Review :routine:\n\n"
         "* Routines\n\n"
         "** TODO Process Inbox :routine:\n\n"
         "** TODO Review Upcoming Deadlines :routine:\n")
        (save-buffer))))

  (my/org-refresh-agenda-files)
  (my/org-refresh-refile-targets)

  (message
   "Universal Org system initialized. Add dates/repeaters to routines as desired."))

(provide 'org-config)

;;; org.el ends here
