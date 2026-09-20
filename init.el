;;; init.el --- Main entry point -*- lexical-binding: t; -*-

;; Prefer edited source over stale bytecode, including modal backend changes.
(setq load-prefer-newer t)

(defvar my/emacs-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Absolute path to the directory containing init.el.
All load-path entries and file lookups use this instead of
`user-emacs-directory' to stay correct across any launch method.")

(setq custom-file (expand-file-name "var/custom.el" my/emacs-dir))
(load custom-file 'noerror)

(defvar my/is-mac     (eq   system-type 'darwin))
(defvar my/is-linux   (eq   system-type 'gnu/linux))
(defvar my/is-windows (memq system-type '(ms-dos windows-nt cygwin)))

(defvar my/system-config-path
  (cond
   (my/is-mac     (expand-file-name "os/macos.el"   my/emacs-dir))
   (my/is-linux   (expand-file-name "os/linux.el"   my/emacs-dir))
   (my/is-windows (expand-file-name "os/windows.el" my/emacs-dir)))
)
(add-to-list 'load-path (expand-file-name "core"    my/emacs-dir))
(add-to-list 'load-path (expand-file-name "modules" my/emacs-dir))
(add-to-list 'load-path (expand-file-name "os"      my/emacs-dir))
(add-to-list 'load-path (expand-file-name "mo-lisp" my/emacs-dir))

;; Define the backend before any auto-loaded module can activate it.
(require 'mo-modal)
(require 'mo-paths)
(require 'mo-helpers)
(require 'mo-health)
(require 'core-packages)
(require 'core-lib)
(require 'core-ui)


;; Xah-fly-keys enable

;;(require 'xah-fly-keys)

;; ;; specify a layout. optional
;; (xah-fly-keys-set-layout "qwerty")

;; (xah-fly-keys 1)

(global-auto-revert-mode 1)


(defun my/load-directory (dir)
  "Load every .el file found in DIR.

Errors inside individual files are caught with `condition-case' and printed
as messages — a broken module will NOT abort the rest of Emacs startup.

Use this for drop-in directories: drop a .el file in, restart Emacs, done."
  (when (file-directory-p dir)
    (mapc
     (lambda (file)
       (condition-case err
           (load file nil 'nomessage)   ; nil = no 'missing' error; nomessage = quiet
         (error
          (message "[my/load-directory] Skipping '%s': %s"
                   (file-name-nondirectory file)
                   (error-message-string err)))))
     ;; Sorted alphabetically — order matters: keybindings.el (k) must load
     ;; before any module that calls my/leader (e.g. nix-config.el, n).
     (directory-files dir t "\\.el$"))))

;; Scan and load every file in modules/
;; To add a new plugin: create modules/my-plugin.el.
(my/load-directory (expand-file-name "modules" my/emacs-dir))

(elpaca-wait)
;;(load-theme 'modus-operandi-tinted t)

(when (and my/system-config-path
           (file-exists-p my/system-config-path))
  (condition-case err
      (load my/system-config-path nil 'nomessage)
    (error
     (message "[init] Could not load OS config '%s': %s"
              my/system-config-path
              (error-message-string err)))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)   ; 16 MB
                  gc-cons-percentage 0.1)
            (message "Emacs ready in %.2f seconds with %d GCs."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

;; Passive health monitoring: runs after every startup, opens the report
;; buffer only when something fails.  Flip to nil to silence it.
(add-hook 'emacs-startup-hook #'my/health-check-auto)
