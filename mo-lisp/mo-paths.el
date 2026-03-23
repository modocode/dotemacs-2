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

;;; ── Font Registry ───────────────────────────────────────────────────────────
;;
;; Parallel to `my/paths' but for fonts.  Each entry is a cons of
;; (font-name . height), where height is in 1/10pt units (110 = 11pt).
;;
;; Keys used by core-ui.el:
;;   default  — the base/default face (monospace baseline)
;;   fixed    — fixed-pitch face (code blocks, inline code)
;;   variable — variable-pitch face (prose in Org/text modes)
;;
;; Override on a per-machine basis in your os/ file:
;;   (my/register-font 'variable "Source Serif 4" 130)

(defvar my/fonts
  '((default  . ("Inconsolata" . 110))
    (fixed    . ("Inconsolata" . 110))
    (variable . ("ETBembo"     . 130)))
  "Alist mapping font role keys to (font-name . height) conses.

Keys are symbols; values are (NAME . HEIGHT) where HEIGHT is in
1/10pt units (e.g. 130 = 13pt).

Override entries for your specific machine in your os/ config file
using `my/register-font' rather than mutating this alist directly.")

(defun my/register-font (key name &optional height)
  "Register NAME (and optional HEIGHT) for font role KEY in `my/fonts'.

KEY is a symbol (e.g. \\='variable).  NAME is a font family string.
HEIGHT is in 1/10pt units; if omitted the existing height is preserved.

Example:
  (my/register-font \\='variable \"Source Serif 4\" 130)"
  (let ((existing (alist-get key my/fonts)))
    (setf (alist-get key my/fonts)
          (cons name (or height (and existing (cdr existing)) 110)))))

(defun my/font-name (key)
  "Return the font family name registered for KEY, or nil."
  (car (alist-get key my/fonts)))

(defun my/font-height (key)
  "Return the font height (1/10pt) registered for KEY, or nil."
  (cdr (alist-get key my/fonts)))

(provide 'mo-paths)
;;; mo-paths.el ends here
