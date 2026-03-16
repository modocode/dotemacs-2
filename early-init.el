;;; early-init.el --- Pre-initialization settings -*- lexical-binding: t; -*-
;;
;; Emacs loads this file BEFORE the package system and the GUI frame are
;; initialized. That makes it the right place for:
;;   1. GC tuning (speeds up loading dramatically)
;;   2. Disabling GUI widgets (prevents the toolbar from flashing in)
;;   3. Frame geometry (maximized, no borders)
;;   4. Encoding defaults

;;; ── 1. GC Turbo-mode ────────────────────────────────────────────────────────
;; Raise the threshold to the maximum during startup so Emacs never pauses to
;; garbage-collect while loading files.  init.el resets this to a sane value
;; once Emacs is fully booted.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;;; ── 2. Prevent GUI Flicker ──────────────────────────────────────────────────
;; Setting these in `default-frame-alist' applies BEFORE the first frame is
;; drawn, so you never see a flash of the toolbar or scroll-bar.
(push '(menu-bar-lines . 0)     default-frame-alist)
(push '(tool-bar-lines . 0)     default-frame-alist)
(push '(vertical-scroll-bars)   default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)

;;; ── 3. Start maximized ──────────────────────────────────────────────────────
;; Works on macOS, Linux (X11/Wayland), and Windows without platform hacks.
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;;; ── 4. Quiet Splash Screen ──────────────────────────────────────────────────
(setq inhibit-startup-screen        t
      inhibit-startup-message       t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message       nil)

;;; ── 5. Resizing Optimisation ────────────────────────────────────────────────
;; Prevents Emacs from resizing the frame pixel-by-pixel when font metrics
;; change during init — a common source of brief visual jitter.
(setq frame-inhibit-implied-resize t)

;;; ── 6. Prefer Fresh .el Over Stale .elc ────────────────────────────────────
;; If you edit a source file and forget to recompile, Emacs still loads the
;; correct version.
(setq load-prefer-newer t)

;;; ── 7. Redirect Native-Comp Cache ──────────────────────────────────────────
;; Move eln-cache out of ~/.emacs.d/ root into var/ so it doesn't clutter the
;; config directory.  `startup-redirect-eln-cache' is available since Emacs 29.
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "var/eln-cache/" user-emacs-directory)))

;;; ── 8. Disable package.el ───────────────────────────────────────────────────
;; We use elpaca as our package manager. Prevent package.el from activating
;; and potentially loading stale packages from a previous install.
(setq package-enable-at-startup nil)

;;; ── 9. Encoding (Critical for Cross-Platform Correctness) ──────────────────
;; Set UTF-8 globally before anything else runs, so files opened via any OS are
;; decoded consistently.
(set-language-environment  "UTF-8")
(set-default-coding-systems 'utf-8)
