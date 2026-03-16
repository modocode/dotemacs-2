;;; modules/ui-tweaks.el --- UI polish and quality-of-life tweaks -*- lexical-binding: t; -*-
;;
;; DROP-IN MODULE EXAMPLE
;; ──────────────────────
;; This file is loaded automatically by `my/load-directory' in init.el.
;; You don't need to touch init.el to activate or deactivate it:
;;
;;   Activate   → the file exists in modules/
;;   Deactivate → delete or rename the file, restart Emacs
;;
;; After loading, verify it with:
;;   M-x eval-expression RET (featurep 'ui-tweaks) RET  → should return t
;;   C-h v features RET                                  → look for 'ui-tweaks

;;; ── Line Numbers ────────────────────────────────────────────────────────────
;; Show relative line numbers in programming and config files.
;; `use-package emacs :ensure nil' is the idiomatic way to configure
;; built-in Emacs behaviour through use-package without installing anything.
(use-package emacs
  :ensure nil
  :custom
  (display-line-numbers-type 'relative)
  :hook
  (prog-mode . display-line-numbers-mode)
  (conf-mode . display-line-numbers-mode))

;;; ── which-key ───────────────────────────────────────────────────────────────
;; Displays a popup after a prefix key showing all available completions.
;; Example: press C-x and wait — a buffer listing all C-x … bindings appears.
;;
;; `:demand t' overrides the global `use-package-always-defer t' we set in
;; core-packages.el.  which-key needs to be active from the start so the popup
;; appears the very first time you press a prefix key.
(use-package which-key
  :ensure t
  :demand t
  :custom
  (which-key-idle-delay 0.4)           ; seconds before the popup appears
  (which-key-max-description-length 40)
  :config
  (which-key-mode 1))

;;; ── Example: guarded ripgrep integration ────────────────────────────────────
;; `my/with-binary' (defined in core-lib.el) checks for the `rg' executable
;; before even attempting to load the package.  Safe to leave in on machines
;; that don't have ripgrep — the block is simply skipped.
(my/with-binary "rg"
  (use-package rg
    :ensure t
    :bind ("C-c s" . rg-menu)))

;;; ── Better Built-in Minibuffer Completion ───────────────────────────────────
(use-package emacs
  :ensure nil
  :custom
  ;; `flex' scoring matches characters out-of-order (like VS Code's fuzzy find).
  ;; `basic' is the fallback for when flex produces no results.
  (completion-styles '(flex basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(provide 'ui-tweaks)
;;; ui-tweaks.el ends here
