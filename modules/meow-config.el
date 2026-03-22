;;; modules/meow-config.el --- Meow modal editing -*- lexical-binding: t; -*-
;;
;; Meow is a modal editing system designed for Emacs.
;; Keys are arranged ergonomically around QWERTY home row.
;; Loading this file triggers the with-eval-after-load 'meow callbacks
;; in keybindings.el, which applies the SPC leader to meow's state keymaps.

(defun my/meow-setup ()
  "Configure meow keybindings for QWERTY layout."
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)

  ;; Motion state — used in special buffers (magit, dired, etc.)
  ;; Override j/k so they move lines rather than trigger meow-next/prev hints.
  (meow-motion-define-key
   '("j" . meow-next)
   '("k" . meow-prev)
   '("<escape>" . ignore))

  ;; Normal state — the core editing keys.
  (meow-normal-define-key
   ;; Numeric expand (select progressively larger syntactic units)
   '("0" . meow-expand-0)
   '("1" . meow-expand-1)
   '("2" . meow-expand-2)
   '("3" . meow-expand-3)
   '("4" . meow-expand-4)
   '("5" . meow-expand-5)
   '("6" . meow-expand-6)
   '("7" . meow-expand-7)
   '("8" . meow-expand-8)
   '("9" . meow-expand-9)

   ;; Movement
   '("h" . meow-left)
   '("H" . meow-left-expand)
   '("j" . meow-next)
   '("J" . meow-next-expand)
   '("k" . meow-prev)
   '("K" . meow-prev-expand)
   '("l" . meow-right)
   '("L" . meow-right-expand)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("e" . meow-next-word)
   '("E" . meow-next-symbol)
   '("f" . meow-find)
   '("t" . meow-till)
   '("n" . meow-search)

   ;; Selection
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("w" . meow-mark-word)
   '("W" . meow-mark-symbol)
   '("x" . meow-line)
   '("X" . meow-goto-line)
   '("Q" . meow-goto-line)
   '("v" . meow-visit)
   '("z" . meow-pop-selection)
   '(";" . meow-reverse)
   '("g" . meow-cancel-selection)
   '("G" . meow-grab)
   '("Y" . meow-sync-grab)

   ;; Editing
   '("a" . meow-append)
   '("A" . meow-open-below)
   '("i" . meow-insert)
   '("I" . meow-open-above)
   '("o" . meow-open-below)
   '("O" . meow-open-above)
   '("c" . meow-change)
   '("d" . meow-delete)
   '("D" . meow-backward-delete)
   '("s" . meow-kill)
   '("r" . meow-replace)
   '("R" . meow-swap-grab)
   '("p" . meow-yank)
   '("y" . meow-save)
   '("m" . meow-join)
   '("u" . meow-undo)
   '("U" . meow-undo-in-selection)

   ;; Misc
   '("-" . negative-argument)
   '("q" . meow-quit)
   '("'" . repeat)
   '("<escape>" . ignore)))

(use-package meow
  :ensure t
  :demand t
  :config
  (my/meow-setup)
  (meow-global-mode 1))

;; Force meow to load synchronously so state keymaps and meow-global-mode
;; are active before the rest of init.el finishes.  Without this, elpaca
;; defers meow's activation to after-init-hook, which is too late for the
;; with-eval-after-load 'meow callbacks in keybindings.el to apply properly.
(elpaca-wait)

(provide 'meow-config)
;;; meow-config.el ends here
