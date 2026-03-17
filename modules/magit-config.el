;;; modules/magit-config.el --- Git interface via Magit -*- lexical-binding: t; -*-

;;; ── Magit ────────────────────────────────────────────────────────────────────
;; The definitive Emacs git porcelain.  Bound to SPC g g by keybindings.el.
(use-package transient
  :ensure t
  :demand t
)

(use-package magit
  :ensure t
  :custom
  ;; Open magit-status in the current window instead of always splitting.
  ;; The diff view still gets its own window.
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1)

  ;; Highlight changed words inside hunks, not just changed lines.
  (magit-diff-refine-hunk 'all)

  ;; Save modified file-visiting buffers before running git operations.
  ;; 'dontask means save silently instead of prompting per-buffer.
  (magit-save-repository-buffers 'dontask)

  ;; How many commits to show in the status-buffer log section.
  (magit-log-section-commit-count 15)

  ;; Always show the revision in the commit message header.
  (magit-revision-show-gravatars nil))

;;; ── diff-hl ──────────────────────────────────────────────────────────────────
;; Shows added / changed / deleted line indicators in the left gutter,
;; identical to what VS Code shows for unstaged changes.
;; Hooks into magit so the gutter updates after every stage/unstage.

(use-package diff-hl
  :ensure t
  :demand t
  :hook
  ((magit-pre-refresh  . diff-hl-magit-pre-refresh)   ; clear stale highlights
   (magit-post-refresh . diff-hl-magit-post-refresh)  ; redraw after magit ops
   (dired-mode         . diff-hl-dired-mode))          ; diffs in dired sidebar
  :config
  (global-diff-hl-mode 1))

;;; ── git-timemachine ──────────────────────────────────────────────────────────
;; Step through a file's git history one commit at a time in-buffer.
;; Activate with SPC g t.  Inside timemachine:
;;   p / n  — previous / next revision
;;   q      — quit and return to HEAD

(use-package git-timemachine
  :ensure t)

;;; ── Health registration ──────────────────────────────────────────────────────
;; Tell mo-health to verify these features loaded correctly at startup.

(with-eval-after-load 'mo-health
  (add-to-list 'my/health-check-features 'magit-config t))

(provide 'magit-config)
;;; magit-config.el ends here
