---
name: machine-setup
description: Provision this Mac from this dotfiles repo, step by step. Use when the user says "get my machine ready", "set up this Mac", "provision this laptop", "run bootstrap", or similar — including a brand-new machine.
---

# Machine setup

Drives `scripts/bootstrap.sh` on behalf of the user, but does it stage by stage
with a checkpoint after each one, rather than firing the whole script and hoping.
Several stages need something from the user (a sudo password, clicking through a
GUI installer, Obsidian's plugin browser) — catch those explicitly instead of
letting the script hang or silently continue past a failure.

## 0. Confirm prerequisites (chicken-and-egg check)

You (Claude Code) are running, so the absolute minimum is already met. Still verify:

```bash
command -v brew || echo "MISSING: Homebrew"
command -v git  || echo "MISSING: git"
```

If Homebrew is missing, this is likely a from-scratch Mac — tell the user
`scripts/install_brew.sh` will install it as part of stage 1 below, no separate
action needed. If `git` is missing, stop and tell the user to install Xcode
Command Line Tools first (`xcode-select --install`) since cloning this repo
already required git — this case should be rare.

Confirm you're in the repo root (`ls Brewfile scripts/bootstrap.sh` should both
resolve) before continuing.

## 1. Pre-flight

Run the Swift/CLT check that `bootstrap.sh` itself runs, but surface it before
starting rather than mid-script:

```bash
printf 'print("ok")\n' | swift - >/dev/null 2>&1 || echo "Swift/CLT toolchain looks broken"
```

If broken, tell the user to run `sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --install`
and wait for it to finish before continuing — casks that move `.app` bundles fail
cryptically otherwise.

## 2. Homebrew + Brewfile (`scripts/install_brew.sh`)

Run it. This is the longest stage (dozens of casks/formulae) and may need the
user to approve macOS install dialogs for some casks (e.g. Docker Desktop's
license prompt). Let the user know before starting that this stage runs longest
and to keep an eye out for any GUI prompts.

After it finishes, checkpoint: `brew bundle check --file=Brewfile`. If it reports
missing entries, note which ones and continue rather than blocking — some casks
(rare ones, or ones needing manual license acceptance) can be retried after.

## 3. Fish as login shell

`bootstrap.sh` handles this inline (adds fish to `/etc/shells`, runs `chsh`).
**This step needs the user's account password** — `chsh` will prompt interactively.
Tell the user to expect a password prompt right before running this part.

## 4. Python tooling (`scripts/install_python_tools.sh`)

Run it, then checkpoint: `pipx list` should show `ruff` and `pyright`.

## 5. npm globals (`scripts/install_apps.sh`)

Mostly a no-op note (npm globals live in the Brewfile and installed in stage 2).
Run it anyway for consistency, then checkpoint: `npm ls -g --depth=0`.

## 6. Per-tool setup scripts

Run each of these, checkpointing after all of them rather than one by one (they're
fast and mostly idempotent checks):

```
scripts/setup_obsidian.sh
scripts/setup_docker.sh
scripts/setup_beyondcompare.sh
scripts/setup_fork.sh
scripts/setup_terraform.sh
scripts/setup_git_filter_repo.sh
scripts/setup_dock.sh
```

Known manual follow-ups to flag to the user afterward:
- **Docker Desktop** — `setup_docker.sh` launches it and waits up to 60s for the
  daemon; if it's still not up, tell the user to check Docker Desktop manually.
- **Beyond Compare CLI symlink** — `setup_beyondcompare.sh` needs `sudo` for the
  `/usr/local/bin/bcomp` symlink; expect a password prompt.
- **Obsidian community plugins** — `setup_obsidian.sh` pre-configures plugin
  settings but Bases and Notebook Navigator must be installed once manually via
  Obsidian → Settings → Community plugins → Browse. Tell the user this explicitly;
  it cannot be automated from the CLI.

## 7. Symlink configs

```bash
mkdir -p ~/.config
```
then symlink (matching `bootstrap.sh`'s `link_config` logic — safe to re-run,
replaces any existing file/dir at the destination):
- `.config/ghostty` → `~/.config/ghostty`
- `.config/starship.toml` → `~/.config/starship.toml`
- `.config/fish` → `~/.config/fish`

Checkpoint: `readlink ~/.config/fish` should point back into the repo.

## 8. Final report

Summarize for the user:
- Which stages completed cleanly.
- Any Brewfile entries `brew bundle check` still flags as missing (with a note to
  re-run `brew bundle --file=Brewfile` later to retry).
- The manual follow-ups from stage 6 that still need the user's action (Obsidian
  plugins especially — this one is easy to forget).
- Whether the login shell change requires a terminal restart to take effect.

Do not claim full success if any stage failed — report exactly what's done and
what's still outstanding, so the user knows what to check before trusting the
machine is ready.
