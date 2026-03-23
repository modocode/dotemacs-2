;;; modules/lang-python.el --- Python language support -*- lexical-binding: t; -*-
;;
;; Configures the built-in python.el and adds virtual-env awareness.
;; LSP (eglot-ensure) is NOT called here — see modules/lang-lsp.el.

;;; ── Indentation Constants ───────────────────────────────────────────────────
;; Named variables instead of magic numbers so they're easy to find and change.

(defvar my/python-indent-width 4
  "Default indentation width for Python files. PEP 8 mandates 4.")

;;; ── Built-in Python Mode ────────────────────────────────────────────────────
;; python.el ships with Emacs — no package install needed.

(use-package python
  :ensure nil   ; built-in
  :mode ("\\.py\\'" . python-mode)
  :hook
  ;; Show trailing whitespace in Python files — PEP 8 violation if present.
  (python-mode . (lambda () (setq show-trailing-whitespace t)))
  :custom
  (python-indent-offset my/python-indent-width)
  ;; Use python3 as the default interpreter.  Override in os/*.el if your
  ;; machine uses a different name (e.g. "python" on some Windows setups).
  (python-shell-interpreter "python3")
  ;; Don't show the Python shell's startup banner — keeps the REPL clean.
  (python-shell-interpreter-args "-i --simple-prompt"))

;;; ── Virtual Environment Detection (pyvenv) ─────────────────────────────────
;; pyvenv activates a .venv or conda environment, updating exec-path and PATH
;; so Eglot's pyright/pylsp server and any M-x run-python REPL use the
;; project's interpreter rather than the system one.
;;
;; `pyvenv-tracking-mode' watches buffer changes and auto-activates the venv
;; found near the current file — the "it just works" experience.

(use-package pyvenv
  :ensure t
  :hook
  ;; Activate on entering any Python buffer.
  (python-mode . pyvenv-mode)
  :config
  ;; pyvenv-tracking-mode globally watches for pyvenv.cfg / .venv directories
  ;; as you switch buffers, activating the correct environment automatically.
  (pyvenv-tracking-mode 1)
  ;; Reconnect eglot after venv activation so the server sees the new interpreter.
  (add-hook 'pyvenv-post-activate-hooks
            (lambda ()
              (when (eglot-current-server)
                (call-interactively #'eglot-reconnect)))))

;;; ── Python Helpers ──────────────────────────────────────────────────────────

(defun my/python-venv-create ()
  "Create a .venv virtualenv at the project root and activate it.

Uses `my/find-project-root' to locate the project. Falls back to
`default-directory' if no root is found. After creation, pyvenv
activates the new env and eglot reconnects to pick up the new interpreter."
  (interactive)
  (let* ((root (or (my/find-project-root) default-directory))
         (venv-dir (expand-file-name ".venv" root))
         (python (or (executable-find python-shell-interpreter)
                     (executable-find "python3")
                     (executable-find "python"))))
    (unless python
      (user-error "No Python interpreter found on exec-path"))
    (when (file-exists-p venv-dir)
      (unless (yes-or-no-p (format ".venv already exists at %s — recreate? " root))
        (user-error "Aborted")))
    (message "Creating venv at %s ..." venv-dir)
    (let ((exit-code (call-process python nil "*python-venv-create*" t
                                   "-m" "venv" venv-dir)))
      (if (zerop exit-code)
          (progn
            (pyvenv-activate venv-dir)
            (message "Venv created and activated: %s" venv-dir))
        (pop-to-buffer "*python-venv-create*")
        (user-error "venv creation failed — see *python-venv-create* buffer")))))

(defun my/python-pip-install (packages)
  "Run `pip install PACKAGES' in the active virtualenv.

Prompts for a space-separated list of package names. Output appears in
a *pip-install* compilation buffer so you can watch the progress.
Eglot reconnects after installation so any newly installed stubs are
picked up by the language server."
  (interactive "sPip install packages: ")
  (unless (string-match-p "\\S-" packages)
    (user-error "No packages specified"))
  (let* ((pip (or (executable-find "pip")
                  (executable-find "pip3")))
         (args (split-string packages))
         (cmd  (mapconcat #'shell-quote-argument
                          (cons pip (cons "install" args)) " ")))
    (unless pip
      (user-error "pip not found — is a virtualenv active?"))
    (let ((compilation-buffer-name-function (lambda (_) "*pip-install*")))
      (compilation-start cmd nil))
    ;; Reconnect eglot after pip finishes so new stubs/packages are visible.
    (add-hook 'compilation-finish-functions
              (lambda (buf _status)
                (when (string= (buffer-name buf) "*pip-install*")
                  (when (eglot-current-server)
                    (call-interactively #'eglot-reconnect))
                  (remove-hook 'compilation-finish-functions
                               (lambda (_b _s) nil))))
              nil t)))

(defun my/python-show-eglot-stderr ()
  "Pop to the eglot stderr buffer for the current project.
Use this when the language server crashes to see the actual error message."
  (interactive)
  (let* ((server (eglot-current-server))
         (buf (and server (jsonrpc--stderr-buffer server))))
    (if (buffer-live-p buf)
        (pop-to-buffer buf)
      ;; Server is gone — look for the buffer by name pattern.
      (let ((found (cl-find-if
                    (lambda (b)
                      (string-match-p "EGLOT.*stderr" (buffer-name b)))
                    (buffer-list))))
        (if found
            (pop-to-buffer found)
          (message "No eglot stderr buffer found."))))))

;;; ── SPC m local leader bindings (Python) ───────────────────────────────────
;; Deferred until general is loaded (keybindings.el sets up my/local-leader).

(with-eval-after-load 'general
  (with-eval-after-load 'meow
    (my/local-leader
      :keymaps '(python-mode-map python-ts-mode-map)
      "v" '(my/python-venv-create  :which-key "create venv")
      "a" '(pyvenv-activate        :which-key "activate venv")
      "d" '(pyvenv-deactivate      :which-key "deactivate venv")
      "p" '(my/python-pip-install  :which-key "pip install")
      "r" '(run-python                  :which-key "run REPL")
      "l" '(my/python-show-eglot-stderr :which-key "LSP log"))))

(provide 'lang-python)
;;; lang-python.el ends here
