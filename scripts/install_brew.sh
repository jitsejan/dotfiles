#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Where a no-admin Homebrew gets installed if there isn't one already. An existing
# install is always reused, wherever it lives, so this only applies to a fresh Mac.
NO_ADMIN_BREW_PREFIX="${NO_ADMIN_BREW_PREFIX:-$HOME/homebrew}"

install_brew_as_admin() {
  step "Installing Homebrew (admin install to the standard prefix)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

BREW_REPO_URL="https://github.com/Homebrew/brew"

# The official installer wants to chown /opt/homebrew, which needs sudo. Homebrew
# also supports a git checkout into any prefix the user owns; the tradeoff is
# that formulae without relocatable bottles get built from source.
#
# It must be a git checkout of `main`, not a tarball. The old recipe untarred
# `tarball/master`, but Homebrew renamed its branch to main: the master snapshot
# refuses every command ("Homebrew's master branch is no longer supported"), and
# a tarball has no .git, so the `brew update` it suggests cannot migrate it either.
install_brew_no_admin() {
  step "Installing Homebrew into $NO_ADMIN_BREW_PREFIX (no admin, user-owned prefix)..."
  # A leftover directory (an interrupted clone, or a tarball install missing
  # bin/brew) makes `git clone` refuse, so adopt it in place instead.
  if [[ -n "$(ls -A "$NO_ADMIN_BREW_PREFIX" 2>/dev/null)" ]]; then
    repair_tarball_brew "$NO_ADMIN_BREW_PREFIX" || {
      warn "Could not set up Homebrew in $NO_ADMIN_BREW_PREFIX — move it aside and re-run bootstrap."
      return 1
    }
  else
    git clone --depth=1 "$BREW_REPO_URL" "$NO_ADMIN_BREW_PREFIX"
  fi
  export PATH="$NO_ADMIN_BREW_PREFIX/bin:$NO_ADMIN_BREW_PREFIX/sbin:$PATH"
  warn "Formulae without a relocatable bottle will be compiled from source in a"
  warn "custom prefix. That is slower but needs no admin rights."
}

# Turn an existing user-prefix Homebrew that is not a git checkout (the old
# tarball install) into one tracking main, in place. Cellar/, Caskroom/ and the
# rest of the prefix are gitignored by Homebrew, so installed packages survive.
repair_tarball_brew() {
  local prefix="$1"
  step "Converting the existing Homebrew in $prefix to a git checkout of main..."
  # Chained with && because this runs in an `||` context, where set -e is off.
  git -C "$prefix" init -q &&
    { git -C "$prefix" remote remove origin 2>/dev/null || true; } &&
    git -C "$prefix" remote add origin "$BREW_REPO_URL" &&
    git -C "$prefix" fetch -q --depth=1 origin main &&
    git -C "$prefix" checkout -q -B main --force origin/main &&
    git -C "$prefix" branch -q --set-upstream-to=origin/main main ||
    return 1
  ok "Homebrew in $prefix now tracks main"
}

# Only a prefix the user owns is ever repaired; an admin install is left alone.
for candidate in "$NO_ADMIN_BREW_PREFIX" "$HOME/.brew" "$HOME/Documents/.brew"; do
  if [[ -x "$candidate/bin/brew" && ! -d "$candidate/.git" ]]; then
    repair_tarball_brew "$candidate" ||
      warn "Could not convert $candidate — fix by hand: rm -rf $candidate && re-run bootstrap."
  fi
done

# brew_prefix, not `command -v brew`: a user-prefix brew is usually not on PATH
# yet when bootstrap starts, and must be found on disk rather than reinstalled.
if existing_prefix="$(brew_prefix)"; then
  ok "Homebrew already installed at $existing_prefix"
elif no_admin; then
  install_brew_no_admin || true  # activate_brew below reports a missing brew
else
  install_brew_as_admin
fi

activate_brew || { warn "Homebrew is not on PATH — skipping package install."; exit 0; }
if ! brew --prefix >/dev/null 2>&1; then
  warn "brew is on PATH but not working — skipping package install. Output of 'brew --prefix':"
  brew --prefix || true
  exit 0
fi

ok "Using Homebrew prefix: $(brew_prefix)"
ok "Casks will install to: $(app_install_dir)"
mkdir -p "$(app_install_dir)"

brew update || warn "brew update failed — continuing with the current formula index."

# node must exist before `brew bundle` reaches the Brewfile's npm entries.
# Sourced, not executed, so the PATH it sets applies to the bundle run below.
# shellcheck source=scripts/install_node.sh
source "$SCRIPT_DIR/install_node.sh"

step "Installing packages from $REPO_ROOT/Brewfile..."
if no_admin; then
  echo "  (no-admin mode: entries needing sudo are excluded from the Brewfile)"
fi

# stdin is redirected from /dev/null so that a formula which prompts during
# install (a licence question, say) fails immediately and is reported by
# `brew bundle`, instead of blocking an unattended bootstrap forever. brew bundle
# exits non-zero if any single entry fails; a flaky cask download or a cask that
# turns out to need admin should not abort the whole bootstrap, so the failure is
# reported and the run continues.

# Verbose by default: without it brew bundle prints a list of "Installing x"
# lines and then nothing until it finishes, which is how a multi-hour LLVM
# source build went unnoticed (#114). DOTFILES_QUIET=1 restores the terse output
# for re-runs that have nothing new to install.
BUNDLE_FLAGS=(--file="$REPO_ROOT/Brewfile")
if [[ "${DOTFILES_QUIET:-0}" != "1" ]]; then
  BUNDLE_FLAGS+=(--verbose)
  echo "  (verbose: showing brew's output as it runs; set DOTFILES_QUIET=1 to hide it)"
fi

if ! brew bundle "${BUNDLE_FLAGS[@]}" </dev/null; then
  warn "Some Brewfile entries failed (e.g. a flaky download, or a cask that needs admin)."
  warn "Continuing setup — re-run 'brew bundle' later to retry the failures."
fi
