;;; os/linux.el --- Linux-specific configuration -*- lexical-binding: t; -*-
;;
;; Loaded automatically on GNU/Linux by init.el.
;;
;; This is also the RIGHT PLACE to declare machine-specific paths using
;; `my/register-path' (defined in mo-lisp/mo-paths.el).  The defaults live
;; in mo-paths.el; override only what differs on THIS machine.
;;
;; If you have more than one Linux machine, commit this file with sensible
;; defaults and let each machine's local edits handle divergence — or use
;; (system-name) to branch by hostname inside this file (see example below).

;;; ── Path Overrides ──────────────────────────────────────────────────────────
;; Uncomment and edit the lines relevant to this machine.
;; `my/register-path' replaces the default value in the registry so that
;; (my/path 'org-dir) returns YOUR path wherever it's called.

;; (my/register-path 'org-dir   "~/org/")          ; already the default
;; (my/register-path 'notes-dir "~/notes/")        ; already the default

;; Example: Syncthing folder layout on a specific workstation
;; (my/register-path 'org-dir   "~/Sync/org/")
;; (my/register-path 'notes-dir "~/Sync/notes/")

;; Example: branch by hostname for two machines in one file
;; (pcase (system-name)
;;   ("work-laptop"
;;    (my/register-path 'org-dir "~/work/org/"))
;;   ("home-desktop"
;;    (my/register-path 'org-dir "~/personal/org/")))

;;; ── Display Tweaks ──────────────────────────────────────────────────────────
;; Example: increase font size for HiDPI displays
;; (when (display-graphic-p)
;;   (my/set-font "LigaSauceCodePro NF" 120))

(provide 'linux)
;;; linux.el ends here
