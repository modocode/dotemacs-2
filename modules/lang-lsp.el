;;; modules/lang-lsp.el --- Eglot LSP configuration -*- lexical-binding: t; -*-
;;
;; PURPOSE
;; ───────
;; This is the SINGLE place where Eglot is configured and attached to language
;; modes.  Nothing outside this file should call `eglot-ensure'.  That
;; decoupling means:
;;
;;   - To disable LSP globally: flip `my/use-eglot' to nil (before this loads)
;;   - To disable LSP per-buffer: use `my/toggle-eglot' (from mo-helpers.el)
;;   - To swap Eglot for something else (lsp-mode, etc.): replace THIS file only
;;
;; LOAD ORDER NOTE
;; ───────────────
;; This module uses `with-eval-after-load' for every hook so it doesn't matter
;; whether lang-c.el, lang-python.el, or lang-zig.el load before or after
;; this file.  The hooks are always registered at the right time.

;;; ── Toggle ──────────────────────────────────────────────────────────────────

(defvar my/use-eglot t
  "When non-nil, Eglot auto-starts in supported language buffers.

Set this to nil BEFORE init loads modules to disable all auto-start globally:

  ;; In init.el, before (my/load-directory ...):
  (setq my/use-eglot nil)

For per-buffer control at runtime, use `my/toggle-eglot'.")

;;; ── Python Server Selection ─────────────────────────────────────────────────

(defvar my/python-lsp-server "basedpyright"
  "Which Python language server to use with Eglot.
Valid values:
  \"basedpyright\" — recommended; pip install basedpyright (reliable on Windows)
  \"pyright\"      — pip install pyright (unreliable on Windows due to wrapper chain)
  \"pylsp\"        — pip install python-lsp-server (pure Python, no Node dependency)
The corresponding executable must be on your PATH.")

;;; ── Eglot ───────────────────────────────────────────────────────────────────
;; Built-in since Emacs 29. Provides LSP support via `completion-at-point-functions'
;; (CAPF), which corfu picks up automatically — no extra glue needed.

(use-package eglot
  :ensure nil   ; built-in since Emacs 29, do not let elpaca manage it
  :demand t     ; load now so eglot-server-programs is populated before hooks fire
  :custom
  ;; Stop the server when the last buffer for a project closes.
  ;; Prevents zombie processes accumulating across a session.
  (eglot-autoshutdown t)
  ;; Don't ask to confirm server-initiated workspace edits (rename symbol, etc.)
  (eglot-confirm-server-edits nil)
  ;; Disable the verbose events log buffer; set to a number to keep N events.
  (eglot-events-buffer-size 0)
  ;; Don't highlight all references to symbol-at-point — it's expensive.
  (eglot-ignored-server-capabilities '(:documentHighlightProvider))
  :config

  ;; ── Server Path Validation ─────────────────────────────────────────────────
  ;; Warn clearly if a required server binary is missing, so the user knows
  ;; exactly what to install rather than seeing a cryptic Eglot error.

  (my/with-binary "clangd" t)   ; clangd is in eglot defaults; just verify it exists
  (unless (executable-find "clangd")
    (warn "lang-lsp: `clangd' not found. C/C++ LSP will not start. Install: llvm/clangd"))

  (unless (or (executable-find "basedpyright-langserver")
              (executable-find "pyright-langserver")
              (executable-find "pylsp"))
    (warn "lang-lsp: No Python LSP found. Install: pip install basedpyright"))

  (unless (executable-find "zls")
    (warn "lang-lsp: `zls' not found. Zig LSP will not start. Install: https://github.com/zigtools/zls"))

  ;; ── Server Program Overrides ───────────────────────────────────────────────
  ;; Eglot's default server list is in `eglot-server-programs'.
  ;; We override Python here based on `my/python-lsp-server'.
  ;; C/C++ (clangd) and Zig (zls via add-to-list below) use Eglot defaults.

  (pcase my/python-lsp-server
    ("basedpyright"
     (add-to-list 'eglot-server-programs
                  '((python-mode python-ts-mode)
                    . ("basedpyright-langserver" "--stdio"))))
    ("pyright"
     (add-to-list 'eglot-server-programs
                  '((python-mode python-ts-mode)
                    . ("pyright-langserver" "--stdio"))))
    ("pylsp"
     (add-to-list 'eglot-server-programs
                  '((python-mode python-ts-mode)
                    . ("pylsp"))))
    (_
     (warn "lang-lsp: Unknown `my/python-lsp-server' value: %s" my/python-lsp-server)))

  ;; Zig: not in Eglot's built-in defaults list, so register it explicitly.
  (add-to-list 'eglot-server-programs
               '(zig-mode . ("zls"))))

;;; ── Centralized eglot-ensure Hooks ─────────────────────────────────────────
;; ALL `eglot-ensure' calls live here.
;; `with-eval-after-load' defers the hook registration until the mode's
;; feature is actually loaded, which is correct since we defer all packages.

(when my/use-eglot

  ;; Python
  (with-eval-after-load 'python
    (add-hook 'python-mode-hook    #'eglot-ensure)
    (add-hook 'python-ts-mode-hook #'eglot-ensure))

  ;; C / C++  (cc-mode provides both c-mode and c++-mode)
  (with-eval-after-load 'cc-mode
    (add-hook 'c-mode-hook   #'eglot-ensure)
    (add-hook 'c++-mode-hook #'eglot-ensure))

  ;; Zig
  (with-eval-after-load 'zig-mode
    (add-hook 'zig-mode-hook #'eglot-ensure)))

;;; ── Corfu + Eglot Integration ───────────────────────────────────────────────
;; Eglot populates `completion-at-point-functions' (CAPF).
;; Corfu reads CAPF automatically — no glue package needed.
;;
;; The one tweak: enable `corfu-separator' and partial-completion in eglot
;; buffers so that "vec<int" matches "std::vector<int>" correctly.

(with-eval-after-load 'eglot
  (with-eval-after-load 'corfu
    ;; Allow orderless-style completion in eglot capf candidates.
    ;; This sets completion-styles to use orderless inside eglot buffers.
    (add-hook 'eglot-managed-mode-hook
              (lambda ()
                (setq-local completion-styles '(orderless basic))
                (setq-local completion-category-defaults nil)))))

(provide 'lang-lsp)
;;; lang-lsp.el ends here
