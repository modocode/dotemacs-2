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

;; Sync exec-path from the Windows PATH environment variable.
;; Emacs launched from a shortcut/Start menu often inherits a stripped PATH
;; that omits user-level tools installed by WinGet, scoop, etc.
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

;; Org paths on network drive
(my/register-path 'org-dir   "N:/")
(my/register-path 'notes-dir "N:/")

(provide 'windows)
;;; windows.el ends here
