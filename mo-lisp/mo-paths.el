;;; mo-lisp/mo-paths.el --- Machine-agnostic path registry -*- lexical-binding: t; -*-
;;
;; PROBLEM THIS SOLVES
;; ───────────────────
;; Paths like ~/org or ~/notes are not OS-type facts (Linux vs macOS), they are
;; machine-specific facts.  Two Linux machines might store notes in completely
;; different places.  Hardcoding them anywhere in modules/ forces you to edit
;; that file on every machine, which breaks the drop-in philosophy.
;;
;; SOLUTION
;; ────────
;; This file provides a central path registry (`my/paths') with sensible
;; cross-platform defaults.  Each os/ file can then call `my/register-path'
;; to override only the entries that differ on that machine.  Modules read
;; paths through `my/path' instead of using literal strings.
;;
;; USAGE PATTERN
;; ─────────────
;;
;;   In modules/org.el (or wherever you configure org):
;;     (setq org-directory (my/path 'org-dir))
;;     (setq org-agenda-files (my/path-list 'org-dir 'notes-dir))
;;
;;   In os/linux.el for a machine where notes live in Dropbox:
;;     (my/register-path 'notes-dir "~/Dropbox/notes/")
;;
;;   In os/macos.el for a Mac with iCloud Drive:
;;     (my/register-path 'org-dir   "~/Library/Mobile Documents/com~apple~CloudDocs/org/")
;;     (my/register-path 'notes-dir "~/Library/Mobile Documents/com~apple~CloudDocs/notes/")
;;
;; INSPECTING THE REGISTRY AT RUNTIME
;; ────────────────────────────────────
;;   C-h v my/paths RET        — see every registered path
;;   M-: (my/path 'org-dir)    — resolve a specific key right now

;;; ── Registry ────────────────────────────────────────────────────────────────

(defvar my/paths
  '((org-dir   . "~/org/")
    (notes-dir . "~/notes/"))
  "Alist mapping symbolic path keys to directory strings.

Keys are symbols; values are strings accepted by `expand-file-name',
so ~ and environment variables are valid.

Override entries for your specific machine in your os/ config file using
`my/register-path' rather than mutating this alist directly.")

;;; ── API ─────────────────────────────────────────────────────────────────────

(defun my/register-path (key path)
  "Register or override PATH under KEY in `my/paths'.

KEY is a symbol (e.g. \\='org-dir).  PATH is a string — ~ is allowed.
Call this from your os/ file to declare where things actually live on
this specific machine.

Example:
  (my/register-path \\='notes-dir \"~/Dropbox/notes/\")"
  (setf (alist-get key my/paths) path))

(defun my/path (key &optional fallback)
  "Return the expanded path registered under KEY in `my/paths'.

If KEY has no entry, return FALLBACK (default: nil).
The path is always passed through `expand-file-name', so ~ is resolved
to the real home directory.

Example:
  (my/path \\='org-dir)          ;; => \"/home/user/org/\"
  (my/path \\='roam-dir \"~/org\") ;; => \"/home/user/org\" if roam-dir unset"
  (let ((entry (alist-get key my/paths)))
    (if entry
        (expand-file-name entry)
      (and fallback (expand-file-name fallback)))))

(defun my/path-list (&rest keys)
  "Return a list of expanded paths for each symbol in KEYS.

Keys with no entry in `my/paths' are silently omitted, so you can
pass optional keys without needing to guard against nil entries.

Typical use for `org-agenda-files':
  (my/path-list \\='org-dir \\='notes-dir \\='projects-dir)"
  (delq nil (mapcar #'my/path keys)))

(defun my/path-exists-p (key)
  "Return t if the path registered under KEY exists on disk."
  (let ((p (my/path key)))
    (and p (file-exists-p p))))

(provide 'mo-paths)
;;; mo-paths.el ends here
