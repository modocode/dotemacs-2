;;; modules/org.el --- Org-mode configuration -*- lexical-binding: t; -*-
;;
;; Paths are resolved through the mo-paths registry (mo-lisp/mo-paths.el)
;; so this file never needs to change between machines.
;;
;; To customise paths for your machine, open your os/ file and call:
;;   (my/register-path 'org-dir   "~/wherever/org/")
;;   (my/register-path 'notes-dir "~/wherever/notes/")

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
  )

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
  :ensure t)

(setq org-agenda-span 7)
(setq org-agenda-start-on-weekday nil) ; Starts from today, not Monday

(setq org-super-agenda-groups
      '(;; 1. THE "NON-NEGOTIABLES"
        (:name "🚀 Critical & Exams"
               :priority "A"
               :tag "exam")
        
        ;; 2. HEALTH & VITALITY (Gym/Health)
        (:name "💪 Physical Lab (Health & Gym)"
               :tag "health"
               :regexp "gym\\|workout\\|run\\|meal prep")

        ;; 3. CAREER & CONNECTIONS (Networking/Social/Orgs)
        (:name "🤝 Networking & Social"
               :tag ("social" "networking" "ieee" "orgs" "jobfair")
               :regexp "out with\\|meetup\\|fair\\|club")

        ;; 4. THE FORGE (Personal Projects/Portfolio)
        (:name "🛠️ Portfolio & Projects"
               :tag "project"
               :and (:todo "TODO" :tag "personal"))

        ;; 5. DEEP WORK (Scheduled Study Blocks)
        (:name "🧠 Deep Work Blocks"
               :tag "study"
               :and (:scheduled future :regexp "Block"))

        ;; 6. UNIVERSITY LOGISTICS (The "Bottlenecks")
        (:name "🏫 UTA Admin & Logistics"
               :tag ("work" "housing" "finance")
               :discard (:tag "homework")) ;; Keep logistics separate from actual study

        ;; 7. ACADEMICS (Grouped by Subject)
        (:name "📐 Math & Physics"
               :tag ("calc" "diffeq" "phys"))
        (:name "🔌 Engineering Labs"
               :tag ("ee1106" "ee1201" "ee2301"))

        ;; 8. PURCHASING & LOGS
        (:name "🛒 Gear & Orders"
               :regexp "Buy\\|Order\\|Purchase")
        
        (:name "✅ Wins Today"
               :log t)

        ;; Catch-all for everything else
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


;; --- Custom Agenda View

(setq org-agenda-custom-commands
	  '(("s" "School & Life Dashboard"
		 ((org-ql-block '(and (todo "TODO" "NEXT")
							  (deadline today))
						((org-ql-block-header "🔥 DUE TODAY")))

          (org-ql-block '(and (todo "TODO" "NEXT")
                              (tags "school")
                              (not (deadline <= today)))
                        ((org-ql-block-header "📚 Upcoming School Work")))

          (org-ql-block '(and (todo "NEXT")
                              (not (tags "school")))
                        ((org-ql-block-header "⚡ Personal Next Actions")))

          (agenda "" ((org-agenda-span 7)
                      (org-agenda-overriding-header "📅 Weekly Overview")))

          (org-ql-block '(and (todo "WAITING"))
                        ((org-ql-block-header "⏳ Waiting on Others")))))

        ("5" "The Big 5 Areas"
         ((org-ql-block '(and (todo "NEXT") (tags "health"))
                        ((org-ql-block-header "🍎 Health & Vitality")))
          (org-ql-block '(and (todo "NEXT") (tags "finance"))
                        ((org-ql-block-header "💰 Finance & Career")))
          (org-ql-block '(and (todo "NEXT") (tags "growth"))
                        ((org-ql-block-header "🧠 Personal Growth")))
          (org-ql-block '(and (todo "NEXT") (tags "social"))
                        ((org-ql-block-header "🤝 Relationships/Social")))
          (org-ql-block '(and (todo "NEXT") (tags "home"))
                        ((org-ql-block-header "🏠 Home & Environment")))))))

;; --- Org Capture Templates

(setq org-capture-templates
      '(("t" "Tasks")
        ("tt" "Inbox Task" entry (file+headline "~/org/gtd.org" "Inbox")
         "* TODO %^{Task Name} %^G\n  %U\n  %i"
         :empty-lines 1 :kill-buffer t)

        ("tw" "Work Task" entry (file+headline "~/org/gtd.org" "Work")
         "* TODO %^{Task Name} :work:\n  SCHEDULED: %t\n  %a"
         :empty-lines 1)

        ("ti" "Immediate/Urgent" entry (file+headline "~/org/gtd.org" "Inbox")
         "* TODO [#A] %^{Task Name} :urgent:\n  SCHEDULED: %t\n"
         :immediate-finish t)
        ;; --- Group 2: Contextual & Reading ---
        ("r" "Reference/Reading")

        ;; Captures a link, uses %c to paste clipboard content automatically
        ("rl" "Link to Read" entry (file+headline "~/org/gtd.org" "Reading List")
         "* TODO Read: %:description\n  Source: %u\n  %c\n  %a"
         :empty-lines 1)

        ;; Great for saving code snippets or specific text selections (%i)
        ("rc" "Code Snippet" entry (file+headline "~/org/gtd.org" "Resources")
         "* %^{Description} :code:\n#+BEGIN_SRC %^{Language}\n%i\n#+END_SRC\n  Source: %a")


	;; --- Group 3: Life Maintenance (Health & Admin) ---
        ("l" "Life")
        ("lh" "Health/Gym" entry (file+headline "~/org/gtd.org" "Health")
         "* TODO %^{Workout/Health Task} :health:\n  SCHEDULED: %^t\n  %?"
         :empty-lines 1)
        ("la" "Admin/Finance" entry (file+headline "~/org/gtd.org" "Admin")
         "* TODO %^{Admin Task} :admin:\n  DEADLINE: %^t\n  %?"
         :empty-lines 1)
        ("ln" "Networking/Social" entry (file+headline "~/org/gtd.org" "Social")
         "* TODO %^{Event/Meetup} :social:org:\n  SCHEDULED: %^t\n  %?"
         :empty-lines 1)
		

        ;; --- Group n: Information ---
        ("i" "Information")
        
        ("in" "New Info" entry (file+headline "~/org/gtd.org" "Info")
      	 "* %?\n:PROPERTIES:\n:SOURCE: %^{Source URL|Manual}\n:CAPTURED: %U\n:END:\n\n%i"
      	 :empty-lines 1)
    	("it" "Tech Tip" entry (file+headline "~/org/gtd.org" "Info")
    	 "* %? :TECH:\n:PROPERTIES:\n:LANGUAGE: %^{Language}\n:CAPTURED: %U\n:END:\n\n#+BEGIN_SRC %\\1\n%i\n#+END_SRC"
    	 :empty-lines 1)
        ("if" "Quick Fact" entry (file+headline "~/org/gtd.org" "Info")
         "* %^{Fact About}: %?\n  :PROPERTIES:\n  :CAPTURED: %U\n  :END:"
         :immediate-finish t)
  		("iq" "Quote" entry (file+headline "~/org/gtd.org" "Info")
  		 "* Quote by %^{Author} :QUOTE:\n  %U\n  #+BEGIN_QUOTE\n  %i%?\n  #+END_QUOTE")
  		
        ;; --- Group 4: Journal & Reviews ---
        ("j" "Journaling")

        ;; Uses a date-tree format in a separate file
        ("jj" "Journal Entry" entry (file+datetree "~/org/journal.org")
         "* %<%H:%M> %^{Title}\n  %?")

        ("jr" "Daily Review" entry (file+datetree "~/org/journal.org")
         "* %<%H:%M> Daily Review\n  1. What went well today?\n     %?\n  2. What could be improved?\n     \n")

      	;; --- Project Management Group ---
       	    ("s" "Someday/Maybe" entry (file+headline "~/org/gtd.org" "Someday")
		"* %?\n:PROPERTIES:\n:ENTERED: %U\n:END:\n\n%i")
        

	    ("p" "Universal Project Mission" entry
		    (file+headline "~/org/projects.org" "Missions")
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
			    )

        )

	  )

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
