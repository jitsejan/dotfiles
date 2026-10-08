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

## Before anything: which mode is this?

```bash
dsmemberutil checkmembership -U "$(whoami)" -G admin
```

This changes several stages below, so establish it first and tell the user which
mode the run will use. On a **no-admin** machine, never suggest a `sudo` command
as the fix for a failing stage — find the user-scoped alternative or record it as
something to ask IT for. `scripts/lib/common.sh` exposes `no_admin`,
`brew_prefix`, `app_install_dir`, `find_app` and `writable_bin_dir`; use those
rather than assuming `/opt/homebrew` and `/Applications`.

## 0. Confirm prerequisites (chicken-and-egg check)

You (Claude Code) are running, so the absolute minimum is already met. Still verify:

```bash
command -v brew || echo "MISSING: Homebrew"
command -v git  || echo "MISSING: git"
```

If Homebrew is missing, this is likely a from-scratch Mac — tell the user
`scripts/install_brew.sh` will install it as part of stage 1 below, no separate
action needed. Without admin it goes into a user-owned prefix (`~/homebrew`)
rather than `/opt/homebrew`, because the official installer needs `sudo`.

If `git` is missing, stop and tell the user to install Xcode
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
cryptically otherwise. **Without admin this is an IT request, not a command the
user can run** — flag it as blocked rather than handing them a `sudo` line.

## 2. Homebrew + Brewfile (`scripts/install_brew.sh`)

Run it. This is the longest stage (dozens of casks/formulae) and may need the
user to approve macOS install dialogs for some casks (e.g. Docker Desktop's
license prompt). Let the user know before starting that this stage runs longest
and to keep an eye out for any GUI prompts.

On a no-admin machine, expect this stage to be slower still: a user-prefix
Homebrew has to build from source any formula whose bottle isn't relocatable.
Four casks (`zoom`, `mactex`, `windows-app`, `intune-company-portal`) are
excluded from the Brewfile entirely — that's expected, not a failure.

After it finishes, checkpoint: `brew bundle check --file=Brewfile`. If it reports
missing entries, note which ones and continue rather than blocking — some casks
(rare ones, or ones needing manual license acceptance) can be retried after.

## 3. Fish as the interactive shell (`scripts/setup_shell.sh`)

**With admin:** adds fish to `/etc/shells` and runs `chsh`. This needs the user's
account password — tell them to expect a prompt right before running it.

**Without admin:** `chsh` is unusable (it validates against root-owned
`/etc/shells`). The script appends a marked block to `~/.zshrc` that sources the
tracked `.config/zsh/launch-fish.zsh`, which `exec`s fish for interactive shells.
Do **not** checkpoint with `dscl . -read ~/ UserShell` — the login shell
legitimately stays `/bin/zsh` in this mode, so that check looks like a failure
when everything is fine. Check that the hook is wired up instead, then have the
user open a new terminal tab:

```bash
grep -c 'dotfiles: fish handoff' ~/.zshrc   # 2 when the block is present
readlink ~/.config/zsh                      # points into the repo
```

The handoff deliberately does *not* fire for `zsh -ic '<command>'`, non-tty
shells, or when `DOTFILES_NO_FISH=1` is set — so probing it with `zsh -ic` will
correctly show zsh, not fish. That is the guard working, not a broken setup.

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
- **Docker without admin** — `setup_docker.sh` starts a colima VM instead. The
  *first* `colima start` downloads a VM image and takes several minutes; don't
  mistake that for a hang.
- **Beyond Compare CLI symlink** — with admin this needs `sudo` for
  `/usr/local/bin/bcomp` (expect a password prompt); without, it links into
  `~/.local/bin` and needs nothing.
- **Dock rebuild** — `setup_dock.sh` *clears* the Dock before rebuilding it. On a
  managed Mac that discards IT-placed icons, and on a partly provisioned machine
  it rebuilds an almost-empty Dock. Ask the user before running it the first
  time; `DOTFILES_SKIP_DOCK=1` skips it.
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
- `.config/starship.toml` → `~/.config/starship.toml`
- `.config/fish` → `~/.config/fish`
- `.config/zsh` → `~/.config/zsh`

The iTerm2 Monokai profile is linked separately by `setup_iterm2.sh`, into
`~/Library/Application Support/iTerm2/DynamicProfiles/` rather than `~/.config`.
Making it the *default* profile can't be scripted (iTerm2 rewrites that plist on
quit), so it surfaces as a manual step — surface it to the user rather than
skipping past it.

Note `bootstrap.sh` does this *before* the shell stage, since `setup_shell.sh`
needs the zsh handoff snippet to already be linked.

Checkpoint: `readlink ~/.config/fish` should point back into the repo.

## 8. Final report

Summarize for the user:
- Which stages completed cleanly.
- Any Brewfile entries `brew bundle check` still flags as missing (with a note to
  re-run `brew bundle --file=Brewfile` later to retry).
- The manual follow-ups from stage 6 that still need the user's action (Obsidian
  plugins especially — this one is easy to forget).
- Whether the login shell change requires a terminal restart to take effect.
- On a no-admin machine: the software that was skipped because it needs an admin
  password, and what the user should do about each (ask IT, or use the listed
  alternative). `bootstrap.sh` prints this list at the end of its own run.

Do not claim full success if any stage failed — report exactly what's done and
what's still outstanding, so the user knows what to check before trusting the
machine is ready.
