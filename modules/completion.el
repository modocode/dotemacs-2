;;; modules/completion.el --- Completion framework -*- lexical-binding: t; -*-
;;
;; Three-layer completion stack:
;;   1. vertico    — vertical minibuffer UI for M-x, find-file, etc.
;;   2. orderless  — fuzzy/flex matching style for both minibuffer and in-buffer
;;   3. corfu      — in-buffer popup for code completion (CAPF / Eglot)
;;
;; Supporting cast:
;;   marginalia    — adds annotations to minibuffer candidates (docstrings, sizes)
;;   consult       — enhanced search/navigation commands (consult-line, etc.)
;;   embark        — context actions on any minibuffer candidate or thing-at-point

;;; ── Vertico ─────────────────────────────────────────────────────────────────
;; Replaces the default vertical completion list with a clean, fast UI.
;; Pairs naturally with orderless and marginalia.

(use-package vertico
  :ensure t
  :demand t   ; must be active from the very first M-x
  :custom
  (vertico-cycle t)   ; wrap around at top/bottom of candidate list
  :config
  (vertico-mode 1))

;;; ── Orderless ───────────────────────────────────────────────────────────────
;; Changes the completion matching style so that space-separated tokens can
;; appear in ANY order in the candidate.  "find buf" matches "find-file-buffer".
;; Also used in corfu (via the eglot hook in lang-lsp.el) for code completion.

(use-package orderless
  :ensure t
  :demand t
  :custom
  ;; Split on spaces OR dashes so "foo bar" matches "foo-bar-baz"
  (orderless-component-separator "[ -]")
  (completion-styles '(orderless basic))
  ;; orderless-prefixes: each token matches the START of a dash/slash-separated
  ;; word component — "tab g" → "tab-group", "foo b" → "foo-bar-baz"
  ;; orderless-flex: "tgrp" fuzzy-matches "tab-group" as a last resort
  (orderless-matching-styles
   '(orderless-prefixes   ; "tab g"  → matches "tab-group"
     orderless-literal    ; "group"  → exact substring anywhere
     orderless-flex))     ; "tgrp"   → fuzzy fallback
  ;; Case insensitive everywhere
  (completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  ;; Category overrides:
  ;;   command — explicit so Emacs' own category defaults can't shadow orderless
  ;;   file    — keep basic + partial-completion for path expansion ("~/Doc/pr")
  (completion-category-overrides
   '((command (styles orderless basic))
     (file    (styles basic partial-completion)))))
;;; ── Marginalia ──────────────────────────────────────────────────────────────
;; Adds helpful annotations to minibuffer candidates: function docstrings for
;; M-x, file sizes for find-file, key bindings for describe-function, etc.

(use-package marginalia
  :ensure t
  :demand t
  :config
  (marginalia-mode 1))

;;; ── Consult ─────────────────────────────────────────────────────────────────
;; Provides enhanced commands that replace or complement built-ins:
;;   consult-line     → better isearch (live preview)
;;   consult-buffer   → better C-x b (groups by type)
;;   consult-grep     → grep with live preview
;;   consult-imenu    → jump to definition in file
;;
;; Deliberately minimal keybinds here — add more in a dedicated bindings module.

(use-package consult
  :ensure t
  :bind
  (("C-s"   . consult-line)       ; replaces isearch-forward
   ("C-x b" . consult-buffer)     ; replaces switch-to-buffer
   ("M-s g" . consult-grep)
   ("M-g i" . consult-imenu)))

;;; ── Corfu ───────────────────────────────────────────────────────────────────
;; In-buffer popup completion that reads from `completion-at-point-functions'
;; (CAPF).  Eglot, elisp-completion, yasnippet, and others all populate CAPF,
;; so corfu provides completion for all of them with one configuration.
;;
;; corfu deliberately replaces company-mode and auto-complete — do NOT enable
;; either of those alongside it.

(use-package corfu
  :ensure t
  :demand t   ; must be active when Eglot starts, so load immediately
  :custom
  (corfu-auto          t)     ; show popup automatically without pressing TAB
  (corfu-auto-delay    0.2)   ; seconds before popup appears
  (corfu-auto-prefix   2)     ; minimum characters before auto-popup shows
  (corfu-cycle         t)     ; wrap around candidate list
  (corfu-quit-no-match t)     ; hide popup when no candidates match
  (corfu-preselect     'prompt) ; don't auto-select first candidate
  :bind
  (:map corfu-map
        ;; Use TAB/S-TAB to navigate the popup, not just RET.
        ;; This avoids conflicting with yasnippet's TAB expansion.
        ("TAB"     . corfu-next)
        ([tab]     . corfu-next)
        ("S-TAB"   . corfu-previous)
        ([backtab] . corfu-previous))
  :config
  (global-corfu-mode 1))

;;; ── Embark ──────────────────────────────────────────────────────────────────
;; Provides a context menu of actions on ANY candidate or object at point.
;; Think of it as a right-click menu for the keyboard:
;;   C-, on a buffer name in vertico → options to kill, rename, etc.
;;   C-, on a symbol in code         → options to describe, jump to, grep for
;;
;; M-k in the minibuffer is bound to kill (yank) the current candidate —
;; useful for grabbing file paths from find-file into the kill ring.

(use-package embark
  :ensure t
  :bind
  (("C-,"   . embark-act)
   ("C-M-," . embark-dwim)
   ("C-h B" . embark-bindings))
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; embark-consult wires consult's previews into Embark collect buffers.
;; Must load after both embark and consult.
(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))


;;; Bookmarks
(keymap-set bookmark-bmenu-mode-map "C-o" #'casual-bookmarks-tmenu)

(provide 'completion-config)
;;; completion.el ends here
