;;; modules/keybindings.el --- Leader keybindings and hydra UIs -*- lexical-binding: t; -*-
;;
;; which-key is configured in ui-tweaks.el — it must already be running by the
;; time this file loads (modules/ is loaded alphabetically, k < u, so which-key
;; will not yet be active).  That's fine — general.el attaches :which-key
;; annotations at definition time; which-key reads them whenever it renders.

;;; ── Hydras ───────────────────────────────────────────────────────────────────
;; Hydras are transient keymaps that stay active until you press the quit key.
;; Perfect for repetitive operations (resize a window several times, zoom in/out)
;; without re-pressing the full prefix each time.

(use-package hydra
  :ensure t
  :demand t
  :config

  ;; ── Window Resize ─────────────────────────────────────────────────────────
  ;; SPC w r — stay in the hydra, tap h/j/k/l repeatedly to resize.
  (defhydra hydra-window-resize (:hint nil)
    "
  Window Resize
  _h_ shrink ←   _l_ grow →
  _j_ shrink ↓   _k_ grow ↑
  _=_ balance    _q_ done
"
    ("h" shrink-window-horizontally)
    ("l" enlarge-window-horizontally)
    ("j" shrink-window)
    ("k" enlarge-window)
    ("=" balance-windows)
    ("q" nil :exit t))

  ;; ── Text Scale ────────────────────────────────────────────────────────────
  ;; SPC w z — zoom the current buffer's text up/down without affecting others.
  (defhydra hydra-text-scale (:hint nil)
    "
  Text Zoom
  _+_ larger   _-_ smaller   _0_ reset   _q_ done
"
    ("+" text-scale-increase)
    ("-" text-scale-decrease)
    ("0" (text-scale-set 0) :exit t)
    ("q" nil :exit t))

  ;; ── Git Hunks ─────────────────────────────────────────────────────────────
  ;; SPC g h — navigate and act on diff-hl hunks without opening magit.
  ;; Useful for quickly staging individual changes while staying in the buffer.
  (defhydra hydra-git-hunk (:hint nil)
    "
  Git Hunks
  _n_ next   _p_ prev   _s_ stage   _r_ revert   _d_ show   _q_ done
"
    ("n" diff-hl-next-hunk)
    ("p" diff-hl-previous-hunk)
    ("s" diff-hl-stage-current-hunk)
    ("r" diff-hl-revert-hunk)
    ("d" diff-hl-show-hunk)
    ("q" nil :exit t)))

;;; ── General ──────────────────────────────────────────────────────────────────
;; general.el is the standard way to define evil leader bindings.
;; We use SPC as the leader in normal/visual/motion states, and M-SPC
;; as the global-prefix so the same bindings work in insert and emacs states.

(use-package general
  :ensure t
  :demand t
  :config
  (general-evil-setup)

  ;; SPC leader — active in normal, visual, and motion states.
  (general-create-definer my/leader
    :states  '(normal visual motion emacs)
    :keymaps 'override
    :prefix  "SPC"
    :global-prefix "M-SPC")

  ;; SPC m local leader — for mode-specific bindings added in other modules.
  ;; Example: (my/local-leader :keymaps 'python-mode-map "r" #'run-python)
  (general-create-definer my/local-leader
    :states  '(normal visual motion emacs)
    :keymaps 'override
    :prefix  "SPC m"
    :global-prefix "M-SPC m")

  ;; Enable recentf so SPC f r works.
  (recentf-mode 1)

  (my/leader

    ;; ── Top-level ────────────────────────────────────────────────────────────
    "SPC" '(execute-extended-command :which-key "M-x")
    ":"   '(eval-expression           :which-key "eval expr")
    ";"   '(comment-dwim              :which-key "comment")
    "X"   '(my/health-check           :which-key "health check")

    ;; ── Buffers (b) ──────────────────────────────────────────────────────────
    "b"   '(:ignore t                 :which-key "buffer")
    "b b" '(consult-buffer            :which-key "switch")
    "b k" '(kill-current-buffer       :which-key "kill")
    "b K" '(my/kill-other-buffers     :which-key "kill others")
    "b n" '(next-buffer               :which-key "next")
    "b p" '(previous-buffer           :which-key "prev")
    "b r" '(revert-buffer             :which-key "revert")
    "b s" '(save-buffer               :which-key "save")

    ;; ── Files (f) ────────────────────────────────────────────────────────────
    "f"   '(:ignore t                 :which-key "file")
    "f f" '(find-file                 :which-key "find file")
    "f r" '(consult-recent-file       :which-key "recent files")
    "f s" '(save-buffer               :which-key "save")
    "f S" '(save-some-buffers         :which-key "save all")
    "f R" '(my/rename-file-and-buffer :which-key "rename")
    "f y" '(my/copy-buffer-path       :which-key "copy path")
    "f i" '(my/open-init              :which-key "open init.el")

    ;; ── Windows (w) ──────────────────────────────────────────────────────────
    "w"   '(:ignore t                 :which-key "window")
    "w v" '(split-window-right        :which-key "split right")
    "w s" '(split-window-below        :which-key "split below")
    "w d" '(delete-window             :which-key "delete")
    "w o" '(delete-other-windows      :which-key "only this")
    "w h" '(evil-window-left          :which-key "go ←")
    "w j" '(evil-window-down          :which-key "go ↓")
    "w k" '(evil-window-up            :which-key "go ↑")
    "w l" '(evil-window-right         :which-key "go →")
    "w a" '(ace-window                :which-key "ace jump")
    "w =" '(balance-windows           :which-key "balance")
    "w r" '(hydra-window-resize/body  :which-key "resize…")
    "w z" '(hydra-text-scale/body     :which-key "zoom…")

    ;; ── Jump (j) — avy ───────────────────────────────────────────────────────
    "j"   '(:ignore t                 :which-key "jump")
    "j j" '(avy-goto-char-timer       :which-key "char timer")
    "j w" '(avy-goto-word-1           :which-key "word")
    "j l" '(avy-goto-line             :which-key "line")

    ;; ── Projects (p) ─────────────────────────────────────────────────────────
    "p"   '(:ignore t                 :which-key "project")
    "p p" '(project-switch-project    :which-key "switch")
    "p f" '(project-find-file         :which-key "find file")
    "p g" '(project-find-regexp       :which-key "grep")
    "p d" '(project-dired             :which-key "dired")
    "p s" '(project-shell             :which-key "shell")
    "p e" '(project-eshell            :which-key "eshell")
    "p k" '(project-kill-buffers      :which-key "kill buffers")

    ;; ── Git (g) ──────────────────────────────────────────────────────────────
    "g"   '(:ignore t                 :which-key "git")
    "g g" '(magit-status              :which-key "status")
    "g b" '(magit-blame               :which-key "blame")
    "g l" '(magit-log-current         :which-key "log")
    "g d" '(magit-diff-buffer-file    :which-key "diff file")
    "g c" '(magit-clone               :which-key "clone")
    "g f" '(magit-find-file           :which-key "find revision")
    "g t" '(git-timemachine           :which-key "timemachine")
    "g h" '(hydra-git-hunk/body       :which-key "hunks…")

    ;; ── Search (s) ───────────────────────────────────────────────────────────
    "s"   '(:ignore t                 :which-key "search")
    "s s" '(consult-line              :which-key "line")
    "s g" '(consult-grep              :which-key "grep")
    "s r" '(consult-ripgrep           :which-key "ripgrep")
    "s i" '(consult-imenu             :which-key "imenu")
    "s p" '(project-find-regexp       :which-key "in project")

    ;; ── Org & Notes (o) ──────────────────────────────────────────────────────
    "o"   '(:ignore t                 :which-key "org / notes")
    "o a" '(org-agenda                :which-key "agenda")
    "o c" '(org-capture               :which-key "capture")
    "o t" '(org-todo                  :which-key "todo state")
    "o s" '(org-schedule              :which-key "schedule")
    "o d" '(org-deadline              :which-key "deadline")
    "o n" '(denote                    :which-key "new note")
    "o l" '(denote-link               :which-key "link note")
    "o b" '(denote-backlinks          :which-key "backlinks")

    ;; ── Code (c) ─────────────────────────────────────────────────────────────
    "c"   '(:ignore t                 :which-key "code")
    "c c" '(compile                   :which-key "compile")
    "c r" '(recompile                 :which-key "recompile")
    "c d" '(xref-find-definitions     :which-key "definition")
    "c D" '(xref-find-references      :which-key "references")
    "c f" '(eglot-format-buffer       :which-key "format")
    "c a" '(eglot-code-actions        :which-key "actions")
    "c e" '(my/toggle-eglot           :which-key "toggle LSP")
    "c p" '(my/insert-debug-print     :which-key "debug print")

    ;; ── Eval (e) ─────────────────────────────────────────────────────────────
    "e"   '(:ignore t                 :which-key "eval")
    "e e" '(eval-last-sexp            :which-key "last sexp")
    "e b" '(eval-buffer               :which-key "buffer")
    "e r" '(eval-region               :which-key "region")
    "e f" '(eval-defun                :which-key "defun")
    "e i" '(my/reload-init            :which-key "reload init")

    ;; ── Help (h) ─────────────────────────────────────────────────────────────
    "h"   '(:ignore t                 :which-key "help")
    "h k" '(describe-key              :which-key "key")
    "h f" '(describe-function         :which-key "function")
    "h v" '(describe-variable         :which-key "variable")
    "h m" '(describe-mode             :which-key "mode")
    "h p" '(describe-package          :which-key "package")
    "h i" '(info                      :which-key "info")

    ;; ── Toggle (t) ───────────────────────────────────────────────────────────
    "t"   '(:ignore t                 :which-key "toggle")
    "t n" '(display-line-numbers-mode :which-key "line numbers")
    "t w" '(visual-line-mode          :which-key "word wrap")
    "t t" '(load-theme                :which-key "load theme")
    "t d" '(toggle-debug-on-error     :which-key "debug on error")

    ;; ── Quit (q) ─────────────────────────────────────────────────────────────
    "q"   '(:ignore t                 :which-key "quit")
    "q q" '(save-buffers-kill-terminal :which-key "quit emacs")
    "q r" '(my/reload-init             :which-key "reload config")))

;;; ── Health registration ──────────────────────────────────────────────────────

(with-eval-after-load 'mo-health
  (add-to-list 'my/health-check-features 'keybindings t))

(provide 'keybindings)
;;; keybindings.el ends here
