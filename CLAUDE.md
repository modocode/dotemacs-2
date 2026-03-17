# Emacs Config — Claude Context

Cross-platform Emacs config targeting Linux, macOS, and Windows. Uses **elpaca** as the package manager and **use-package** for configuration. The goal is a drop-in modular structure where adding a new plugin means creating one file in `modules/`.

---

## Directory Layout

```
.emacs.d/
├── early-init.el          # Pre-init: GC tuning, GUI suppression, eln-cache redirect, encoding
├── init.el                # Entry point: load-path, explicit core requires, module auto-loader
├── core/                  # Infrastructure — loaded explicitly in order by init.el
│   ├── core-packages.el   # elpaca bootstrap → no-littering → gcmh
│   ├── core-lib.el        # Helper macros/functions (my/with-binary, my/set-font, my/etc-dir, my/var-dir)
│   └── core-ui.el         # Font selection, theme (modus-vivendi), variable-pitch hook
├── mo-lisp/               # Personal libraries — loaded explicitly in order by init.el
│   ├── mo-paths.el        # Machine-agnostic path registry (my/path, my/register-path)
│   ├── mo-helpers.el      # Interactive utilities (my/open-init, my/insert-debug-print, etc.)
│   └── mo-health.el       # Startup health-check system
├── modules/               # Drop-in modules — auto-loaded by my/load-directory in init.el
│   ├── completion.el      # vertico, orderless, marginalia, consult, corfu, embark
│   ├── editing.el         # smartparens, yasnippet
│   ├── evil-config.el     # evil, evil-collection, evil-escape
│   ├── lang-c.el          # C/C++ config
│   ├── lang-lsp.el        # eglot (built-in LSP)
│   ├── lang-python.el     # Python config
│   ├── lang-zig.el        # Zig config
│   ├── keybindings.el     # general.el SPC leader + hydra UIs (window-resize, text-scale, git-hunk)
│   ├── lang-c.el          # C/C++ config
│   ├── magit-config.el    # magit + diff-hl gutter + git-timemachine
│   ├── org-config.el      # org, org-modern, org-superstar, org-super-agenda, org-ql, denote
│   ├── project-setup.el   # project.el with custom root markers
│   ├── themes.el          # Theme package installs (modus-themes, ef-themes, etc.)
│   ├── ui-tweaks.el       # which-key, line numbers, rg.el
│   └── window.el          # ace-window, evil-snipe, avy
└── os/                    # OS-specific overrides — only ONE is loaded at startup
    ├── linux.el
    ├── macos.el
    └── windows.el
```

**Generated at runtime — never commit:**

| Directory | Purpose |
|-----------|---------|
| `elpaca/` | Package clones, builds, caches |
| `var/` | no-littering runtime state (auto-save, backup, recentf, eln-cache…) |
| `etc/` | no-littering package config (gnus, yasnippet cache…) |
| `elpa/` | Stale package.el remnant — safe to `rm -rf` |

---

## Critical Conventions

### 1. Module filenames must never shadow package names

`modules/` is on the `load-path`. If a file is named `org.el`, any `(require 'org)` will find your config file instead of the real package, then fail because the file provides a different feature symbol.

**Rule:** Name config files `<package>-config.el` or `<package>-setup.el`, never `<package>.el`.

**Good examples already in the repo:**
- `evil-config.el` (not `evil.el`)
- `org-config.el` (not `org.el`)
- `project-setup.el` (not `project.el`)

The `provide` symbol at the bottom must match the filename, not the package name:
```elisp
(provide 'evil-config)   ; correct — matches evil-config.el
(provide 'evil)          ; WRONG  — shadows the real evil package
```

### 2. Every package needs `:ensure t` for elpaca to install it

Without `:ensure t`, elpaca does not install the package. It will silently fail or use a stale version. Always add `:ensure t` to every `use-package` block that wraps an external package. Built-ins use `:ensure nil`.

### 3. `use-package-always-defer t` is set globally

All packages are lazy by default. A `use-package` block's `:config` section only runs when the package actually loads. Packages that must be active from startup need an explicit trigger:

- `:demand t` — load immediately at startup
- `:hook (some-mode . some-mode)` — load when that mode activates
- `:bind` — load when the keybinding is pressed

**Packages that currently require `:demand t`:**
- `evil` — modal editing must be active before any keypress
- `org-modern` — `(global-org-modern-mode)` is in its `:config`
- `no-littering` — must intercept file paths before any other package runs
- `hydra`, `general` — must be loaded before keybindings are defined
- `diff-hl` — `(global-diff-hl-mode 1)` is in its `:config`
- `gcmh`, `vertico`, `orderless`, `marginalia`, `corfu` — active from the first interaction

### 4. no-littering load order

`no-littering` is installed in `core-packages.el` with its own `elpaca-wait` call, so it is fully loaded before any module runs. This ensures it can redirect file paths for all subsequently installed packages.

State files → `var/`  |  Config files → `etc/`

For packages not automatically handled by no-littering, use the helpers from `core-lib.el`:
```elisp
(my/var-dir "some-package/data")   ; → ~/.emacs.d/var/some-package/data
(my/etc-dir "some-package/config") ; → ~/.emacs.d/etc/some-package/config
```

### 5. Machine-specific paths go in `os/*.el`, not modules

The `mo-paths.el` registry holds cross-platform defaults. Override on a per-machine basis:

```elisp
;; in os/linux.el or os/macos.el
(my/register-path 'org-dir   "~/Dropbox/org/")
(my/register-path 'notes-dir "~/Dropbox/notes/")
```

Read paths in modules:
```elisp
(setq org-directory (my/path 'org-dir "~/org/"))  ; second arg is fallback
(setq org-agenda-files (my/path-list 'org-dir 'notes-dir))
```

### 6. All custom symbols use the `my/` prefix

Functions: `my/find-project-root`, `my/open-init`, `my/set-font`, …
Variables: `my/emacs-dir`, `my/is-mac`, `my/paths`, `my/project-root-markers`, …

---

## Startup Load Order

```
early-init.el
  └─ GC max, GUI off, eln-cache → var/eln-cache/, encoding

init.el
  ├─ require 'mo-paths       (path registry)
  ├─ require 'mo-helpers     (interactive utils)
  ├─ require 'mo-health      (health check)
  ├─ require 'core-packages  (elpaca → no-littering → gcmh)
  ├─ require 'core-lib       (macros + my/etc-dir, my/var-dir)
  ├─ require 'core-ui        (font, modus-vivendi theme)
  ├─ my/load-directory "modules/"   (all modules/*.el, alphabetical)
  └─ load os/<platform>.el  (machine overrides)
```

---

## Adding a New Package

1. Create `modules/my-thing-config.el` (never `modules/my-thing.el`)
2. Write a `use-package` block with `:ensure t`
3. Add `:demand t` if it must be active at startup, or `:hook`/`:bind` otherwise
4. End the file with `(provide 'my-thing-config)`
5. Restart Emacs — `my/load-directory` picks it up automatically

---

## Bugs Fixed in Setup Session (2026-03-16)

These were real bugs encountered and fixed — listed so future sessions understand why the config looks the way it does.

**`modules/evil-config.el` (was `evil.el`)**
- File renamed from `evil.el` → shadowed the real evil package on load-path
- Missing `:ensure t` on `evil` and `evil-escape` → elpaca never installed them
- Missing `:demand t` on `evil` → evil-mode never activated at startup
- `(provide 'evil)` → poisoned the feature symbol; changed to `(provide 'evil-config)`
- `evil-escape-key-sequence` was set inside evil's `:init` instead of evil-escape's

**`modules/org-config.el` (was `org.el`)**
- File renamed from `org.el` → shadowed built-in org on load-path, broke `org-modern` load
- `org-modern`, `org-superstar`, `org-super-agenda`, `org-ql` all missing `:ensure t`
- `org-modern` missing `:demand t` → `global-org-modern-mode` never called
- `org-superstar` missing `:hook (org-mode . org-superstar-mode)` → never activated

**`core-packages.el`**
- Added `no-littering` as section 3, before all other packages, with its own `elpaca-wait`
- Configured `auto-save-file-name-transforms` and `backup-directory-alist` via no-littering

**`early-init.el`**
- Added `startup-redirect-eln-cache` to move `eln-cache/` → `var/eln-cache/`

**`modules/project-setup.el`**
- Removed explicit `project-list-file` setting — no-littering handles it automatically
