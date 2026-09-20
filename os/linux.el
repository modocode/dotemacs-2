;;; os/linux.el --- Linux-specific configuration -*- lexical-binding: t; -*-
;;
;; Loaded automatically on GNU/Linux by init.el.
;;
; Path Overrides
;; (my/register-path 'org-dir   "~/Sync/org/")
;; (my/register-path 'notes-dir "~/Sync/notes/")
 (my/register-path 'org-dir   "~/org/")

;; Example: branch by hostname for two machines in one file
;; (pcase (system-name)
;;   ("work-laptop"
;;    (my/register-path 'org-dir "~/work/org/"))
;;   ("home-desktop"
;;    (my/register-path 'org-dir "~/personal/org/")))

; Font Overrides
;; (my/register-font 'default  "Inconsolata"    110)
;; (my/register-font 'fixed    "Inconsolata"    110)
;; (my/register-font 'variable "ETBembo"        130)
;;


;; (load-theme 'gruber-darker)
(load-theme 'naysayer)
(my/register-font 'default  "DejaVu Sans Mono"   110)  ; base/monospace face
(my/register-font 'fixed    "DejaVu Sans Mono"   110)  ; code & inline code blocks
(my/register-font 'variable "Inconsolata"       130)  ; prose in Org/text buffers


(provide 'linux)
;;; linux.el ends here
