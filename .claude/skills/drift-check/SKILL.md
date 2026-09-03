---
name: drift-check
description: Compare what's actually installed on this Mac (brew packages/casks, VS Code extensions, npm globals) against the Brewfile and report or fix the gaps. Use when the user asks to check the Mac, audit for drift, find untracked/unused software, or clean up the machine.
---

# Drift check

The Brewfile is meant to be the source of truth (see `CLAUDE.md`), but installs
made outside a `Brewfile` edit — a one-off `brew install`, an app installed by
double-clicking a `.dmg`, a VS Code extension installed from the marketplace UI —
drift the Mac away from it silently. This skill finds and reconciles that drift.

## 1. Gather actual state

```bash
brew list --formula | sort > /tmp/brew_formula.txt
brew list --cask | sort > /tmp/brew_cask.txt
brew leaves | sort > /tmp/brew_leaves.txt   # top-level formulae only, excludes deps
npm ls -g --depth=0
code --list-extensions | sort   # if `code` CLI is available
```

## 2. Gather tracked state

```bash
grep -oE '^brew "[^"]+"' Brewfile | sed 's/brew "//;s/"//' | sort > /tmp/tracked_formula.txt
grep -oE '^cask "[^"]+"' Brewfile | sed 's/cask "//;s/"//' | sort > /tmp/tracked_cask.txt
grep -oE '^vscode "[^"]+"' Brewfile | sed 's/vscode "//;s/"//' | sort
grep -oE '^npm "[^"]+"' Brewfile | sed 's/npm "//;s/"//' | sort
```

Note: some formulae are tracked under a tap-qualified name (e.g.
`microsoft/mssql-release/msodbcsql18`) but `brew list` reports the bare name
(`msodbcsql18`). Don't flag these as untracked — check both forms before
concluding something is missing.

## 3. Diff

```bash
comm -23 /tmp/brew_leaves.txt /tmp/tracked_formula.txt   # installed leaves, not tracked
comm -23 /tmp/brew_cask.txt /tmp/tracked_cask.txt        # installed casks, not tracked
comm -13 /tmp/brew_formula.txt /tmp/tracked_formula.txt  # tracked, not installed
comm -13 /tmp/brew_cask.txt /tmp/tracked_cask.txt         # tracked, not installed
```

Do the equivalent by hand for VS Code extensions and npm globals (small lists,
just eyeball the diff).

## 4. Classify each gap before acting

Don't mechanically add everything untracked or remove everything unused — some
untracked items are dependencies pulled in transitively (not real signal), and
some casks share an underlying formula under two different names (e.g.
`gcloud-cli` / `google-cloud-sdk` were the same package — uninstalling one by
name silently removed the other's binaries). Before uninstalling anything by
cask/formula name, run `brew info <name>` and check whether another tracked
package aliases the same install.

For each gap, ask (or infer from context/recency) whether it's:
- **In active use, untracked** → add to `Brewfile`.
- **Installed but abandoned** (e.g. replaced by something else per recent git
  history — check `git log --oneline -20` for context) → offer to uninstall.
- **A transitive dependency, not a deliberate install** → leave alone, don't
  track it.
- **Tracked but not installed** → either install it (`brew bundle --file=Brewfile`)
  or remove the stale entry if it's no longer wanted.

When in doubt on a specific item, ask the user rather than guessing — this
mirrors how the original Mac audit worked (see git history around the
`chore/mac-cleanup-audit` branch/PR for the pattern).

## 5. Apply changes

- Brewfile edits: plain text edits, one line per package/cask/extension/npm entry,
  keep it grouped under the relevant `# comment` section.
- Uninstalls: `brew uninstall <formula>` / `brew uninstall --cask <cask>` —
  confirm with the user first since this is a real, if reversible, action on
  their machine.
- After any Brewfile edit, sanity-check it: `brew bundle check --file=Brewfile`
  (some "needs to be installed or updated" results are just outdated versions,
  not real gaps — don't chase those).

## 6. Ship it

Per `CLAUDE.md`: branch, commit, push, open a PR, wait for CI
(shellcheck + Brewfile validation), then merge. Don't commit directly to `master`.
