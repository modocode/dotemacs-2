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

  :bind (:map vertico-mode
	      :map minibuffer-local-map
	      ("M-h" . backward-kill-word))

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
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)

  ;; File paths behave better with partial completion.
  (completion-category-overrides
   '((file (styles partial-completion))))

  ;; Keep default matching precise.
  (orderless-matching-styles
   '(orderless-literal
     orderless-regexp
     orderless-initialism
     orderless-prefixes))

  :config
  (defun my/orderless-dispatch (pattern _index _total)
    (cond
     ;; !foo  -> exclude foo
     ((string-prefix-p "!" pattern)
      `(orderless-without-literal . ,(substring pattern 1)))

     ;; foo=   -> literal
     ((string-suffix-p "=" pattern)
      `(orderless-literal . ,(substring pattern 0 -1)))

     ;; foo^   -> prefix
     ((string-suffix-p "^" pattern)
      `(orderless-prefixes . ,(substring pattern 0 -1)))

     ;; foo~   -> flex/fuzzy
     ((string-suffix-p "~" pattern)
      `(orderless-flex . ,(substring pattern 0 -1)))

     ;; foo%   -> regexp
     ((string-suffix-p "%" pattern)
      `(orderless-regexp . ,(substring pattern 0 -1)))))

  (setq orderless-style-dispatchers
        '(my/orderless-dispatch)))






(use-package marginalia
  :after vertico
  :ensure t
  :demand t
  :config
  (marginalia-mode 1))


(use-package consult
  :ensure t
  :bind
  (("C-s"   . consult-line)       ; replaces isearch-forward
   ("C-x b" . consult-buffer)     ; replaces switch-to-buffer
   ("M-s g" . consult-grep)
   ("M-g i" . consult-imenu)))

(use-package consult-dir
  :ensure t
  )

(my/bind-keys consult-dir vertico-map
  "C-x C-d" #'consult-dir
  "C-x C-j" #'consult-dir-jump-file
  )



(use-package consult-notes
  :ensure t
  :commands (consult-notes consult-notes-search-in-all-notes)
  :bind (("M-s n" . consult-notes)                       ; search notes by title
         ("M-s N" . consult-notes-search-in-all-notes))  ; full-text across notes
  :config
  ;; Reads denote-directory automatically (no second path to maintain)
  (consult-notes-denote-mode))

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
  (("C-,"   . embark-act)          ; act on thing at point / minibuffer candidate
   ("C-M-," . embark-dwim)         ; default action (jump to def, open file, etc.)
   ("C-h B" . embark-bindings)     ; describe all embark actions in a buffer
   ("C-c e" . embark-collect)      ; snapshot current candidates into a collect buffer
   ("C-c E" . embark-export))      ; export candidates to a specialised buffer (grep, dired…)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; embark-consult wires consult's previews into Embark collect buffers.
;; Must load after both embark and consult.
(use-package embark-consult
  :ensure t
  :after (embark consult)

)
  


;; (add-to-list 'vertico-multiform-categories '(embark-keybinding grid))
;; (vertico-multiform-mode)


(use-package vterm
  :commands vterm)

(provide 'completion-config)
;;; completion.el ends here
