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
  (pyvenv-tracking-mode 1))

(provide 'lang-python)
;;; lang-python.el ends here
