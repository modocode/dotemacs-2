# Emacs Config Setup Guide

A modular, cross-platform Emacs config built around **elpaca** (package manager), **evil** (vim bindings), and a **SPC leader** key layout. Targets Linux, macOS, and Windows from a single shared repository.

---

## Requirements

| Tool | Purpose | Install |
|------|---------|---------|
| Emacs 29+ | Required for `startup-redirect-eln-cache`, native comp | [emacs.org](https://www.gnu.org/software/emacs/) |
| git | Required by elpaca to clone packages | `apt install git` / `brew install git` |
| rg (ripgrep) | `SPC s r` ripgrep search | `apt install ripgrep` / `brew install ripgrep` |
| A Nerd Font | Glyph icons in org-modern, modeline | [nerdfonts.com](https://www.nerdfonts.com/) |

LSP servers (all optional — install only what you need):

| Language | Binary | Install |
|----------|--------|---------|
| C / C++ | `clangd` | `apt install clangd` |
| Python | `pyright` | `pip install pyright` |
| Zig | `zls` | [github.com/zigtools/zls](https://github.com/zigtools/zls) |

---

## First Run

```bash
git clone <your-repo-url> ~/.emacs.d
emacs
```

On first startup, elpaca clones and compiles every package. This takes 2–5 minutes. You will see an `*elpaca-bootstrap*` buffer. Once done, Emacs restarts normally on subsequent launches.

After startup, run `M-x my/health-check` (or `SPC X`) to verify the config is healthy on this machine.

---

## Machine-Specific Setup

Paths like `~/org` and `~/notes` are not the same on every machine. Override them in your OS file:

**`os/linux.el`** / **`os/macos.el`** / **`os/windows.el`**:
```elisp
(my/register-path 'org-dir   "~/Dropbox/org/")
(my/register-path 'notes-dir "~/Dropbox/notes/")
```

The path registry (`mo-lisp/mo-paths.el`) ships with `~/org/` and `~/notes/` as defaults. Override only what differs on the current machine.

---

## Keybindings

All bindings use **SPC** as the leader in normal/visual mode. In insert or Emacs state, use **M-SPC** for the same bindings. Press `SPC` and wait 0.4 s to see all available keys via which-key.

### Buffers `SPC b`

| Key | Command |
|-----|---------|
| `SPC b b` | Switch buffer (consult) |
| `SPC b k` | Kill current buffer |
| `SPC b K` | Kill all other buffers |
| `SPC b n / p` | Next / previous buffer |
| `SPC b r` | Revert buffer from disk |
| `SPC b s` | Save buffer |

### Files `SPC f`

| Key | Command |
|-----|---------|
| `SPC f f` | Find file |
| `SPC f r` | Recent files |
| `SPC f s` | Save |
| `SPC f S` | Save all modified buffers |
| `SPC f R` | Rename file and buffer |
| `SPC f y` | Copy file path to clipboard |
| `SPC f i` | Open `init.el` |

### Windows `SPC w`

| Key | Command |
|-----|---------|
| `SPC w v` | Split right |
| `SPC w s` | Split below |
| `SPC w d` | Delete window |
| `SPC w o` | Delete other windows |
| `SPC w h/j/k/l` | Move to window left/down/up/right |
| `SPC w a` | Ace-window jump (pick by letter) |
| `SPC w =` | Balance all windows |
| `SPC w r` | **Hydra**: resize (h/j/k/l, stay open) |
| `SPC w z` | **Hydra**: text zoom (+/-/0) |

### Jump `SPC j` — avy

| Key | Command |
|-----|---------|
| `SPC j j` | Jump to char (type a char, then pick) |
| `SPC j w` | Jump to word |
| `SPC j l` | Jump to line |

### Projects `SPC p`

| Key | Command |
|-----|---------|
| `SPC p p` | Switch project |
| `SPC p f` | Find file in project |
| `SPC p g` | Grep in project |
| `SPC p d` | Open project in dired |
| `SPC p s` | Shell in project root |
| `SPC p e` | Eshell in project root |
| `SPC p k` | Kill all project buffers |

### Git `SPC g`

| Key | Command |
|-----|---------|
| `SPC g g` | Magit status |
| `SPC g b` | Git blame |
| `SPC g l` | Log for current branch |
| `SPC g d` | Diff current file |
| `SPC g c` | Clone repository |
| `SPC g f` | Find file at revision |
| `SPC g t` | Git timemachine (step through history) |
| `SPC g h` | **Hydra**: hunk nav/stage/revert |

**Timemachine keys** (active while in timemachine):  `p` / `n` step revisions, `q` quit.

**Hunk hydra keys**: `n`/`p` next/prev hunk, `s` stage hunk, `r` revert hunk, `d` show hunk popup, `q` quit.

### Search `SPC s`

| Key | Command |
|-----|---------|
| `SPC s s` | Search lines in buffer (consult-line) |
| `SPC s g` | Grep across files |
| `SPC s r` | Ripgrep (requires `rg`) |
| `SPC s i` | Jump to symbol in file (imenu) |
| `SPC s p` | Regex search in project |

### Org & Notes `SPC o`

| Key | Command |
|-----|---------|
| `SPC o a` | Org agenda |
| `SPC o c` | Org capture |
| `SPC o t` | Cycle todo state |
| `SPC o s` | Schedule item |
| `SPC o d` | Set deadline |
| `SPC o n` | New denote note |
| `SPC o l` | Link to denote note |
| `SPC o b` | Denote backlinks |

### Code `SPC c`

| Key | Command |
|-----|---------|
| `SPC c c` | Compile |
| `SPC c r` | Recompile (repeat last) |
| `SPC c d` | Jump to definition (xref) |
| `SPC c D` | Find all references (xref) |
| `SPC c f` | Format buffer (eglot) |
| `SPC c a` | Code actions (eglot) |
| `SPC c e` | Toggle eglot LSP on/off |
| `SPC c p` | Insert language debug-print at point |

### Eval `SPC e`

| Key | Command |
|-----|---------|
| `SPC e e` | Eval expression before point |
| `SPC e b` | Eval entire buffer |
| `SPC e r` | Eval selected region |
| `SPC e f` | Eval current defun |
| `SPC e i` | Reload `init.el` |

### Help `SPC h`

| Key | Command |
|-----|---------|
| `SPC h k` | Describe key |
| `SPC h f` | Describe function |
| `SPC h v` | Describe variable |
| `SPC h m` | Describe current mode |
| `SPC h p` | Describe package |
| `SPC h i` | Info manual browser |

### Toggle `SPC t`

| Key | Command |
|-----|---------|
| `SPC t n` | Toggle line numbers |
| `SPC t w` | Toggle word wrap |
| `SPC t t` | Load a different theme |
| `SPC t d` | Toggle debug-on-error |

### Top-level

| Key | Command |
|-----|---------|
| `SPC SPC` | M-x |
| `SPC :` | Eval expression |
| `SPC ;` | Comment/uncomment |
| `SPC X` | Health check report |

---

## Config Structure

```
early-init.el      Pre-init: GC boost, disable GUI, redirect eln-cache
init.el            Entry point: load-path, explicit requires, module auto-load

core/
  core-packages.el   elpaca bootstrap → no-littering → gcmh
  core-lib.el        Macros: my/with-binary, my/set-font, my/etc-dir, my/var-dir
  core-ui.el         Font cascade, modus-vivendi theme, variable-pitch hook

mo-lisp/           Personal libraries (loaded in explicit order)
  mo-paths.el        Machine-agnostic path registry
  mo-helpers.el      Interactive utilities (open-init, rename-file, debug-print…)
  mo-health.el       Startup health check system

modules/           Drop-in modules (auto-loaded alphabetically)
  completion.el      vertico + orderless + marginalia + consult + corfu + embark
  editing.el         smartparens + yasnippet
  evil-config.el     evil + evil-collection + evil-escape (jk)
  keybindings.el     general.el SPC leader + hydra UIs
  lang-c.el          C/C++ config
  lang-lsp.el        eglot (built-in LSP client)
  lang-python.el     Python config
  lang-zig.el        Zig config
  magit-config.el    magit + diff-hl gutter + git-timemachine
  org-config.el      org + org-modern + org-superstar + denote + org-ql
  project-setup.el   project.el with extra root markers
  themes.el          modus-themes, ef-themes, zenburn, gruvbox…
  ui-tweaks.el       which-key, line numbers, rg.el
  window.el          ace-window + evil-snipe + avy

os/                One file loaded per machine
  linux.el
  macos.el
  windows.el
```

---

## Adding a New Package

1. Create `modules/my-package-config.el` (never `modules/my-package.el` — it would shadow the package on the load-path)
2. Write a `use-package` block with `:ensure t`
3. Add `:demand t` for startup-critical packages, or `:hook`/`:bind` otherwise
4. End with `(provide 'my-package-config)`
5. Restart — `my/load-directory` picks it up automatically

---

## Key Design Decisions

**Why elpaca instead of straight/package.el?**
Elpaca is async, has better lock file support, and a nicer UI. The bootstrap block in `core-packages.el` is self-contained — it clones elpaca on first run with no manual steps.

**Why `use-package-always-defer t`?**
Every package that isn't needed at startup defers its load until first use. Startup stays under ~300 ms even with 50+ packages.

**Why no-littering?**
Without it, packages scatter state files all over `~/.emacs.d/`. With it, everything generated goes into `var/` (state) or `etc/` (config), which are both gitignored.

**Why are module files named `evil-config.el` not `evil.el`?**
`modules/` is on the `load-path`. A file named `evil.el` would shadow the real evil package when anything calls `(require 'evil)`. The `-config` suffix prevents the collision.

---

## Diagnostics

Run **`SPC X`** (or `M-x my/health-check`) to get a full report:
- Which OS config loaded
- Which paths in `my/paths` exist on disk
- Which external binaries (git, rg, LSP servers) are on PATH
- Which fonts are installed
- Whether every module loaded without error

On a healthy machine the report shows all green. On a new machine it tells you exactly what to install and which file to edit.
