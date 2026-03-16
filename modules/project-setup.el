;;; modules/project-setup.el --- project.el configuration -*- lexical-binding: t; -*-
;;
;; Configures the built-in project.el for project-aware navigation, search,
;; and shell access. Deliberately avoids Projectile to stay lean.
;;
;; NOTE: This file is named `project-setup.el', not `project.el', to avoid
;; shadowing the built-in `project' feature on the load-path.

(use-package project
  :ensure nil   ; built-in since Emacs 28
  :demand t     ; load immediately — project.el is infrastructure, not a plugin
  :custom
  ;; The C-x p p (project-switch-project) dispatch menu.
  ;; NOTE: project-list-file is managed by no-littering (→ var/project-list).
  ;; Only include commands that are always available (no Projectile, no Magit).
  ;; Keys in parens are the single-character dispatch shortcuts.
  (project-switch-commands
   '((project-find-file    "Find file"    ?f)
     (project-find-regexp  "Find regexp"  ?g)
     (project-dired        "Dired"        ?d)
     (project-shell        "Shell"        ?s)
     (project-eshell       "Eshell"       ?e)))

  :config

  ;; ── Custom Project Root Detection ─────────────────────────────────────────
  ;; project.el's default root detection only recognises .git.
  ;; We teach it to also recognise the same markers as `my/find-project-root'
  ;; so that Python (pyproject.toml), CMake, and Zig projects are found correctly
  ;; even in monorepos where the .git is several levels up.

  (defun my/project-try-local (dir)
    "Return a `(local . DIR)' project if DIR contains a known project marker.
Registered in `project-find-functions' so project.el uses it automatically."
    (cl-some (lambda (marker)
               (when-let* ((root (locate-dominating-file dir marker)))
                 (cons 'local root)))
             ;; Skip .git here — project.el already handles it natively.
             '("pyproject.toml" "CMakeLists.txt" "build.zig" ".project")))

  (add-hook 'project-find-functions #'my/project-try-local)

  ;; project.el needs a `project-root' method for the 'local project type we return.
  (cl-defmethod project-root ((project (head local)))
    (cdr project)))

(provide 'project-setup)
;;; project-setup.el ends here
