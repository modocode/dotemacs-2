;;; core/core-packages.el --- Package manager bootstrap -*- lexical-binding: t; -*-
;;
;; Sets up elpaca as the package manager and integrates it with use-package.
;; Everything here must run BEFORE any module tries to install or configure
;; a package.

;;; ── 1. Bootstrap elpaca ─────────────────────────────────────────────────────
;; This block is the canonical elpaca installer.  On first run it clones
;; elpaca from GitHub and byte-compiles it.  On subsequent runs it just loads
;; the pre-compiled autoloads — takes milliseconds.

(defvar elpaca-installer-version 0.9)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory  (expand-file-name "repos/"  elpaca-directory))
(defvar elpaca-order
  '(elpaca :repo "https://github.com/progfolio/elpaca.git"
           :ref nil :depth 1
           :files (:defaults "elpaca-test.el" (:exclude "extensions"))
           :build (:not elpaca--activate-package)))

(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process
                                 `("git" nil ,buffer t "clone"
                                   ,@(when-let* ((depth (plist-get order :depth)))
                                       (list (format "--depth=%d" depth)
                                             "--no-single-branch"))
                                   ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;;; ── 2. Integrate elpaca with use-package ────────────────────────────────────
;; elpaca-use-package adds a `:ensure' keyword that routes package installs
;; through elpaca instead of package.el.

(elpaca elpaca-use-package
  (elpaca-use-package-mode))

;; Block here until elpaca finishes installing use-package support.
;; Everything after this point can safely call `use-package'.
(elpaca-wait)

;;; ── 3. No-Littering — redirect package clutter out of ~/.emacs.d/ ──────────
;; Must load BEFORE other packages so it intercepts their file-path variables.
;; All state/data files land in  var/   (e.g. var/recentf, var/savehist).
;; Config/settings files land in etc/   (e.g. etc/custom.el).
(use-package no-littering
  :ensure t
  :demand t
  :config
  ;; Redirect auto-save files — no-littering doesn't set this automatically.
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))

  ;; Keep backup files tidy as well.
  (setq backup-directory-alist
        `(("." . ,(no-littering-expand-var-file-name "backup/")))
        backup-by-copying  t   ; never clobber hard-links
        version-control    t   ; number backups
        kept-new-versions  6
        kept-old-versions  2
        delete-old-versions t))

(elpaca-wait) ; ensure no-littering is fully loaded before any module runs

;;; ── 4. Global use-package Defaults ─────────────────────────────────────────
;; `use-package-always-defer t' means every package is lazy-loaded by default.
;; You MUST explicitly add `:demand t' to any package that must be loaded at
;; startup (e.g. which-key, evil).
;;
;; Why defer everything?
;;   Emacs startup = sum of all loaded packages.  Deferring packages means they
;;   only load when first needed (a keybinding is pressed, a mode activates, a
;;   file is opened), keeping startup under ~300 ms even with 50+ packages.
(setq use-package-always-defer t)

;;; ── 5. Garbage-Collector Magic Hack (gcmh) ──────────────────────────────────
;; gcmh raises the GC threshold while Emacs is idle (between keystrokes) and
;; lowers it when Emacs is actively running Lisp. This gives you fast
;; interactive editing without long GC pauses during normal use.
(use-package gcmh
  :ensure t
  :demand t
  :config
  (gcmh-mode 1))

(provide 'core-packages)
;;; core-packages.el ends here
