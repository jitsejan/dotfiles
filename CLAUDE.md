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
- **Check bottle relocatability before adding a formula.** Homebrew lives in a
  user prefix here, and a bottle whose `cellar` is a hardcoded path (rather than
  `:any` / `:any_skip_relocation`) cannot be poured — Homebrew silently compiles
  it from source instead. That is fine for a small C library and catastrophic for
  anything that build-depends on LLVM: `node` and `opencode` each triggered a
  multi-hour LLVM 22 compile, which is why the no-admin branch swaps them for
  `fnm` and the `opencode-ai` npm package. Check with
  `brew info --json=v2 <formula>` and look at `bottle.stable.files.*.cellar`,
  plus `brew deps --include-build <formula> | grep llvm`.
- **This Mac has no admin rights.** Never write a script that calls `sudo`, `chsh`,
  or that writes to `/Applications`, `/usr/local/bin`, `/opt` or `/etc/shells`
  unconditionally — guard it behind `no_admin` from `scripts/lib/common.sh` and
  provide a user-scoped fallback. Resolve Homebrew's location with `brew_prefix`
  rather than hardcoding `/opt/homebrew`, and find apps with `find_app` so
  `~/Applications` is searched too. See [No-admin mode](docs/setup.md#no-admin-mode).
- **Every script sources `scripts/lib/common.sh`.** It provides admin detection
  (`no_admin`), path resolution (`brew_prefix`, `app_install_dir`, `find_app`,
  `writable_bin_dir`), output helpers (`step`/`ok`/`skip`/`warn`), and
  `manual_step` for recording things the user must do by hand. Don't reimplement
  these per script.
- **A missing optional tool is a warning, not a failure.** Setup scripts should
  `warn` and `exit 0` rather than `exit 1`, so one absent cask never makes a
  bootstrap run look broken.
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
- **New shell scripts must pass `shellcheck --severity=error`** (CI enforces this,
  across both `scripts/*.sh` and `scripts/lib/*.sh`).
- **Brewfile flags need the `HOMEBREW_` prefix.** `brew` strips other variables
  from the environment it evaluates the Brewfile in, so the no-admin switch is
  `HOMEBREW_DOTFILES_NO_ADMIN`, mirrored from `DOTFILES_NO_ADMIN` in `common.sh`.
  CI parses the Brewfile both ways.

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
- **Test the no-admin path on an admin Mac** → `DOTFILES_NO_ADMIN=1 ./scripts/bootstrap.sh`.
- **Re-run bootstrap without wiping the Dock** → `DOTFILES_SKIP_DOCK=1 ./scripts/bootstrap.sh`.
