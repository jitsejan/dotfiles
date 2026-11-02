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

# Some formulae prompt on stdin during install — microsoft/mssql-release's
# msodbcsql18 falls back to `STDIN.gets` for EULA acceptance when
# HOMEBREW_ACCEPT_EULA is unset. In an unattended bootstrap that blocks forever
# with no output. Redirecting stdin from /dev/null turns any such prompt into an
# immediate failure that `brew bundle` reports, instead of a silent hang.
#
# The EULA is deliberately NOT auto-accepted here: accepting a licence is the
# user's decision, not the script's. An already-exported HOMEBREW_ACCEPT_EULA is
# honoured, and if the driver is missing the manual step below says what to run.
# brew bundle exits non-zero if any single entry fails. A flaky cask download or a
# cask that turns out to need admin should not abort the whole bootstrap, so the
# failure is reported and the run continues.
# Redirecting stdin is not enough on its own. `brew` runs a formula's install in
# a separate build process, so the </dev/null here never reaches msodbcsql18's
# `STDIN.gets` — on an *upgrade* of an already-installed driver it loops forever
# printing "Please enter YES or NO" with no way to answer. That hung a bootstrap
# run for 50 minutes before this guard existed.
#
# If the driver is already installed, its EULA was accepted at install time, so
# re-asserting that during an unattended upgrade is a restatement of a decision
# the user already made — not a new one. Only ever set for an existing install:
# a first-time install still falls through to the manual step below.
if brew list --versions msodbcsql18 >/dev/null 2>&1; then
  export HOMEBREW_ACCEPT_EULA="${HOMEBREW_ACCEPT_EULA:-Y}"
fi

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

# Surface the one entry that cannot complete unattended without an explicit
# licence acceptance from the user.
if ! brew list --versions msodbcsql18 >/dev/null 2>&1; then
  manual_step "Microsoft's ODBC driver needs you to accept its EULA (https://aka.ms/odbc18eula). If you accept, run: HOMEBREW_ACCEPT_EULA=Y brew install microsoft/mssql-release/msodbcsql18"
fi
