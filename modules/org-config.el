;;; modules/org.el --- Org-mode configuration -*- lexical-binding: t; -*-
;;
;; Paths are resolved through the mo-paths registry (mo-lisp/mo-paths.el)
;; so this file never needs to change between machines.
;;
;; To customise paths for your machine, open your os/ file and call:
;;   (my/register-path 'org-dir   "~/wherever/org/")
;;   (my/register-path 'notes-dir "~/wherever/notes/")

(defun my/org-file (name)
  "Return the full path to NAME within the registered org-dir.
Falls back to ~/org/ on machines where org-dir has not been set."
  (concat (file-name-as-directory (my/path 'org-dir "~/org/")) name))

(use-package org
  :ensure nil   ; org is built-in; elpaca should not manage it
  :config

  ;; ── Paths (machine-specific values live in os/*.el) ─────────────────────
  ;; `my/path' expands ~ and returns nil if the key has no entry, so nothing
  ;; blows up on a machine where you haven't set up notes-dir yet.
  (setq org-directory (my/path 'org-dir "~/org/"))

  ;; `my/path-list' builds the list and silently drops any key that is not
  ;; registered, so agenda won't complain about a missing notes folder on a
  ;; machine where you haven't created it.
  (setq org-agenda-files (my/path-list 'org-dir 'notes-dir))

  ;; ── Editing Behaviour ────────────────────────────────────────────────────
  (setq org-M-RET-may-split-line    '((default . nil)))
  (setq org-insert-heading-respect-content t)
  (setq org-log-into-drawer          t)

  ;; Will set org-todo-keywords after watching gtd jjo

  ;; ── Capture Templates ────────────────────────────────────────────────────
  ;; All file paths go through my/org-file so they resolve against org-dir,
  ;; which is set per-machine in os/*.el (e.g. "N:/" on Windows).
  (setq org-capture-templates
        `(("t" "Tasks")
          ("tt" "Inbox Task" entry (file+headline ,(my/org-file "gtd.org") "Inbox")
           "* TODO %^{Task Name} %^G\n  %U\n  %i"
           :empty-lines 1 :kill-buffer t)

          ("tw" "Work Task" entry (file+headline ,(my/org-file "gtd.org") "Work")
           "* TODO %^{Task Name} :work:\n  SCHEDULED: %t\n  %a"
           :empty-lines 1)

          ("ti" "Immediate/Urgent" entry (file+headline ,(my/org-file "gtd.org") "Inbox")
           "* TODO [#A] %^{Task Name} :urgent:\n  SCHEDULED: %t\n"
           :immediate-finish t)

          ;; --- Group 2: Contextual & Reading ---
          ("r" "Reference/Reading")

          ("rl" "Link to Read" entry (file+headline ,(my/org-file "gtd.org") "Reading List")
           "* TODO Read: %:description\n  Source: %u\n  %c\n  %a"
           :empty-lines 1)

          ("rc" "Code Snippet" entry (file+headline ,(my/org-file "gtd.org") "Resources")
           "* %^{Description} :code:\n#+BEGIN_SRC %^{Language}\n%i\n#+END_SRC\n  Source: %a")

          ;; --- Group 3: Life Maintenance (Health & Admin) ---
          ("l" "Life")
          ("lh" "Health/Gym" entry (file+headline ,(my/org-file "gtd.org") "Health")
           "* TODO %^{Workout/Health Task} :health:\n  SCHEDULED: %^t\n  %?"
           :empty-lines 1)
          ("la" "Admin/Finance" entry (file+headline ,(my/org-file "gtd.org") "Admin")
           "* TODO %^{Admin Task} :admin:\n  DEADLINE: %^t\n  %?"
           :empty-lines 1)
          ("ln" "Networking/Social" entry (file+headline ,(my/org-file "gtd.org") "Social")
           "* TODO %^{Event/Meetup} :social:org:\n  SCHEDULED: %^t\n  %?"
           :empty-lines 1)

          ;; --- Group n: Information ---
          ("i" "Information")

          ("in" "New Info" entry (file+headline ,(my/org-file "gtd.org") "Info")
           "* %?\n:PROPERTIES:\n:SOURCE: %^{Source URL|Manual}\n:CAPTURED: %U\n:END:\n\n%i"
           :empty-lines 1)
          ("it" "Tech Tip" entry (file+headline ,(my/org-file "gtd.org") "Info")
           "* %? :TECH:\n:PROPERTIES:\n:LANGUAGE: %^{Language}\n:CAPTURED: %U\n:END:\n\n#+BEGIN_SRC %\\1\n%i\n#+END_SRC"
           :empty-lines 1)
          ("if" "Quick Fact" entry (file+headline ,(my/org-file "gtd.org") "Info")
           "* %^{Fact About}: %?\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:"
           :immediate-finish t)
          ("iq" "Quote" entry (file+headline ,(my/org-file "gtd.org") "Info")
           "* Quote by %^{Author} :QUOTE:\n  %U\n  #+BEGIN_QUOTE\n  %i%?\n  #+END_QUOTE")

          ;; --- Group 4: Journal & Reviews ---
          ("j" "Journaling")

          ("jj" "Journal Entry" entry (file+datetree ,(my/org-file "journal.org"))
           "* %<%H:%M> %^{Title}\n  %?")

          ("jr" "Daily Review" entry (file+datetree ,(my/org-file "journal.org"))
           "* %<%H:%M> Daily Review\n  1. What went well today?\n     %?\n  2. What could be improved?\n     \n")

          ;; --- Project Management Group ---
          ("s" "Someday/Maybe" entry (file+headline ,(my/org-file "gtd.org") "Someday")
           "* %?\n:PROPERTIES:\n:ENTERED: %U\n:END:\n\n%i")

          ("p" "Universal Project Mission" entry
           (file+headline ,(my/org-file "projects.org") "Missions")
           "* MISSION: %^{Project Name} :SYSTEMS_ENG:
		    :PROPERTIES:
		    :ID:       %(shell-command-to-string \"uuidgen\" | tr -d '\\n')
		    :CREATED:  %U
		    :STATUS:   INITIATING
		    :CATEGORY: %^{Category|Lab|Invention|Personal|Software}
		    :END:

		    ,** 1. CONOPS (Concept of Operations)
		    - **Primary Intent:** %^{What is the singular purpose of this creation?}
		    - **Operating Environment:** %^{Where/When will this exist? (e.g., local server, outdoor, lab)}
		    - **The 'Impossible' Constraint:** %^{What is the bottleneck we are breaking?}

		    ,** 2. ARCHITECTURAL DECOMPOSITION (The V-Model)
		    - [ ] [MODULE-A]: %^{Physical or Logic Layer 1}
		    - [ ] [MODULE-B]: %^{Physical or Logic Layer 2}
		    - [ ] [INTERFACE]: %^{How do these modules exchange energy/data/force?}

		    ,** 3. PERFORMANCE REQUIREMENTS (Success Metrics)
		    | Parameter        | Target/Baseline | Actual Result | Status |
		    |------------------+-----------------+---------------+--------|
		    | Metric 1 (Main)  | %^{Target}      |               | PEND   |
		    | Metric 2 (Const) |                 |               | PEND   |
		    | Metric 3 (Efficiency) |             |               | PEND   |

		    ,** 4. THE EXECUTION LOOP (Cybernetic Log)
		    ,#+BEGIN_QUOTE
		    \"A system is only as good as its feedback.\"
		    ,#+END_QUOTE
		    %?

		    ,** 5. V&V (Verification & Validation)
		    - [ ] **Verification:** Did the build match the blueprint?
		    - [ ] **Validation:** Does the blueprint actually solve the user's problem?
		    - [ ] **Recursive Shift:** What is the 10x version of this system?

		    ,** 6. KNOWLEDGE EXTRACTION (Resume/Portfolio)
		    - **Challenge:** %^{The core problem faced}
		    - **Action:** Implemented %\\1 using %^{Primary Tools/Methods}.
		    - **Result:** %^{Quantifiable outcome (%, $, Time, Speed)}."
           ))))

;; --- Org Todo

(setq org-todo-keywords
      '((sequence "TODO(t)" "START(s!)" "BLOCKED(b@/!)" "REVIEW(v!)" "DOC(d!)" "|" "DONE(0!)" "CANCELLED(c@)")))

(setq org-todo-keyword-faces
      '(("TODO" . (:foreground "orange" :weight bold))
        ("START" . (:foreground "cyan" :weight bold))
        ("BLOCKED" . (:foreground "red" :weight bold))
        ("REVIEW" . (:foreground "magenta" :weight bold))
        ("DOC" . (:foreground "yellow" :weight bold))
        ("DONE" . (:foreground "green" :weight bold))
        ("CANCELLED" . (:foreground "gray" :weight bold))))
(setq org-use-fast-todo-selection t)


;; --- Org Tagging

(setq org-tag-alist '((:startgroup . nil)
                      ("study" . ?s) ("assignment" . ?a) ("exam" . ?e) ("lab" . ?l)
                      (:endgroup . nil)
                      (:startgroup . nil)
                      ("project" . ?p) ("career" . ?c) ("org" . ?o)
                      (:endgroup . nil)
                      ("health" . ?h) ("social" . ?z) ("admin" . ?m)))


;; --- Org Styling

(setq org-adapt-indentation t
      org-hide-leading-stars t
      org-hide-emphasis-markers t
      org-pretty-entities t
	  org-ellipsis "  ·")

(setq org-src-fontify-natively t
	  org-src-tab-acts-natively t
      org-edit-src-content-indentation 0)

;; --- Org Modern

(use-package org-modern
  :ensure t
  :demand t   ; :config must run at startup so global-org-modern-mode activates
  :custom
  (org-auto-align-tags              t)
  (org-tags-column                  0)
  (org-fold-catch-invisible-edits   'show-and-error)
  (org-special-ctrl-a/e             t)
  (org-insert-heading-respect-content t)
  ;; Don't style these — org-superstar handles bullets/todo markers
  (org-modern-tag      nil)
  (org-modern-priority nil)
  (org-modern-todo     nil)
  :config
  (global-org-modern-mode))



;; --- Org Super Agenda

(use-package org-super-agenda
  :ensure t
  :demand t   ; must activate the mode before any agenda view runs
  :config
  (org-super-agenda-mode 1))

(setq org-agenda-span 7)
(setq org-agenda-start-on-weekday nil) ; Starts from today, not Monday

;; Default groups used by the plain `org-agenda' dispatcher (SPC o a).
;; Focused views below set their own groups via the local-var alist.
(setq org-super-agenda-groups
      '((:name "🚀 Critical & Exams"    :priority "A" :tag "exam")
        (:name "💪 Health & Gym"         :tag "health" :regexp "gym\\|workout\\|run")
        (:name "🤝 Networking & Social"  :tag ("social" "networking" "ieee" "orgs"))
        (:name "🛠️  Portfolio & Projects" :tag "project")
        (:name "🧠 Deep Work Blocks"     :tag "study" :regexp "Block")
        (:name "🏫 UTA Admin"            :tag ("work" "housing" "finance")
               :discard (:tag "homework"))
        (:name "📐 Math & Physics"       :tag ("calc" "diffeq" "phys"))
        (:name "🔌 Engineering Labs"     :tag ("ee1106" "ee1201" "ee2301"))
        (:name "🛒 Gear & Orders"        :regexp "Buy\\|Order\\|Purchase")
        (:name "✅ Wins Today"           :log t)
        (:auto-group t)))

;; --- Org Superstar
(use-package org-superstar
  :ensure t
  :hook (org-mode . org-superstar-mode)
  :config
;;(setq org-superstar-leading-bullet " ")
; Set different bullets, with one getting a terminal fallback.
(setq org-superstar-headline-bullets-list
      '("◉" ("🞛" ?◈) "○" "▷"))
(setq org-superstar-special-todo-items t) ;; Makes TODO header bullets into boxes
(setq org-superstar-todo-bullet-alist '(("TODO" . 9744)
                                        ("DONE" . 9744)
                                        ("READ" . 9744)
                                        ("IDEA" . 9744)
                                        ("WAITING" . 9744)
                                        ("CANCELLED" . 9744)
                                        ("PROJECT" . 9744)
                                        ("POSTPONED" . 9744)))
)

(with-eval-after-load 'org-superstar
  (setq org-superstar-item-bullet-alist
        '((?* . ?•)
          (?+ . ?➤)
          (?- . ?•)))
  (setq org-superstar-headline-bullets-list '(?\d))
  (setq org-superstar-special-todo-items t)
  (setq org-superstar-remove-leading-stars t)
  (setq org-hide-leading-stars t)
  ;; Enable custom bullets for TODO items
  (setq org-superstar-todo-bullet-alist
        '(("TODO" . ?☐)
          ("NEXT" . ?✒)
          ("HOLD" . ?✰)
          ("WAITING" . ?☕)
          ("CANCELLED" . ?✘)
          ("DONE" . ?✔)))
  (org-superstar-restart))
(setq org-ellipsis " ▼ ")


;; --- Evil Org (restores TAB=org-cycle and other keys overridden by evil-collection)

(use-package evil-org
  :ensure t
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar)))


;; --- Org Ql

(use-package org-ql
  :ensure t
  :bind ("M-s a" . my-consult-org-ql-agenda-jump))


;; --- Custom Agenda Views
;;
;; ── Tag Registers ─────────────────────────────────────────────────────────
;; These two strings are the ONLY things you edit each semester.
;; Add/remove course tags here and all views update automatically.
;; Use the org match-string syntax: tags separated by | (OR) or & (AND).

(defvar my/school-tags
  "homework|assignment|exam|lab|study|calc|phys|diffeq|ee1106|ee1201|ee2301|college"
  "Org tags match-string for all school work.
Edit this at the start of each semester — all school views derive from it.")

(defvar my/life-tags
  "health|social|admin|career|self|finance|home|growth|org"
  "Org tags match-string for life areas (from org-tag-alist).
Add new life domains here and they appear in SPC o l automatically.")

;; ── Build Commands ────────────────────────────────────────────────────────
;; Backtick + comma splices the defvar values in at load time so the match
;; strings are always in sync with the registers above.
;; After editing a register, reload with: SPC e b (eval-buffer) or SPC q r.

(setq org-agenda-custom-commands
      `(
        ;; ── h: School / Homework ──────────────────────────────────────────
        ;; Groups: overdue → today → exams → labs → per-course (auto-parent).
        ;; `:auto-parent t` reads the parent heading ("Calc", "Physics", etc.)
        ;; so a new course you add in gtd.org shows up as its own group here
        ;; with zero config changes.
        ("h" "📚 School Work"
         ((tags-todo ,my/school-tags
                     ((org-super-agenda-groups
                       '((:name "🔥 Overdue"          :deadline past)
                         (:name "⚡ Due Today"         :deadline today)
                         (:name "🧪 Exams"             :tag "exam")
                         (:name "🔬 Lab Reports"       :tag "lab")
                         (:name "🚧 Blocked"           :todo "BLOCKED")
                         (:auto-parent t)))
                      (org-agenda-sorting-strategy
                       '(deadline-up priority-down todo-state-up))))))

        ;; ── e: Exam Tracker ───────────────────────────────────────────────
        ;; All exam-tagged items sorted soonest-first. Review tasks without
        ;; a deadline float to the bottom so you notice them.
        ("e" "🧪 Exam Tracker"
         ((tags-todo "exam"
                     ((org-super-agenda-groups
                       '((:name "🔥 Overdue Prep"     :deadline past)
                         (:name "⚡ Exam Today"        :deadline today)
                         (:name "📅 Coming Up"         :deadline future)
                         (:name "❓ No Deadline Set"   :deadline nil)
                         (:discard (:anything t))))
                      (org-agenda-sorting-strategy '(deadline-up priority-down))))))

        ;; ── l: Life Areas ─────────────────────────────────────────────────
        ;; Covers everything outside school: health, admin, career, social…
        ;; Add a new life-area tag to my/life-tags and it appears here.
        ("l" "🌿 Life Areas"
         ((tags-todo ,my/life-tags
                     ((org-super-agenda-groups
                       '((:name "🚨 Urgent"            :priority "A")
                         (:name "💪 Health & Gym"      :tag "health")
                         (:name "💼 Career"            :tag "career")
                         (:name "🤝 Social"            :tag "social")
                         (:name "📋 Admin & Finance"   :tag ("admin" "finance"))
                         (:name "🏠 Home"              :tag "home")
                         (:name "🌱 Growth"            :tag ("growth" "self"))
                         (:auto-tags t)))
                      (org-agenda-sorting-strategy
                       '(priority-down deadline-up todo-state-up))))))

        ;; ── p: Projects ───────────────────────────────────────────────────
        ;; All project-tagged items grouped by parent section so each project
        ;; gets its own bucket. Sort by priority within each group.
        ("p" "🛠 Projects"
         ((tags-todo "project"
                     ((org-super-agenda-groups
                       '((:name "🚨 Urgent"            :priority "A")
                         (:auto-parent t)))
                      (org-agenda-sorting-strategy
                       '(priority-down deadline-up))))))

        ;; ── r: Reading List ───────────────────────────────────────────────
        ;; Flat priority-sorted list of everything to read.
        ("r" "📖 Reading List"
         ((tags-todo "reading"
                     ((org-super-agenda-groups
                       '((:name "Read Next"  :priority "A")
                         (:name "Backlog"    :priority< "A")
                         (:discard (:anything t))))
                      (org-agenda-sorting-strategy '(priority-down))))))

        ;; ── w: Weekly Overview ────────────────────────────────────────────
        ;; 7-day calendar view with default org-super-agenda-groups.
        ;; Good for morning planning — shows everything across all areas.
        ("w" "📅 Weekly Overview"
         ((agenda "" ((org-agenda-span 7)
                      (org-agenda-start-on-weekday nil)
                      (org-agenda-overriding-header "")))))

        ;; ── 5: Big 5 Life Areas (org-ql version) ─────────────────────────
        ;; Fixed: was using todo "NEXT" which doesn't exist — now uses "START".
        ("5" "The Big 5 Areas"
         ((org-ql-block '(and (todo "TODO" "START") (tags "health"))
                        ((org-ql-block-header "🍎 Health & Vitality")))
          (org-ql-block '(and (todo "TODO" "START") (tags "career" "finance"))
                        ((org-ql-block-header "💰 Finance & Career")))
          (org-ql-block '(and (todo "TODO" "START") (tags "growth" "self"))
                        ((org-ql-block-header "🧠 Personal Growth")))
          (org-ql-block '(and (todo "TODO" "START") (tags "social"))
                        ((org-ql-block-header "🤝 Relationships/Social")))
          (org-ql-block '(and (todo "TODO" "START") (tags "home" "admin"))
                        ((org-ql-block-header "🏠 Home & Admin")))))))


;; --- Structure Templates

(with-eval-after-load 'org
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
  (add-to-list 'org-structure-template-alist '("cpp" . "src C++"))
  (add-to-list 'org-structure-template-alist '("rs" . "src rust")))

;; --- Denote


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
  (setq org-agenda-files (my/path-list 'org-dir 'notes-dir))
  (setq denote-directory (my/path-list 'notes-dir))
  (setq denote-known-keywords '("school" "project" "philsophy" "self"))

  ;; Automatically rename Denote buffers when opening them so that
  ;; instead of their long file name they have, for example, a literal
  ;; "[D]" followed by the file's title.  Read the doc string of
  ;; `denote-rename-buffer-format' for how to modify this.
  (denote-rename-buffer-mode 1))

(provide 'org-config)
;;; org.el ends here
