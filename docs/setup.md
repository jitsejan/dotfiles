# Dotfiles & Machine Setup

A single, reproducible source of truth for my macOS development machine. Clone the
repo, run one script, and the machine is provisioned: packages installed, shell
configured, apps set up, and config files symlinked.

## The approach

- **Declarative where possible.** A [Brewfile](#brewfile) lists every package, cask,
  VS Code extension, and npm global. `brew bundle` makes the machine converge to that list.
- **Idempotent scripts.** Every script checks "is this already done?" before acting,
  so re-running `bootstrap.sh` is safe.
- **Symlinks, not copies.** Shell/terminal configs live in the repo and are symlinked
  into `~/.config`, so editing a tracked file *is* editing the live config.
- **One command to rule them all.** `./scripts/bootstrap.sh` orchestrates everything.
- **Secrets stay out of git.** `fish_variables` and other sensitive stores are gitignored.

```bash
# Full setup on a fresh machine
git clone git@github.com:jitsejan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh
```

## Repository layout

```
dotfiles/
├── Brewfile                 # all brew/cask/vscode/npm packages
├── README.md
├── dotfiles.code-workspace  # VS Code workspace
├── .gitignore               # ignores secrets, .DS_Store, .venv, swap files
├── .config/
│   ├── fish/                # shell config + functions
│   ├── kitty/               # terminal config, theme, custom tab bar
│   ├── starship.toml        # prompt
│   └── obsidian/            # tracked Obsidian config (app, theme, plugins)
└── scripts/
    ├── bootstrap.sh         # orchestrator
    ├── install_brew.sh      # Homebrew + brew bundle
    ├── install_python_tools.sh
    ├── install_apps.sh      # npm globals
    └── setup_*.sh           # per-tool setup (docker, dock, codex, …)
```

## Bootstrap flow

`bootstrap.sh` runs these steps in order:

1. **OS detection** — macOS runs `install_brew.sh`; Linux falls back to a
   (not-yet-implemented) `install_apt.sh`.
2. **Make Fish the login shell** — adds Fish to `/etc/shells` and runs `chsh`.
3. **Python tooling** — `install_python_tools.sh`.
4. **npm globals** — `install_apps.sh`.
5. **Per-tool setup** — Obsidian, Codex, Docker, Beyond Compare, Fork, Terraform,
   git-filter-repo, Dock.
6. **Symlink configs** into `~/.config`:
   - `~/.config/kitty` → repo `.config/kitty`
   - `~/.config/starship.toml` → repo `.config/starship.toml`
   - `~/.config/fish` → repo `.config/fish`

## Brewfile

The Brewfile is the heart of the setup — `brew bundle` installs everything in it.

| Group | Packages |
|-------|----------|
| **Taps** | `microsoft/mssql-release` |
| **Shell & Terminal** | fish, starship, kitty |
| **Core Dev** | act, awscli, docker-desktop, dockutil, duckdb, gh, git, git-filter-repo, node, pipx, postgresql@14, terraform, terragrunt, uv, gcloud-cli |
| **CLI Utilities** | bat, btop, cmatrix, eza, fd, fzf, glow, jq, qpdf, ripgrep, tree, zoxide |
| **Dev Apps** | cursor, fork, pycharm, visual-studio-code |
| **Productivity** | rectangle, obsidian, beyond-compare, shadow |
| **Browsers** | google-chrome, microsoft-edge |
| **AI Tools** | chatgpt, claude, codex |
| **DB Drivers** | unixodbc, msodbcsql18 (MS SQL ODBC) |
| **Docs** | pandoc, mactex |
| **Fonts** | font-jetbrains-mono-nerd-font |
| **VS Code** | 17 extensions (Python, Jupyter, Terraform, YAML, PlantUML, Mermaid, Atlassian, Monokai Pro, Makefile…) |
| **npm globals** | @anthropic-ai/claude-code, @mermaid-js/mermaid-cli |

> **Tracked but installed outside brew:** `kitty` and `shadow` are kept in the Brewfile
> even though they don't appear in `brew bundle dump` — they're managed another way but
> I want them tracked.

**Keeping the Brewfile in sync with the Mac:**

```bash
brew bundle dump --file=- --describe   # what's actually installed
```

Then add what's installed-but-untracked and remove what's tracked-but-gone.

## Shell — Fish + Starship

**Fish** is the login shell. `config.fish` sets up:

- **PATH** — prepends `/opt/homebrew/bin`.
- **Modern CLI aliases** — the "rust rewrites" replace the classics:

  | Alias | Runs | Replaces |
  |-------|------|----------|
  | `cat` | `bat` | cat |
  | `ls` | `eza -alh` | ls |
  | `grep` | `rg` (ripgrep) | grep |
  | `find` | `fd` | find |
  | `cd` | `z` (zoxide) | cd |
  | `please` | `sudo` | — |

- **zoxide** for smart directory jumping.
- **Auto-dotenv** — a `PWD` change hook auto-loads `.env` via the `dotenv` function
  when entering a directory.

**Starship** drives the prompt (`starship.toml`):

- Two-tone powerline: directory → git branch → git status → Python project name.
- **Python-aware**: shows interpreter version + virtualenv, and detects **Rye**
  (`rye.lock`) and **uv** (`uv.lock`) projects with custom segments.
- Right-side: Python info, command duration, clock (`HH:MM:SS`).

## Terminal — Kitty

`kitty.conf` configures:

- **Font**: RobotoMono Nerd Font.
- **Custom bottom tab bar** (`tab_bar.py`) — left-aligned, no separators, bold active tab.
- Theme split into `theme.conf`.

## Python tooling

`install_python_tools.sh` installs:

- **uv** (Astral) — fast package installer/resolver.
- **Rye** — project & Python version management.
- Via **pipx** (isolated): `black`, `ruff`, `isort`, `pyright`.

Workflow leans on **Rye + uv**, with Starship surfacing which one a project uses.

## AI & coding tools

- **Claude** desktop app + **Claude Code** CLI (`@anthropic-ai/claude-code`, npm global).
- **ChatGPT** desktop app + **Codex CLI** (`setup_codex.sh` handles login and writes
  `~/.codex/config.toml`).
- **Cursor** editor.

## Per-tool setup scripts

Each is idempotent — verifies the app/binary exists, then configures it:

| Script | What it does |
|--------|--------------|
| `setup_docker.sh` | Verifies Docker Desktop, launches it, waits for the daemon, checks compose. |
| `setup_dock.sh` | Rebuilds the macOS Dock via `dockutil` — grouped layout (file mgmt → notes → dev/ops → comms) with spacers. |
| `setup_codex.sh` | Checks/does Codex login, writes a default `config.toml`. |
| `setup_terraform.sh` | Verifies Terraform + Terragrunt, ensures `~/.terraform.d`. |
| `setup_beyondcompare.sh` | Symlinks `bcomp` CLI into `/usr/local/bin`. |
| `setup_fork.sh` | Verifies Fork + checks global git user config. |
| `setup_git_filter_repo.sh` | Verifies install, prints safety warnings + usage patterns. |
| `setup_obsidian.sh` | Provisions the Obsidian vault (see below). |

## Obsidian

`setup_obsidian.sh` provisions the knowledge-base vault:

- **Vault**: `ObsidiJan` at `~/Documents/Obsidian`.
- Registers the vault in `~/Library/Application Support/obsidian/obsidian.json`.
- Copies tracked config from `.config/obsidian/` into the vault's `.obsidian/`:
  - `app.json` — editor prefs (tab size 4, spaces, readable line length, spellcheck
    en-US, attachments → `attachments/`).
  - `appearance.json` — **Cupertino 2** theme, base font 16.
  - `community-plugins.json` — enables **Bases** + **Notebook Navigator**.
  - `plugins/` — pre-seeded plugin settings.

> **Manual step:** community plugins (Bases, Notebook Navigator) must be installed once
> via Obsidian → Settings → Community plugins → Browse. Settings are pre-configured, so
> they work immediately after install.

## Maintenance playbook

- **Add a package** — edit `Brewfile`, run `brew bundle`, commit.
- **Tweak shell/prompt** — edit the symlinked file in the repo (changes are live), commit.
- **New machine** — clone + `./scripts/bootstrap.sh`.
- **Audit drift** — `brew bundle dump --describe` and diff against `Brewfile`.
- **Issues → branches → PRs** — track changes as GitHub issues, one branch/PR per issue
  (`claude/issue-<n>-<slug>`), squash-merge to `master`.
</content>
