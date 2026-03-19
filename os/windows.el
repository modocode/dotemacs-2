;;; os/windows.el --- Windows-specific configuration -*- lexical-binding: t; -*-
;;
;; Loaded automatically on Windows (ms-dos, windows-nt, cygwin) by init.el.
;; Put anything Windows-specific here: font adjustments for ClearType,
;; registry path workarounds, WSL integration, etc.

;; Example: ensure UTF-8 even though Windows defaults to CP-1252
;; (prefer-coding-system 'utf-8-unix)

(setq ring-bell-function #'ignore)

;; Org paths on network drive
(my/register-path 'org-dir   "N:/")
(my/register-path 'notes-dir "N:/")

(provide 'windows)
;;; windows.el ends here
