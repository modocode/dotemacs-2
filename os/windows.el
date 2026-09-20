;;; os/windows.el --- Windows-specific configuration -*- lexical-binding: t; -*-
;;

;; (prefer-coding-system 'utf-8-unix)

(setq ring-bell-function #'ignore)

;; Start find-file from home, not the Emacs install directory.
(setq default-directory (expand-file-name "~/"))

;; Sync exec-path from the Windows PATH environment variable.
;; emacs launched from a shortcut/Start menu often inherits a stripped PATH

(dolist (dir (split-string (or (getenv "PATH") "") ";"))
  (when (and (not (string-empty-p dir)) (file-directory-p dir))
    (add-to-list 'exec-path dir)))

;; zig and zls — winget installs them in version-named folders that are not
;; automatically added to PATH.  Register both explicitly.
(dolist (dir
         (list (expand-file-name
                "AppData/Local/Microsoft/WinGet/Packages/zigtools.zls_Microsoft.Winget.Source_8wekyb3d8bbwe"
                "~")
               (expand-file-name
                "AppData/Local/Microsoft/WinGet/Packages/zig.zig_Microsoft.Winget.Source_8wekyb3d8bbwe/zig-x86_64-windows-0.15.2"
                "~")))
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir)
    (setenv "PATH" (concat dir ";" (getenv "PATH")))))

;; caps Lock is remapped to right alt at the os level (registry scancode map or sharpkeys).
;; treat right alt as meta so caps lock = meta in emacs.
;; left alt is freed so glazewm can own it without conflict.
(setq w32-ralt-modifier 'meta
      w32-lalt-modifier  nil)

;; Windows uses "python" not "python3"
(setq python-shell-interpreter "python")

;; Add python root and scripts dirs to exec-path and PATH.
(dolist (candidate
         (list (expand-file-name "AppData/Local/Programs/Python/Python313"         "~")
               (expand-file-name "AppData/Local/Programs/Python/Python313/Scripts" "~")
               (expand-file-name "AppData/Local/Programs/Python/Python312"         "~")
               (expand-file-name "AppData/Local/Programs/Python/Python312/Scripts" "~")
               (expand-file-name "AppData/Local/Programs/Python/Python311"         "~")
               (expand-file-name "AppData/Local/Programs/Python/Python311/Scripts" "~")
               (expand-file-name "AppData/Roaming/Python/Python313/Scripts"        "~")
               (expand-file-name "AppData/Roaming/Python/Python312/Scripts"        "~")
               (expand-file-name "AppData/Roaming/Python/Python311/Scripts"        "~")))
  (when (file-directory-p candidate)
    (add-to-list 'exec-path candidate)
    (setenv "PATH" (concat candidate ";" (getenv "PATH")))))

;; Org paths on network drive
(my/register-path 'org-dir    "N:/")
(my/register-path 'notes-dir  "N:/notes/")
(my/register-path 'career-dir "N:/career/")


;; Fonts for this machine.
(my/register-font 'default  "Inconsolata"   110)  ; base/monospace face
(my/register-font 'fixed    "Inconsolata"   110)  ; code & inline code blocks
(my/register-font 'variable "ETBembo"       130)  ; prose in Org/text buffers

(provide 'windows)
;;; windows.el ends here
