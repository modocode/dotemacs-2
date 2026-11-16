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
(load-theme 'wombat)
(my/register-font 'default  "SFMono Nerd Font"   120)  ; base/monospace face
(my/register-font 'fixed    "SFMono Nerd Font"   120)  ; code & inline code blocks
(my/register-font 'variable "Inconsolata"       130)  ; prose in Org/text buffers

;; (my/set-font "Inconsolata" 130)
;; A long-running daemon can retain display names from an old session.
(require 'browse-url)

(defun my/browser-session-environment ()
  "Return browser environment with current systemd desktop display settings."
  (let ((process-environment (copy-sequence (browse-url-process-environment))))
    (when (executable-find "systemctl")
      (dolist (entry (condition-case nil
                        (process-lines "systemctl" "--user" "show-environment")
                      (error nil)))
        (when (string-match
               "\\`\\(DISPLAY\\|WAYLAND_DISPLAY\\|XDG_CURRENT_DESKTOP\\|XDG_SESSION_TYPE\\)=\\(.*\\)\\'"
               entry)
          (setenv (match-string 1 entry) (match-string 2 entry)))))
    process-environment))

(defun my/browse-url-linux (url &optional _new-window)
  "Open URL in a new Zen tab using current session display settings."
  (let ((process-environment (my/browser-session-environment)))
    (start-process "zen-browser" "*Browser launch*" "zen" "--new-tab" url)))

(function-put 'my/browse-url-linux 'browse-url-browser-kind 'external)

(setq browse-url-browser-function #'my/browse-url-linux)

(provide 'linux)
;;; linux.el ends here
