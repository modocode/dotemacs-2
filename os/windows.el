;;; os/windows.el --- Windows-specific configuration -*- lexical-binding: t; -*-
;;
;; Loaded automatically on Windows (ms-dos, windows-nt, cygwin) by init.el.
;; Put anything Windows-specific here: font adjustments for ClearType,
;; registry path workarounds, WSL integration, etc.

;; Example: ensure UTF-8 even though Windows defaults to CP-1252
;; (prefer-coding-system 'utf-8-unix)

(setq ring-bell-function #'ignore)

;; Start find-file from home, not the Emacs install directory.
(setq default-directory (expand-file-name "~/"))

;; Defer theme loading until elpaca has finished building all packages.
;; Calling load-theme here directly fails on first run because gruvbox-theme
;; hasn't been installed yet when os/windows.el loads.
(add-hook 'elpaca-after-init-hook (lambda () (load-theme 'gruvbox t)))

;; Sync exec-path from the Windows PATH environment variable.
;; Emacs launched from a shortcut/Start menu often inherits a stripped PATH

(dolist (dir (split-string (or (getenv "PATH") "") ";"))
  (when (and (not (string-empty-p dir)) (file-directory-p dir))
    (add-to-list 'exec-path dir)))

;; zig and zls — WinGet installs them in version-named folders that are not
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

;; Caps Lock is remapped to Right Alt at the OS level (registry scancode map or SharpKeys).
;; Treat Right Alt as Meta so Caps Lock = Meta in Emacs.
;; Left Alt is freed so GlazeWM can own it without conflict.
(setq w32-ralt-modifier 'meta
      w32-lalt-modifier  nil)

;; Windows uses "python" not "python3"
(setq python-shell-interpreter "python")

;; Add Python root and Scripts dirs to exec-path and PATH.
;; Root dir  → python.exe  (pyright needs this to resolve imports / type stubs)
;; Scripts/  → pyright-langserver.exe, pip.exe, etc.
;; Without the root on PATH, pyright finds pyright-langserver but then
;; crashes immediately (status 1) because it can't locate python.exe.
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
(my/register-path 'org-dir   "N:/")
(my/register-path 'notes-dir "N:/")


;; Fonts for this machine.
;; Change any of these if you install a different font and want to use it here.
(my/register-font 'default  "Inconsolata"   110)  ; base/monospace face
(my/register-font 'fixed    "Inconsolata"   110)  ; code & inline code blocks
(my/register-font 'variable "ETBembo"       130)  ; prose in Org/text buffers

(provide 'windows)
;;; windows.el ends here
