;;; modules/elfeed-config.el --- RSS/Atom feed reader -*- lexical-binding: t; -*-
;;
;; Extensibility model:
;;   Add feeds by appending to `my/elfeed-feeds' in your os/*.el file:
;;
;;     (add-to-list 'my/elfeed-feeds '("https://example.com/feed.xml" blog tech))
;;
;; Each entry is either a plain URL string or a list (URL TAG TAG …).
;; Tags let you filter in the elfeed search buffer with, e.g.:  +tech -blog
;;
;; Keybindings (SPC r …):
;;   SPC r r — open elfeed search buffer
;;   SPC r u — fetch all feeds (elfeed-update)
;;   SPC r R — mark all visible entries read

;;; ── Feed registry ────────────────────────────────────────────────────────────
;; Defined before elpaca loads elfeed so os/*.el can safely call add-to-list
;; during the same early pass.

(defvar my/elfeed-feeds
  '(("https://hnrss.org/frontpage" hackernews tech))
  "Master feed list consumed by elfeed.
Each element is either a URL string or (URL TAG …).
Extend from os/*.el with add-to-list rather than setq so this
default list is not clobbered when you have multiple machines.")

;;; ── Top-level commands ───────────────────────────────────────────────────────
;; Defined here (not inside :config) so they are available immediately —
;; SPC r R and completion can find them without waiting for elfeed to load.

(defun my/elfeed-mark-all-read ()
  "Mark every entry currently visible in the elfeed search buffer as read."
  (interactive)
  (mark-whole-buffer)
  (elfeed-search-untag-all-unread))

;;; ── elfeed ───────────────────────────────────────────────────────────────────

(use-package elfeed
  :ensure t
  :defer t   ; opened on demand via SPC r r
  :init
  ;; Wire the registry into elfeed lazily: by the time elfeed actually loads,
  ;; os/*.el has already run and my/elfeed-feeds is fully populated.
  (add-hook 'elfeed-search-mode-hook
            (lambda () (setq elfeed-feeds my/elfeed-feeds)))
  :custom
  (elfeed-search-filter "@6-months-ago +unread") ; default view: recent unread
  (elfeed-db-directory (my/var-dir "elfeed/db/")))

;;; ── Keybindings ──────────────────────────────────────────────────────────────
;; SPC r bindings live in keybindings.el alongside all other leader keys.
;; See the "Feeds (r)" section there.

(provide 'elfeed-config)
;;; elfeed-config.el ends here
