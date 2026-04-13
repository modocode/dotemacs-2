;;; init.el --- Main entry point -*- lexical-binding: t; -*-

;;; ── Config Directory ────────────────────────────────────────────────────────
;; Derive the root of THIS config from `load-file-name' — the path of the file
;; currently being loaded by Emacs.  This is always correct regardless of how
;; Emacs was invoked (--init-directory, a wrapper ~/.emacs, symlink, etc.).
;;
;; WHY NOT `user-emacs-directory'?
;; If Emacs starts from a default ~/.emacs.d/init.el that then loads THIS
;; file, `user-emacs-directory' stays as ~/.emacs.d/ — meaning every
;; (expand-file-name "mo-lisp" user-emacs-directory) would silently point
;; at the wrong directory and `require' would fail with "no such file".
;;
;; `load-file-name' is bound by Emacs to the file being loaded right now,
;; so it always gives us the true parent directory of this init.el.
(defvar my/emacs-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Absolute path to the directory containing init.el.
All load-path entries and file lookups use this instead of
`user-emacs-directory' to stay correct across any launch method.")

;; Redirect Custom's auto-generated code away from init.el so it never
;; pollutes version-controlled source.  Must be set before any package
;; writes to it (i.e. before modules and os/ files load).
(setq custom-file (expand-file-name "var/custom.el" my/emacs-dir))
(load custom-file 'noerror)

;;; ── OS Detection ────────────────────────────────────────────────────────────
;; Three simple boolean variables you can test anywhere in your config with
;; `when my/is-mac' etc.
(defvar my/is-mac     (eq   system-type 'darwin))
(defvar my/is-linux   (eq   system-type 'gnu/linux))
(defvar my/is-windows (memq system-type '(ms-dos windows-nt cygwin)))

;; `my/system-config-path' holds the absolute path to ONE file that will be
;; loaded later.  Only that file runs; the others are never touched.
(defvar my/system-config-path
  (cond
   (my/is-mac     (expand-file-name "os/macos.el"   my/emacs-dir))
   (my/is-linux   (expand-file-name "os/linux.el"   my/emacs-dir))
   (my/is-windows (expand-file-name "os/windows.el" my/emacs-dir)))
  "Absolute path to the OS-specific config file for the current machine.
Use `C-h v my/system-config-path RET' to verify which file was selected.")

;;; ── Load-path Setup ─────────────────────────────────────────────────────────
;; Tell Emacs where to find features we `require'.
(add-to-list 'load-path (expand-file-name "core"    my/emacs-dir))
(add-to-list 'load-path (expand-file-name "modules" my/emacs-dir))
(add-to-list 'load-path (expand-file-name "os"      my/emacs-dir))
(add-to-list 'load-path (expand-file-name "mo-lisp" my/emacs-dir))

;;; ── Core Files (explicit, ordered) ─────────────────────────────────────────
;; These are loaded manually because ORDER matters:
;;   1. mo-paths       — path registry (os/ files need this to call my/register-path)
;;   2. mo-helpers     — interactive utility functions (lang modules use my/find-project-root)
;;   3. mo-health      — health check system (loaded before packages so it works even if elpaca fails)
;;   4. core-packages  — bootstraps elpaca + use-package (everything else needs this)
;;   5. core-lib       — helper macros/functions (modules may use these)
;;   6. core-ui        — visual baseline (fonts, theme)
;;
;; NOTE: `require' takes the FEATURE SYMBOL, not the filename.
;;       The symbol must match what the file calls (provide 'SYMBOL).
;;       Never pass a symbol with the .el extension.
(require 'mo-paths)
(require 'mo-helpers)
(require 'mo-health)
(require 'core-packages)
(require 'core-lib)
(require 'core-ui)

;;; ── Auto-Loader ─────────────────────────────────────────────────────────────
;;
;; HOW `directory-files' WORKS
;; ───────────────────────────
;; (directory-files DIR FULL MATCH NOSORT)
;;
;;   DIR    — path to the directory to scan
;;   FULL   — when t, returns absolute paths; when nil, bare filenames
;;   MATCH  — a regexp; only entries whose names match are included.
;;            "\\.el$" means "ends with .el" (the \\ escapes the dot in ELisp
;;            string literals so it means a literal dot, not "any character")
;;   NOSORT — when t, skips sorting the results (saves a tiny amount of time)
;;
;; Example return value on a directory containing foo.el and bar.el:
;;   ("/home/user/.emacs.d/modules/bar.el"
;;    "/home/user/.emacs.d/modules/foo.el")
;;
;; HOW `mapc' WORKS
;; ────────────────
;; (mapc FUNCTION LIST)
;;
;; Applies FUNCTION to each element of LIST in sequence.  Unlike `mapcar',
;; it discards the return values — we use it purely for the side-effect of
;; loading each file.  Think of it as a `dolist' that takes a lambda.
;;
;; HOW `condition-case' WORKS
;; ──────────────────────────
;; (condition-case VAR BODYFORM (ERROR-SYMBOL HANDLER))
;;
;; Evaluates BODYFORM.  If it signals an error, VAR is bound to the error
;; object and HANDLER runs instead of propagating the error.  This is
;; Emacs Lisp's try/catch.  Using `error' as the symbol catches ALL errors.
;;
;; CHECKING IF A MODULE LOADED
;; ───────────────────────────
;; Every module calls (provide 'feature-name) at the bottom.  Emacs adds
;; that symbol to the list `features'.
;;
;;   C-h v features RET   — shows every currently-loaded feature
;;
;; You can also evaluate:
;;   (featurep 'ui-tweaks)   → t if modules/ui-tweaks.el was loaded OK

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
;; To add a new plugin: create modules/my-plugin.el — that's it.
(my/load-directory (expand-file-name "modules" my/emacs-dir))

;; Wait for elpaca to activate all queued packages (including modus-themes)
;; before loading the default theme.  Without this, load-theme fires before
;; elpaca activates its managed modus-themes build and pulls in the stale
;; built-in copy instead.
(elpaca-wait)
(load-theme 'modus-operandi-tinted t)

;;; ── OS-Specific Config ──────────────────────────────────────────────────────
;; Load exactly ONE file based on `my/system-config-path' set above.
;; The file is optional — if it doesn't exist yet, we silently skip it.
(when (and my/system-config-path
           (file-exists-p my/system-config-path))
  (condition-case err
      (load my/system-config-path nil 'nomessage)
    (error
     (message "[init] Could not load OS config '%s': %s"
              my/system-config-path
              (error-message-string err)))))

;;; ── Post-init GC Reset ──────────────────────────────────────────────────────
;; early-init.el set gc-cons-threshold to the maximum to speed up loading.
;; Now that init is done we restore a balanced value (16 MB) so normal
;; interactive use doesn't accumulate garbage for too long.
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
