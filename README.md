# jitsejan/dotfiles

![CI](https://github.com/jitsejan/dotfiles/actions/workflows/ci.yml/badge.svg)

Personal terminal setup using:
- 👻 Ghostty terminal
- 🚀 Starship prompt with Git + Python (uv)
- 🍺 Brewfile for reproducible packages
- 🐍 Python tools like ruff and pyright
- 🔒 Works with or without local admin rights

## 📦 Setup

### New Mac, nothing installed yet

Claude Code isn't on the machine yet, so this first bit is manual — install
Homebrew, then Claude Code, then hand the rest to Claude:

```bash
# 1. Homebrew (if not already present)
#    With admin rights:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#    Without admin rights (the official installer needs sudo) — user-owned prefix:
mkdir -p ~/homebrew && curl -fsSL https://github.com/Homebrew/brew/tarball/master \
  | tar xz --strip-components 1 -C ~/homebrew
export PATH="$HOME/homebrew/bin:$PATH"

# 2. Claude Code
brew install --cask claude-code   # or: npm install -g @anthropic-ai/claude-code

# 3. Clone the repo and hand off
git clone git@github.com:jitsejan/dotfiles.git ~/dotfiles
cd ~/dotfiles
claude
```

Then tell Claude: **"get my machine ready"** — it runs the `machine-setup` skill,
which drives `./scripts/bootstrap.sh` step by step and flags anything that needs
manual attention (sudo prompts, Docker Desktop's first launch, Obsidian plugins).

### Already have Claude Code

```bash
git clone git@github.com:jitsejan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh
```

## 🔒 No admin rights?

`bootstrap.sh` detects this automatically and adapts: Homebrew runs from a
user-owned prefix, casks install to `~/Applications`, containers come from colima
instead of Docker Desktop, and zsh hands off to Fish since `chsh` needs `sudo`.
The handful of `.pkg`-installer casks that genuinely can't be installed are
skipped and listed at the end of the run.

See [No-admin mode](docs/setup.md#no-admin-mode) for the full breakdown.

See [`docs/setup.md`](docs/setup.md) for a full breakdown of the repo, the
approach, and how the machine is provisioned. See [`CLAUDE.md`](CLAUDE.md) for
how Claude Code should operate in this repo.
