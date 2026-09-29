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
- **Works without admin rights.** The same scripts provision a locked-down,
  IT-managed Mac — see [No-admin mode](#no-admin-mode).
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
│   ├── ghostty/             # terminal config (font, colors)
│   ├── starship.toml        # prompt
│   ├── obsidian/            # tracked Obsidian config (app, theme, plugins)
│   ├── zsh/                 # zsh → fish handoff (no-admin machines)
│   └── vscode/              # settings.json + keybindings.json
└── scripts/
    ├── bootstrap.sh         # orchestrator
    ├── lib/common.sh        # admin detection + path resolution, sourced by all
    ├── install_brew.sh      # Homebrew + brew bundle
    ├── install_node.sh      # node via fnm when brew would compile it
    ├── setup_shell.sh       # Fish as the interactive shell
    ├── install_python_tools.sh
    ├── install_apps.sh      # npm globals
    └── setup_*.sh           # per-tool setup (docker, dock, obsidian, …)
```

## Bootstrap flow

`bootstrap.sh` runs these steps in order:

0. **Admin detection** — `scripts/lib/common.sh` checks group membership and sets
   `DOTFILES_NO_ADMIN`. Everything downstream branches off that one flag.
1. **OS detection** — macOS runs `install_brew.sh`; Linux falls back to a
   (not-yet-implemented) `install_apt.sh`.
2. **Symlink configs** (see the list below) — done early so Fish starts with its
   config already in place.
3. **Fish as the interactive shell** — `setup_shell.sh`. With admin it adds Fish to
   `/etc/shells` and runs `chsh`; without, zsh hands off to Fish instead.
4. **Python tooling** — `install_python_tools.sh`.
5. **npm globals** — `install_apps.sh`.
6. **Per-tool setup** — Obsidian, Docker, Beyond Compare, Fork, Terraform,
   git-filter-repo, Dock.
7. **Manual-step summary** — anything that could not be automated (an admin-only
   installer, Obsidian's plugin browser) is collected during the run and printed
   at the end, so it doesn't scroll past unnoticed.

The symlinks created in step 2:
   - `~/.config/ghostty` → repo `.config/ghostty`
   - `~/.config/starship.toml` → repo `.config/starship.toml`
   - `~/.config/fish` → repo `.config/fish`
   - `~/.config/zsh` → repo `.config/zsh` (the Fish handoff snippet)
   - `~/Library/Application Support/Code/User/settings.json` → repo
     `.config/vscode/settings.json`
   - `~/Library/Application Support/Code/User/keybindings.json` → repo
     `.config/vscode/keybindings.json`
   - (skipped if VS Code hasn't been launched once yet — its `User/` directory
     won't exist; re-run `bootstrap.sh` after first launch)

## Brewfile

The Brewfile is the heart of the setup — `brew bundle` installs everything in it.

It is evaluated as **Ruby**, which lets one file serve both machine types. Two
helpers do that work:

- `no_admin` — reads `HOMEBREW_DOTFILES_NO_ADMIN` and swaps Docker Desktop for
  colima, and drops the four `.pkg`-installer casks. The variable **must** carry
  the `HOMEBREW_` prefix: `brew` strips other variables from the environment it
  evaluates the Brewfile in, so a plain `DOTFILES_NO_ADMIN` silently arrives as
  `nil` and the admin branch is taken by mistake.
- `cask_unless_present` — skips a cask when the app already exists in
  `/Applications` or `~/Applications`. A managed Mac gets Chrome and Edge pushed
  by IT; without this, `brew bundle` installs a second copy into `~/Applications`
  that shadows the managed one and drifts separately.

CI parses the Brewfile **both ways**, so a syntax error can't hide in the branch
that the current machine doesn't take.

| Group | Packages |
|-------|----------|
| **Taps** | `microsoft/mssql-release`, `hashicorp/tap` |
| **Shell & Terminal** | fish, starship, ghostty, iterm2 |
| **Core Dev** | act, awscli, docker-desktop *(colima + docker CLI without admin)*, dockutil, duckdb, gh, git, git-filter-repo, node, opencode, pipx, libpq, hashicorp/tap/terraform, terragrunt, tmux, uv, gcloud-cli |
| **CLI Utilities** | bat, btop, cmatrix, eza, fd, fzf, glow, jq, qpdf, ripgrep, shellcheck, tree, zoxide |
| **Dev Apps** | fork, visual-studio-code |
| **Productivity** | rectangle, obsidian, beyond-compare, shadow, libreoffice, zoom *(admin only)* |
| **Client / VDI** | windows-app, intune-company-portal — both *admin only* (`.pkg` installers) |
| **Browsers** | google-chrome, microsoft-edge |
| **AI Tools** | chatgpt, claude |
| **DB Drivers** | unixodbc, msodbcsql18 (MS SQL ODBC) |
| **Docs** | pandoc, mactex *(admin only)* |
| **Fonts** | font-jetbrains-mono-nerd-font |
| **VS Code** | 18 extensions (Python, Jupyter, Terraform, YAML, PlantUML, Mermaid, Atlassian, Monokai Pro, Makefile, rainbow-csv…) |
| **npm globals** | @anthropic-ai/claude-code, @mermaid-js/mermaid-cli, pptxgenjs |

**Keeping the Brewfile in sync with the Mac:**

```bash
brew bundle dump --file=- --describe   # what's actually installed
```

Then add what's installed-but-untracked and remove what's tracked-but-gone.

**Watch for formulae that leave homebrew-core.** `brew bundle` skips an entry
that no longer resolves *without failing*, so a package can quietly stop being
installed while the Brewfile still lists it. Terraform hit exactly this when
HashiCorp relicensed it to the BUSL and homebrew-core dropped the formula — the
entry has to be tap-qualified (`hashicorp/tap/terraform`) to work at all. If a
tracked tool keeps turning up missing, check `brew info <name>` before assuming
the install failed.

## No-admin mode

Work Macs are often locked down: the account is not in the `admin` group, so
`sudo` is unavailable and `/Applications`, `/usr/local/bin`, `/opt` and
`/etc/shells` are all read-only. Rather than maintaining a second set of scripts,
every script asks `scripts/lib/common.sh` where things live and whether it may
escalate.

Detection is automatic (`dsmemberutil checkmembership -U "$(whoami)" -G admin`).
Set `DOTFILES_NO_ADMIN=1` to force the no-admin path on a machine that does have
admin rights — that's how the mode gets tested.

| Concern | With admin | Without admin |
|---|---|---|
| Homebrew prefix | `/opt/homebrew` via the official installer | user-owned prefix (`~/homebrew` on a fresh install), untarred from the brew tarball |
| Casks | `/Applications` | `~/Applications` via `HOMEBREW_CASK_OPTS=--appdir=…` |
| Fish as shell | `/etc/shells` + `chsh` | zsh `exec`s Fish for interactive shells |
| Containers | Docker Desktop | colima + the `docker` CLI |
| Node | `brew "node"` | `fnm` + upstream's prebuilt binaries |
| opencode | `brew "opencode"` | `npm "opencode-ai"` |
| `bcomp` CLI shim | `/usr/local/bin` | `~/.local/bin` |
| Dock | `dockutil` | `dockutil` (unchanged — the Dock is per-user state) |

### Homebrew in a user prefix

Homebrew officially supports only `/opt/homebrew` on Apple Silicon, but it runs
fine from a user-owned prefix. The caveat is bottles: a formula whose bottle is
not relocatable gets **compiled from source**, which is slow. In practice most
bottles relocate cleanly, so this is a tolerable tradeoff rather than a blocker.

Whether a bottle relocates is visible in the formula's metadata: a `cellar` of
`:any` or `:any_skip_relocation` pours anywhere, while a hardcoded
`/opt/homebrew/Cellar` means a source build. For this Brewfile, most
formulae pour cleanly. The six that don't:

| Formula | Cost in a user prefix |
|---|---|
| `openssl@3` | Long, and a dependency of much of the tree — the first run sits on it |
| `git`, `unixodbc`, `libpq`, `git-filter-repo` | Ordinary bounded builds, minutes each |
| `node`, `opencode` | **Unacceptable** — both need LLVM, which also has no relocatable bottle |

`node` and `opencode` are therefore not installed from Homebrew on a no-admin
machine. Building node from source pulls in a full LLVM 22 compile — hours of
CPU for a runtime that upstream ships as a ready-made binary. Instead:

- **node** comes from **`fnm`** (a `:any_skip_relocation` bottle, installs in
  seconds) which downloads upstream's official prebuilt Node. `install_node.sh`
  is *sourced* by `install_brew.sh` before `brew bundle` runs, because the
  Brewfile's `npm` entries need npm to already exist. `config.fish` loads
  `fnm env --use-on-cd` so the shell picks it up too.
- **opencode** comes from its npm package `opencode-ai`, which is prebuilt and
  tracks the same upstream releases.

To check this yourself before adding a formula:

```bash
brew info --json=v2 <formula> | \
  python3 -c "import sys,json; f=json.load(sys.stdin)['formulae'][0]; \
  print({k:v['cellar'] for k,v in f['bottle']['stable']['files'].items()})"
```

A value starting with `:` pours; a path means it compiles. The first run is slow
regardless; later runs reuse the built kegs and are fast.

Scripts never hardcode the prefix — `brew_prefix()` in `common.sh` resolves it,
and `config.fish` walks a list of candidate prefixes.

Homebrew calls a user prefix a
[Tier 3 configuration](https://docs.brew.sh/Support-Tiers#tier-3): supported, but
report issues to Homebrew's own repos rather than expecting upstream help.

**Known caveat on this machine.** The prefix is currently `~/Documents/.brew`,
which sits inside a directory holding personal files, so Homebrew's build sandbox
cannot wall formulae off from it:

```
Warning: The sandbox cannot prevent formulae from reading:
  /Users/<user>/Documents
because this required path is inside it: /Users/<user>/Documents/.brew
Formulae may access personal data in this directory.
```

Moving the prefix to `~/homebrew` (the location a fresh no-admin install uses)
would restore the sandbox, but requires reinstalling everything — including the
slow source builds. Deferred deliberately; it belongs in its own PR.

### When a source build can't fetch its tarball

Two constraints compound here. A formula without a relocatable bottle builds from
source, and the office network (Cloudflare Gateway) re-signs or blocks some
upstream hosts. The symptom is either a DNS failure *inside the build sandbox* —
which restricts network access even when the host resolves fine from your shell —
or a checksum mismatch, which means a block page arrived instead of the tarball:

```
curl: (6) Could not resolve host: invisible-mirror.net
Error: Formula reports different checksum
```

`tmux` hit this: its dependency `ncurses` has no relocatable bottle, and
`invisible-mirror.net` is not reachable through the proxy. The fix is to fetch the
identical tarball from a mirror that *is* reachable and seed Homebrew's cache with
it, then install normally:

```bash
curl -fsSL -o /tmp/ncurses.tar.gz https://ftp.gnu.org/gnu/ncurses/ncurses-6.6.tar.gz
shasum -a 256 /tmp/ncurses.tar.gz          # must match what brew reported
cp /tmp/ncurses.tar.gz "$(brew --cache --build-from-source ncurses)"
brew install tmux
```

`brew --cache --build-from-source <formula>` prints the exact path and filename
Homebrew expects, so the copy is all that is needed — Homebrew verifies the
checksum and skips the download. Generalise this to any formula whose source host
the network blocks.

### Fish without `chsh`

`chsh` refuses any shell that isn't listed in `/etc/shells`, and adding a line
there needs `sudo`. So the login shell stays zsh and `~/.zshrc` sources
`.config/zsh/launch-fish.zsh`, which `exec`s Fish for interactive shells. The
logic is tracked in this repo; `~/.zshrc` only gets a marked one-line hook.

This is deliberately terminal-agnostic — it works in iTerm2, Terminal.app,
Ghostty and VS Code alike, rather than relying on one terminal's "run this
command" setting. Two escape hatches: `DOTFILES_NO_FISH=1` skips the handoff for
a session, and the `INSIDE_FISH` guard prevents a zsh→fish→zsh loop.

Because the source line sits at the *end* of `~/.zshrc`, exports above it (the
Homebrew `PATH`, the corporate CA bundle) are inherited by the Fish process.

### Containers via colima

Docker Desktop installs a privileged helper the first time it launches and asks
for an admin password. [colima](https://github.com/abiosoft/colima) runs the same
Docker API in a user-owned Lima VM, so the `docker` and `docker compose` CLIs
behave identically with no escalation. `setup_docker.sh` prefers Docker Desktop
when it's installed and falls back to colima otherwise.

### What still can't be automated

Four casks ship a `.pkg` installer, which always needs a password. On a no-admin
machine the Brewfile skips them and `bootstrap.sh` prints them as manual steps:

| Cask | Workaround |
|---|---|
| `zoom` | Use the web client, or ask IT to push it |
| `windows-app` | Ask IT (it's the managed VDI client anyway) |
| `intune-company-portal` | Ask IT — enrolment is their job |
| `mactex` | Use `tinytex` (installs into `$HOME`) with the tracked `pandoc` |

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

## Terminal — Ghostty

`.config/ghostty/config` configures:

- **Font**: JetBrainsMono Nerd Font.
- **Colors**: custom Monokai-ish palette (dark `#191919` background) ported from the
  previous Kitty theme.
- Native macOS tabs/splits, `copy-on-select`, option-as-alt, saved window state.

## Editor — VS Code

`.config/vscode/settings.json` + `keybindings.json` are symlinked into VS Code's
`User/` config directory (see Bootstrap flow, step 6):

- **Theme**: Monokai Pro (`monokai-pro-vscode` + icons).
- **PlantUML**: points at the public plantuml.com render server.
- **Atlascode**: Bitbucket integration enabled.
- **Chat tool auto-approve**: `uv` commands auto-approved in the integrated
  terminal's chat tools. Kept intentionally generic — project-specific
  auto-approve rules belong in that project's own `.vscode/settings.json`,
  not here.
- `keybindings.json` is currently empty (no custom overrides tracked).

`Brewfile`'s `vscode "..."` lines install the extensions themselves; these two
files carry the actual editor configuration.

## Databases

Postgres is used only to **connect to remote databases** — no server runs on this
machine — so the Brewfile tracks **`libpq`** (psql, pg_dump, pg_restore and the
client library) rather than a full `postgresql@N` distribution. A newer libpq
client talks to older servers fine.

`libpq` is keg-only, so Homebrew deliberately does not link it into the prefix's
`bin`. `config.fish` adds `$(brew --prefix)/opt/libpq/bin` to `PATH`; without
that, `psql` looks missing even when it is installed.

## Python tooling

`install_python_tools.sh` installs:

- **uv** (Astral) — fast package installer/resolver + project/Python-version
  manager (also replaces Rye, now maintenance-only).
- Via **pipx** (isolated): `ruff` (lint + format + import sorting, replacing
  black & isort) and `pyright`.

Workflow leans on **uv**, with Starship surfacing project details.

## AI & coding tools

- **Claude** desktop app + **Claude Code** CLI (`@anthropic-ai/claude-code`, npm global) —
  primary daily driver. See [`CLAUDE.md`](../CLAUDE.md) for how Claude Code should operate
  in this repo, plus the `machine-setup` and `drift-check` skills under `.claude/skills/`.
- **ChatGPT** desktop app — used occasionally, no CLI tooling tracked here.

## Per-tool setup scripts

Each is idempotent — verifies the app/binary exists, then configures it:

| Script | What it does |
|--------|--------------|
| `install_node.sh` | Ensures node + npm exist before the Brewfile's npm entries — via fnm without admin. **Sourced, not executed.** |
| `setup_shell.sh` | Makes Fish the interactive shell — `chsh` with admin, a zsh handoff without. |
| `setup_docker.sh` | Prefers Docker Desktop; falls back to starting a colima VM when Desktop isn't installed. |
| `setup_dock.sh` | Rebuilds the macOS Dock via `dockutil` — grouped layout (file mgmt → notes → dev/ops → web/AI → client/VDI → comms) with spacers; finds apps in `~/Applications` as well as `/Applications`; skips any app that isn't installed; disables `show-recents`. **Clears the Dock first**, so set `DOTFILES_SKIP_DOCK=1` to leave an existing Dock alone. |
| `setup_terraform.sh` | Verifies Terraform + Terragrunt, ensures `~/.terraform.d`. |
| `setup_beyondcompare.sh` | Symlinks the `bcomp` CLI into `/usr/local/bin`, or `~/.local/bin` without admin. |
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
