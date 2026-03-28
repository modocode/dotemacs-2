;;; modules/dired-config.el --- Dired + Dirvish file manager -*- lexical-binding: t; -*-
;;
;; Dirvish replaces dired as the primary file manager.  It adds a preview pane,
;; file icons, git status, subtree expansion, and a polished modeline — all
;; while staying fully compatible with dired commands and keybindings.
;;
;; Layout: dirvish-override-dired-mode makes every dired call open dirvish.
;; Icons:  all-the-icons is declared here (also used by centaur-tabs).

;;; ── Built-in Dired ───────────────────────────────────────────────────────────

(use-package dired
  :ensure nil
  :custom
  ;; Group directories first on platforms that support it; plain -alh elsewhere.
  (dired-listing-switches
   (if (eq system-type 'windows-nt)
       "-alh"
     "-agho --group-directories-first"))
  (dired-dwim-target        t)   ; guess copy/move target from other dired window
  (dired-auto-revert-buffer t)   ; refresh buffer when revisiting a directory
  (delete-by-moving-to-trash t)) ; C-x C-k sends to OS trash, not /dev/null

;;; ── dired-x: extra built-in features ────────────────────────────────────────

(use-package dired-x
  :ensure nil
  :hook (dired-mode . dired-omit-mode)
  :custom
  ;; Hide dotfiles, backup files, and macOS metadata by default.
  ;; Toggle with C-x M-o (dired-omit-mode).
  (dired-omit-files
   (rx (or (seq bol (any ".#"))          ; dotfiles and lock files
           (seq bol ".." eol)            ; parent dir entry
           (seq ".DS_Store" eol)))))     ; macOS metadata

;;; ── all-the-icons ────────────────────────────────────────────────────────────
;; Provides file-type icons for dirvish and centaur-tabs.
;; First install: M-x all-the-icons-install-fonts

(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

;;; ── Dirvish ──────────────────────────────────────────────────────────────────

(use-package dirvish
  :ensure t
  :demand t
  :init
  ;; Replace every dired call with dirvish — no need to call dirvish directly.
  (dirvish-override-dired-mode)
  :custom
  ;; Quick-access bookmarks: press `a' in dirvish to jump here instantly.
  (dirvish-quick-access-entries
   '(("h" "~/"             "Home")
     ("d" "~/Downloads/"   "Downloads")
     ("p" "~/projects/"    "Projects")))

  ;; Right-side attribute columns shown next to each file.
  ;; Order matters: leftmost attribute is closest to the filename.
  (dirvish-attributes
   '(all-the-icons subtree-state collapse vc-state git-msg file-size))

  ;; Modeline: left side shows sort order and timestamps; right shows index.
  (dirvish-mode-line-format
   '(:left  (sort file-time " " file-size symlink)
     :right (omit yank index)))

  ;; Header: full path on the left, free disk space on the right.
  (dirvish-header-line-format
   '(:left (path) :right (free-space)))

  ;; Preview pane dispatchers (tried in order).
  ;; image/video/audio require external tools (imagemagick, ffmpeg, etc.).
  (dirvish-preview-dispatchers
   '(image video audio epub pdf archive))

  :config
  ;; Show the preview pane by default for full-frame dirvish sessions.
  (setq dirvish-default-layout '(0 0.4 0.6))

  :bind
  (:map dirvish-mode-map
   ;; Quick access and menus
   ("a"   . dirvish-quick-access)
   ("f"   . dirvish-file-info-menu)
   ("y"   . dirvish-yank-menu)
   ("s"   . dirvish-quicksort)
   ("v"   . dirvish-vc-menu)
   ;; Navigation
   ("^"   . dirvish-history-last)
   ("TAB" . dirvish-subtree-toggle)
   ("M-f" . dirvish-history-go-forward)
   ("M-b" . dirvish-history-go-backward)
   ;; Layout and display
   ("M-t" . dirvish-layout-toggle)
   ("M-s" . dirvish-setup-menu)
   ("M-l" . dirvish-ls-switches-menu)
   ;; Marks and narrow
   ("M-m" . dirvish-mark-menu)
   ("M-n" . dirvish-narrow)))

(provide 'dired-config)
;;; dired-config.el ends here
