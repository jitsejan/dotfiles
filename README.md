# jitsejan/dotfiles

![CI](https://github.com/jitsejan/dotfiles/actions/workflows/ci.yml/badge.svg)

Personal terminal setup using:
- 👻 Ghostty terminal
- 🚀 Starship prompt with Git + Python (uv)
- 🍺 Brewfile for reproducible packages
- 🐍 Python tools like ruff and pyright

## 📦 Setup

### New Mac, nothing installed yet

Claude Code isn't on the machine yet, so this first bit is manual — install
Homebrew, then Claude Code, then hand the rest to Claude:

```bash
# 1. Homebrew (if not already present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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

See [`docs/setup.md`](docs/setup.md) for a full breakdown of the repo, the
approach, and how the machine is provisioned. See [`CLAUDE.md`](CLAUDE.md) for
how Claude Code should operate in this repo.
