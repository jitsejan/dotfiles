# CLAUDE.md

This repo is JJ's personal macOS dotfiles — the reproducible source of truth for
provisioning his development machine. See [`docs/setup.md`](docs/setup.md) for the
full breakdown of layout, bootstrap flow, and each tool. Read that before making
structural changes.

## Rules for working in this repo

- **The Brewfile is the source of truth for installed software.** Never run
  `brew install` / `brew install --cask` ad hoc when asked to add a tool — add the
  entry to `Brewfile` instead, then run `brew bundle`. The Mac's actual state should
  always be derivable from the Brewfile, not the other way around.
- **Idempotent scripts.** Every `scripts/*.sh` must check "is this already done?"
  before acting, so re-running `bootstrap.sh` is always safe.
- **Symlinks, not copies.** Tracked configs (`.config/fish`, `.config/ghostty`,
  `starship.toml`) are symlinked into place — never `cp` a tracked config into its
  live location.
- **Secrets stay out of git.** Check `.gitignore` before tracking anything under
  `.config/` — `fish_variables` and similar sensitive stores must stay ignored.
- **One PR per change, on a branch.** Never commit directly to `master`. Push a
  branch, open a PR, wait for CI (`.github/workflows/ci.yml`: shellcheck + Brewfile
  validation) to pass, then merge.
- **New shell scripts must pass `shellcheck --severity=error`** (CI enforces this).

## Skills

- **`machine-setup`** — drives `scripts/bootstrap.sh` step by step on a new or
  existing Mac, checkpointing after each stage and surfacing manual steps (sudo
  prompts, Docker Desktop first-launch, Obsidian plugin install) instead of letting
  them fail silently. Use this whenever the user asks to set up, provision, or
  reconcile a machine — including "I got a new laptop, get it ready."
- **`drift-check`** — compares what's actually installed (`brew list`, VS Code
  extensions, npm globals) against the Brewfile and reports/fixes the gaps. Use this
  for "check my Mac", "is anything untracked", or periodic audits.

## Common tasks

- **Add a package** → edit `Brewfile`, run `brew bundle --file=Brewfile`, commit.
- **Tweak shell/prompt** → edit the symlinked file in the repo directly (it's live).
- **Audit drift** → use the `drift-check` skill, or manually
  `brew bundle dump --file=- --describe` and diff against `Brewfile`.
- **Provision a new machine** → use the `machine-setup` skill, or manually
  `git clone ... && ./scripts/bootstrap.sh`.
