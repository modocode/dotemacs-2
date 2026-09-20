;;; modules/keybindings.el --- Leader keybindings and hydra UIs -*- lexical-binding: t; -*-
;;

(use-package hydra
  :ensure t
  :demand t
  :config

  (defhydra hydra-window-resize (:hint nil)
    "
  Window Resize
  _h_ shrink ←   _l_ grow →
  _j_ shrink ↓   _k_ grow ↑
  _=_ balance    _q_ done
"
    ("h" (lambda () (interactive) (shrink-window-horizontally 3)))
    ("l" (lambda () (interactive) (enlarge-window-horizontally 3)))
    ("j" (lambda () (interactive) (shrink-window 3)))
    ("k" (lambda () (interactive) (enlarge-window 3)))
    ("=" balance-windows)
    ("q" nil :exit t))

  (defhydra hydra-text-scale (:hint nil)
    "
  Text Zoom
  _+_ larger   _-_ smaller   _0_ reset   _q_ done
"
    ("+" (lambda () (interactive) (text-scale-increase 1)))
    ("-" (lambda () (interactive) (text-scale-decrease 1)))
    ("0" (lambda () (interactive) (text-scale-set 0)) :exit t)
    ("q" nil :exit t))

  (defhydra hydra-git-hunk (:hint nil)
    "
  Git Hunks
  _n_ next   _p_ prev   _s_ stage   _r_ revert   _d_ show   _q_ done
"
    ("n" (lambda () (interactive) (diff-hl-next-hunk)))
    ("p" (lambda () (interactive) (diff-hl-previous-hunk)))
    ("s" (lambda () (interactive) (diff-hl-stage-current-hunk)))
    ("r" (lambda () (interactive) (diff-hl-revert-hunk)))
    ("d" (lambda () (interactive) (diff-hl-show-hunk)))
    ("q" nil :exit t))

  (defhydra hydra-org-nav (:hint nil :foreign-keys warn)
    "
  ┌─────────────────────────── Org Navigate ───────────────────────────────┐
  Headings  _n_ next       _p_ prev       _f_ → same lvl  _b_ ← same lvl
            _u_ up level   _g_ goto…      _i_ imenu jump
  Visible   _TAB_ cycle    _S-TAB_ global _<_ narrow      _>_ widen
  Structure _H_ promote    _L_ demote     _J_ move ↓      _K_ move ↑
  Links     _RET_ follow   _._ next link  _,_ prev link
  Blocks    _]_ next blk   _[_ prev blk
  Search    _/_ sparse     _s_ consult    _a_ agenda
  Clock     _I_ clock in   _O_ clock out  _G_ goto clock
  └────────────────────────────────────────────────────────────────────────┘
  _q_ quit
"
    ("n"   org-next-visible-heading)
    ("p"   org-previous-visible-heading)
    ("f"   org-forward-heading-same-level)
    ("b"   org-backward-heading-same-level)
    ("u"   (lambda () (interactive) (outline-up-heading 1)))
    ("g"   org-goto                :exit t)
    ("i"   consult-org-heading     :exit t)
    ;; ── Visibility ────────────────────────────────────────────────────────
    ("TAB"   org-cycle)
    ("S-TAB" org-global-cycle)
    ("<"   org-narrow-to-subtree   :exit t)
    (">"   widen                   :exit t)
    ;; ── Structure ─────────────────────────────────────────────────────────
    ("H"   org-do-promote)
    ("L"   org-do-demote)
    ("J"   org-move-subtree-down)
    ("K"   org-move-subtree-up)
    ;; ── Links ─────────────────────────────────────────────────────────────
    ("RET" org-open-at-point       :exit t)
    ("."   org-next-link)
    (","   org-previous-link)
    ;; ── Blocks ────────────────────────────────────────────────────────────
    ("]"   org-next-block)
    ("["   org-previous-block)
    ;; ── Search ────────────────────────────────────────────────────────────
    ("/"   org-sparse-tree         :exit t)
    ("s"   consult-org-heading     :exit t)
    ("a"   org-agenda              :exit t)
    ;; ── Clock ─────────────────────────────────────────────────────────────
    ("I"   org-clock-in            :exit t)
    ("O"   org-clock-out           :exit t)
    ("G"   org-clock-goto          :exit t)
    ;; ── Quit ──────────────────────────────────────────────────────────────
    ("q"   nil                     :exit t))

  (defhydra hydra-org-table (:hint nil :foreign-keys warn)
    "
  ┌─────────────────────────── Org Table ──────────────────────────────┐
  Navigate  _n_ next fld   _p_ prev fld   _j_ next row   _RET_ new row
  Move      _H_ col ←      _L_ col →      _J_ row ↓      _K_ row ↑
  Insert    _r_ ins row    _c_ ins col
  Delete    _R_ del row    _C_ del col    _b_ blank fld
  Compute   _a_ align      _=_ formula    _*_ recalc     _s_ sort
  └────────────────────────────────────────────────────────────────────┘
  _q_ quit
"
    ;; ── Navigate ──────────────────────────────────────────────────────────
    ("n"   org-table-next-field)
    ("p"   org-table-previous-field)
    ("j"   (lambda () (interactive) (org-table-next-row)))
    ("RET" org-table-next-row)
    ;; ── Move ──────────────────────────────────────────────────────────────
    ("H"   org-table-move-column-left)
    ("L"   org-table-move-column-right)
    ("J"   org-table-move-row-down)
    ("K"   org-table-move-row-up)
    ;; ── Insert / Delete ───────────────────────────────────────────────────
    ("r"   org-table-insert-row)
    ("R"   org-table-kill-row)
    ("c"   org-table-insert-column)
    ("C"   org-table-delete-column)
    ("b"   org-table-blank-field)
    ;; ── Compute ───────────────────────────────────────────────────────────
    ("a"   org-table-align)
    ("="   org-table-eval-formula     :exit t)
    ("*"   (lambda () (interactive) (org-table-recalculate t)))
    ("s"   org-table-sort-lines       :exit t)
    ;; ── Quit ──────────────────────────────────────────────────────────────
    ("q"   nil                        :exit t))

  (defhydra hydra-window-rotate (:hint nil)
    "
  ┌─────────────────── Window Rotate ───────────────────────┐
  Cycle   _r_ rotate layouts   _w_ rotate windows (swap)
  Set     _h_ even horizontal  _v_ even vertical
          _H_ main horizontal  _V_ main vertical
          _t_ tiled
  └─────────────────────────────────────────────────────────┘
  _q_ done
"
    ("r" rotate-layout)
    ("w" rotate-window)
    ("h" rotate:even-horizontal   :exit t)
    ("v" rotate:even-vertical     :exit t)
    ("H" rotate:main-horizontal   :exit t)
    ("V" rotate:main-vertical     :exit t)
    ("t" rotate:tiled             :exit t)
    ("q" nil                      :exit t))

  (defhydra hydra-tabs (:hint nil)
    "
  Buffer tabs  _n_ next  _p_ prev  _a_ first  _e_ last  _<_ move←  _>_ move→
               _N_ next grp   _P_ prev grp   _g_ switch grp   _k_ kill others in grp
  Workspace    _c_ new tab    _x_ close tab  _r_ rename tab   _s_ switch tab
  Tab groups   _A_ assign grp _X_ close grp  _G_ switch grp
  _q_ done
"
    ;; ── centaur-tabs: buffer tabs within the current group ─────────────────
    ("n" (lambda () (interactive) (centaur-tabs-forward)))
    ("p" (lambda () (interactive) (centaur-tabs-backward)))
    ("a" (lambda () (interactive) (centaur-tabs-select-beg-tab)))
    ("e" (lambda () (interactive) (centaur-tabs-select-end-tab)))
    ("<" (lambda () (interactive) (centaur-tabs-move-current-tab-to-left)))
    (">" (lambda () (interactive) (centaur-tabs-move-current-tab-to-right)))
    ("N" (lambda () (interactive) (centaur-tabs-forward-group)))
    ("P" (lambda () (interactive) (centaur-tabs-backward-group)))
    ("g" (lambda () (interactive) (centaur-tabs-switch-group)) :exit t)
    ("k" (lambda () (interactive) (centaur-tabs-kill-other-buffers-in-current-group)) :exit t)
    ;; ── tab-bar: workspace tabs (window layouts) ──────────────────────────
    ("c" (lambda () (interactive) (centaur-tabs--create-new-tab))               :exit t)
    ("x" (lambda () (interactive) (tab-bar-close-tab))             :exit t)
    ("r" (lambda () (interactive) (tab-bar-rename-tab nil))        :exit t)
    ("s" (lambda () (interactive) (tab-bar-switch-to-tab
                                   (completing-read "Switch to tab: "
                                                    (mapcar (lambda (tab)
                                                              (alist-get 'name tab))
                                                            (tab-bar-tabs)))))
     :exit t)
    ;; ── tab-bar groups: named collections of workspace tabs (Emacs 28+) ───
    ;; Assign the current workspace tab to a named group; tabs in the same
    ;; group are visually clustered in the tab bar.
    ("A" (lambda () (interactive) (tab-bar-change-tab-group
                                   (completing-read "Assign to group: "
                                                    (tab-bar-tab-group-names
                                                     (tab-bar-tabs)))))
     :exit t)
    ("X" (lambda () (interactive) (tab-bar-close-group-tabs
                                   (completing-read "Close group: "
                                                    (tab-bar-tab-group-names
                                                     (tab-bar-tabs)))))
     :exit t)
    ("G" (lambda () (interactive) (tab-bar-switch-to-tab
                                   (completing-read "Switch to tab in group: "
                                                    (mapcar (lambda (tab)
                                                              (alist-get 'name tab))
                                                            (tab-bar-tabs)))))
     :exit t)
    ("q" nil :exit t))

  (defhydra hydra-embark (:hint nil :foreign-keys warn)
    "
  ┌────────────────────────── Embark ──────────────────────────────┐
  Act      _a_ act on target    _d_ dwim (default action)
  Collect  _c_ collect          _l_ collect live    _e_ export
  Browse   _b_ show bindings    _s_ isearch forward
  └────────────────────────────────────────────────────────────────┘
  _q_ quit
"
    ("a" embark-act              :exit t)  ; opens embark's own action menu
    ("d" embark-dwim             :exit t)  ; performs the single most-likely action
    ("c" embark-collect          :exit t)  ; snapshot candidates → *Embark Collect*
    ("l" embark-live-collect     :exit t)  ; live-updating collect buffer (tracks minibuffer)
    ("e" embark-export           :exit t)  ; export to grep-mode, dired, etc.
    ("b" embark-bindings         :exit t)  ; describe all available actions
    ("s" embark-isearch-forward  :exit t)  ; isearch using current embark target as seed
    ("q" nil                     :exit t)))

;;; ── General ──────────────────────────────────────────────────────────────────
(require 'mo-modal)
;; Register new commands even when `mo-modal' is already loaded during reload.
(autoload 'mo-modal-tutor "mo-modal-tutor"
  "Open a fresh buffer of hands-on modal editing lessons." t)
(defvar my/leader-map (make-sparse-keymap)
  "Shared leader menu, independent of the editing backend.")

(use-package general
  :ensure (:wait t)
  :demand t
  :config
  (general-create-definer my/leader :keymaps 'my/leader-map)
  (general-define-key :keymaps 'global-map "M-SPC" my/leader-map)
  (general-define-key :keymaps 'mo-modal-mode-map
    "<escape>" #'mo-modal-enter-command
    ;; Keep raw ESC available for Meta sequences in terminals.
    "C-c C-g" #'mo-modal-enter-command)
  (general-define-key :keymaps 'mo-modal-command-map
    "SPC" my/leader-map
    "i" #'mo-modal-enter-write
    ;; Familiar Meow pair; keep God character motions and prefix maps intact.
    "u" #'backward-word
    "o" #'forward-word
    "v" #'mo-modal-expand
    "V" #'mo-modal-contract
    "C-SPC" #'mo-modal-enter-select
    "C-@" #'mo-modal-enter-select
    "<escape>" #'mo-modal-enter-command)
  (general-define-key :keymaps 'mo-modal-select-map
    "s" #'mo-modal-cut
    "c" #'mo-modal-copy
    "d" #'mo-modal-delete
    "h" #'mo-modal-change
    ";" #'exchange-point-and-mark
    ">" #'mo-modal-indent-right
    "<" #'mo-modal-indent-left
    "(" (lambda () (interactive) (mo-modal-surround "(" ")"))
    "[" (lambda () (interactive) (mo-modal-surround "[" "]"))
    "{" (lambda () (interactive) (mo-modal-surround "{" "}"))
    "\"" (lambda () (interactive) (mo-modal-surround "\"" "\""))
    "'" (lambda () (interactive) (mo-modal-surround "'" "'")))

  ;; Reuse the menu when the backend is switched back to Meow.
  (with-eval-after-load 'meow
    (general-define-key
     :keymaps '(meow-normal-state-keymap meow-motion-state-keymap)
     "SPC" my/leader-map))


  ;; General Keybindings For Nutrition Tracking
  (require 'my-nutrition)


  ;; SPC m local leader — for mode-specific bindings added in other modules.
  ;; Example: (my/local-leader :keymaps 'python-mode-map "r" #'run-python)
  (general-create-definer my/local-leader
    :keymaps 'mo-modal-command-map
    :prefix  "SPC m"
    :global-prefix "M-SPC m")

  ;; Enable recentf so SPC f r works.
  (recentf-mode 1)

  (my/leader

    ;; Top Level
    "SPC" '(execute-extended-command :which-key "M-x")
    ":"   '(eval-expression           :which-key "eval expr")
    ";"   '(comment-dwim              :which-key "comment")
    "X"   '(my/health-check           :which-key "health check")
    "k"   '(browse-kill-ring          :which-key "clipboard")

    ;; Buffer Managment
    "b"   '(:ignore t                 :which-key "buffer")
    "b b" '(consult-buffer            :which-key "switch")
    "b k" '(kill-current-buffer       :which-key "kill")
    "b K" '(my/kill-other-buffers     :which-key "kill others")
    "b n" '(next-buffer               :which-key "next")
    "b p" '(previous-buffer           :which-key "prev")
    "b r" '(revert-buffer             :which-key "revert")
    "b s" '(save-buffer               :which-key "save")

    ;; File Operations
    "f"   '(:ignore t                 :which-key "file")
    "f f" '(find-file                 :which-key "find file")
    "f r" '(consult-recent-file       :which-key "recent files")
    "f o" '(consult-outline           :which-key "file outline")
    "f s" '(save-buffer               :which-key "save")
    "f S" '(save-some-buffers         :which-key "save all")
    "f R" '(my/rename-file-and-buffer :which-key "rename")
    "f y" '(my/copy-buffer-path       :which-key "copy path")
    "f i" '(my/open-init              :which-key "open init.el")
    "f v" '(vundo                     :which-key "undo tree")
    "f b" '(bookmark-bmenu-list       :which-key "bookmarks")

    ;; Window Managment
    "w"   '(:ignore t                 :which-key "window")
    "w v" '(split-window-right        :which-key "split right")
    "w s" '(split-window-below        :which-key "split below")
    "w d" '(delete-window             :which-key "delete")
    "w o" '(delete-other-windows      :which-key "only this")
    "w h" '(windmove-left              :which-key "go ←")
    "w S" '(scratch-buffer              :which-key "go ←")
    "w j" '(windmove-down             :which-key "go ↓")
    "w k" '(windmove-up               :which-key "go ↑")
    "w l" '(windmove-right            :which-key "go →")
    "w a" '(ace-window                :which-key "ace jump")
    "w =" '(balance-windows           :which-key "balance")
    "w r" '(hydra-window-resize/body       :which-key "resize…")
    "w z" '(hydra-text-scale/body          :which-key "zoom…")
    "w t" '(hydra-window-rotate/body       :which-key "rotate…")

    ;; Jump With Avy
    "j"   '(:ignore t                 :which-key "jump")
    "j j" '(avy-goto-char-timer       :which-key "char timer")
    "j w" '(avy-goto-word-1           :which-key "word")
    "j l" '(avy-goto-line             :which-key "line")

    ;; Project Commands
    "p"   '(:ignore t                 :which-key "project")
    "p p" '(project-switch-project    :which-key "switch")
    "p f" '(project-find-file         :which-key "find file")
    "p g" '(project-find-regexp       :which-key "grep")
    "p d" '(project-dired             :which-key "dired")
    "p s" '(project-shell             :which-key "shell")
    "p e" '(project-eshell            :which-key "eshell")
    "p k" '(project-kill-buffers      :which-key "kill buffers")

    ;; Git Commands 
    "g"   '(:ignore t                 :which-key "git")
    "g g" '(magit-status              :which-key "status")
    "g b" '(magit-blame               :which-key "blame")
    "g l" '(magit-log-current         :which-key "log")
    "g d" '(magit-diff-buffer-file    :which-key "diff file")
    "g c" '(magit-clone               :which-key "clone")
    "g f" '(magit-find-file           :which-key "find revision")
    "g t" '(git-timemachine           :which-key "timemachine")
    "g h" '(hydra-git-hunk/body       :which-key "hunks…")

    ;; Searching With Consult
    "s"   '(:ignore t                 :which-key "search")
    "s s" '(consult-line              :which-key "line")
    "s g" '(consult-grep              :which-key "grep")
    "s f" '(consult-find              :which-key "search files")
    "s b" '(consult-bookmark          :which-key "search bookmarks")
    "s r" '(consult-ripgrep           :which-key "ripgrep")
    "s i" '(consult-imenu             :which-key "imenu")
    "s p" '(project-find-regexp       :which-key "in project")

    ;; Org Commands
    "o"   '(:ignore t                    :which-key "org / life")

    ;; Capture/Process
    "o c" '(org-capture                  :which-key "capture…")
    "o i" '(my/org-process-inbox         :which-key "process inbox")
    "o R" '(org-refile                   :which-key "refile…")
    "o S" '(my/org-refile-to-someday     :which-key "→ someday")
    "o A" '(org-archive-subtree          :which-key "archive")
    "o x" '(my/org-archive-done-items    :which-key "archive done")


    ;; Org Agenda Views
    "o a" '(org-agenda                  :which-key "agenda…")
    "o d" '((lambda () (interactive)
              (org-agenda nil "d"))
            :which-key "dashboard")
    "o w" '((lambda () (interactive)
              (org-agenda nil "w"))
            :which-key "weekly review")
    "o n" '((lambda () (interactive)
              (org-agenda nil "n"))
            :which-key "next actions")
    "o r" '((lambda () (interactive)
              (org-agenda nil "r"))
            :which-key "review queue")
    "o W" '((lambda () (interactive)
              (org-agenda nil "W"))
            :which-key "waiting")
    "o q" '((lambda () (interactive)
              (org-agenda nil "q"))
            :which-key "questions")
    "o p" '((lambda () (interactive)
              (org-agenda nil "p"))
            :which-key "projects")


    ;; School
    "o e" '((lambda () (interactive)
              (org-agenda nil "x"))
            :which-key "exams")
    "o f" '((lambda () (interactive)
              (org-agenda nil "a"))
            :which-key "assignments")

    ;; Context views
    "o C" '(:ignore t                    :which-key "contexts")
    "o C h" '((lambda () (interactive)
                (org-agenda nil "ch"))
              :which-key "@home")
    "o C c" '((lambda () (interactive)
                (org-agenda nil "cc"))
              :which-key "@campus")
    "o C o" '((lambda () (interactive)
                (org-agenda nil "co"))
              :which-key "@computer")
    "o C l" '((lambda () (interactive)
                (org-agenda nil "cl"))
              :which-key "@lab")
    "o C e" '((lambda () (interactive)
                (org-agenda nil "ce"))
              :which-key "@errand")
    "o C p" '((lambda () (interactive)
                (org-agenda nil "cp"))
              :which-key "@phone")

    ;; "O C n" ' (:ignore t :which-key "nutrition")
    ;; "f" '((lambda () (interactive)
    ;; 	    (my/nutrition-new-food))
    ;; 	    :which-key "new food")
    ;; "r" #'my/nutrition-new-recipe
    ;; "a" ((lambda () (interactive)
    ;; 	   ('my/nutrition-add-ingredient))
    ;; 	 :which-key "nutrition-add-ingredient")
    ;; "l" ((lambda () (interactive)
    ;; 	   ('my/nutrition-log))
    ;; 	 :which-key "my/nutrition-log")
    ;; "d" ((lambda () (interactive)
    ;; 	   ('my/nutrition-dashboard))
    ;; 	 :which-key "my/nutrition-dashboard")
    ;; "w" ((lambda () (interactive)
    ;; 	   ('my/nutrition-week))
    ;; 	 :which-key "my/nutrition-week")
    ;; "s" ((lambda () (interactive)
    ;; 	   ('my/nutrition-search))
    ;; 	 :which-key "my/nutrition-search")
    ;; "e" ((lambda () (interactive)
    ;; 	   ('my/nutrition-edit-food))
    ;; 	 :which-key "nutrition-edit-food")
    ;; "R" ((lambda () (interactive)
    ;; 	   ('my/nutrition-refresh))
    ;; 	 :which-key "my/nutrition-refresh")
    ;; "o" ((lambda () (interactive)
    ;; 	   ('my/nutrition-open))
    ;; 	 :which-key "my/nutrition-open")
    

    ;; Task Management
    "o t" '(org-todo                     :which-key "todo state")
    "o s" '(org-schedule                 :which-key "schedule")
    "o D" '(org-deadline                 :which-key "deadline")
    "o E" '(org-set-effort                :which-key "set effort")
    "o g" '(hydra-org-nav/body            :which-key "navigate…")
    "o T" '(hydra-org-table/body          :which-key "table…")

    ;; Org Ql Commands
    "o Q" '((lambda () (interactive)
              (org-agenda nil "q"))
            :which-key "questions")
    "o V" '(org-ql-search                :which-key "QL search…")

    ;; Org Denote Commands 
    "o N" '(denote                      :which-key "new knowledge note")
    "o O" '(denote-open-or-create       :which-key "open/create note")
    "o L" '(denote-link                 :which-key "link note")
    "o B" '(denote-backlinks            :which-key "backlinks")
    "o G" '(denote-grep                 :which-key "grep notes")
    "o F" '(denote-dired                :which-key "browse notes")

    ;; Org Navigation
    "o j" '(org-goto                    :which-key "goto heading")
    "o l" '(org-store-link              :which-key "store link")
    "o b" '(org-switchb                 :which-key "switch org buffer")


    ;; Log/Clock
    "l"   '(:ignore t                      :which-key "log / clock")
    "l l" '(hydra-clock/body               :which-key "clock menu…")
    "l i" '(org-clock-in                   :which-key "clock in")
    "l o" '(org-clock-out                  :which-key "clock out")
    "l g" '(org-clock-goto                 :which-key "goto active")
    "l r" '(org-clock-report               :which-key "report")
    "l d" '(org-clock-display              :which-key "display totals")
    "l p" '(org-pomodoro                   :which-key "pomodoro")
    "l c" '(org-clock-cancel               :which-key "cancel clock")
    
    ;; Code Commands
    "c"   '(:ignore t                 :which-key "code")
    "c c" '(compile                   :which-key "compile")
    "c r" '(recompile                 :which-key "recompile")
    "c t" '(vterm                 :which-key "vterm")
    "c d" '(xref-find-definitions     :which-key "definition")
    "c D" '(xref-find-references      :which-key "references")
    "c f" '(eglot-format-buffer       :which-key "format")
    "c a" '(eglot-code-actions        :which-key "actions")
    "c e" '(my/toggle-eglot           :which-key "toggle LSP")
    "c p" '(my/insert-debug-print     :which-key "debug print")

    ;; Evaluation
    "e"   '(:ignore t                 :which-key "eval")
    "e e" '(eval-last-sexp            :which-key "last sexp")
    "e b" '(eval-buffer               :which-key "buffer")
    "e r" '(eval-region               :which-key "region")
    "e f" '(eval-defun                :which-key "defun")
    "e i" '(my/reload-init            :which-key "reload init")

    ;; "Ask Emacs For Help" Prot"
    "h"   '(:ignore t                 :which-key "help")
    "h k" '(describe-key              :which-key "key")
    "h t" '(mo-modal-tutor            :which-key "modal tutor")
    "h o" '(describe-symbol           :which-key "symbol")
    "h f" '(describe-function         :which-key "function")
    "h v" '(describe-variable         :which-key "variable")
    "h m" '(describe-mode             :which-key "mode")
    "h p" '(describe-package          :which-key "package")
    "h i" '(info                      :which-key "info")


    ;; Embark
    "a"   '(:ignore t                 :which-key "actions / embark")
    "a ." '(hydra-embark/body         :which-key "embark menu…")
    "a a" '(embark-act                :which-key "act")
    "a d" '(embark-dwim               :which-key "dwim")
    "a c" '(embark-collect            :which-key "collect")
    "a e" '(embark-export             :which-key "export")
    "a b" '(embark-bindings           :which-key "bindings")

    ;; Tabs
    "T"   '(hydra-tabs/body           :which-key "tabs…")

    ;; Toggle
    "t"   '(:ignore t                 :which-key "toggle")
    "t n" '(display-line-numbers-mode :which-key "line numbers")
    "t w" '(visual-line-mode          :which-key "word wrap")
    "t t" '(load-theme                :which-key "load theme")
    "t d" '(toggle-debug-on-error     :which-key "debug on error")

    ;; Elfeed
    "r"   '(:ignore t               :which-key "feeds")
    "r r" '(elfeed                  :which-key "open elfeed")
    "r u" '(elfeed-update           :which-key "update feeds")
    "r R" '(my/elfeed-mark-all-read :which-key "mark all read")

   ;; Quit/Reload
    "q"   '(:ignore t                 :which-key "quit")
    "q q" '(save-buffers-kill-terminal :which-key "quit emacs")
    "q r" '(my/reload-init             :which-key "reload config")))



(with-eval-after-load 'mo-health
  (add-to-list 'my/health-check-features 'keybindings t))

(provide 'keybindings)
;;; keybindings.el ends here
