;;; early-init.el --- Pre-initialization settings -*- lexical-binding: t; -*-

;; 1. Speed up startup by increasing the GC threshold.
;; We set this high during init and lower it in the main init.el later.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; 2. Prevent "GUI Flicker" 
;; Disable UI elements BEFORE the frame is even created. 
;; This is much faster and cleaner than putting these in init.el.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; 3. OS-Agnostic Frame Settings
;; Ensure the frame starts maximized or at a specific size without jumping.
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; 4. Clean up the startup screen
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

;; 5. Faster loading of .elc files (ignore newer .el files)
(setq load-prefer-newer t)

;; 6. Resizing optimization
;; Prevents Emacs from resizing the frame pixel-by-pixel, which is slow.
(setq frame-inhibit-implied-resize t)

;; 7. Prevent package.el from loading too early
;; Since we use a modular setup with elpaca/straight, we handle loading ourselves.
(setq package-enable-at-startup nil)

;; 8. Encoding (Vital for Windows/Linux interoperability)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
