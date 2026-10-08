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

# The official installer wants to chown /opt/homebrew, which needs sudo. Homebrew
# also supports an untarred install into any prefix the user owns; the tradeoff is
# that formulae without relocatable bottles get built from source.
install_brew_no_admin() {
  step "Installing Homebrew into $NO_ADMIN_BREW_PREFIX (no admin, user-owned prefix)..."
  mkdir -p "$NO_ADMIN_BREW_PREFIX"
  curl -fsSL https://github.com/Homebrew/brew/tarball/master \
    | tar xz --strip-components 1 -C "$NO_ADMIN_BREW_PREFIX"
  export PATH="$NO_ADMIN_BREW_PREFIX/bin:$NO_ADMIN_BREW_PREFIX/sbin:$PATH"
  warn "Formulae without a relocatable bottle will be compiled from source in a"
  warn "custom prefix. That is slower but needs no admin rights."
}

if command -v brew >/dev/null 2>&1; then
  ok "Homebrew already installed at $(brew --prefix)"
elif no_admin; then
  install_brew_no_admin
else
  install_brew_as_admin
fi

activate_brew || { warn "Homebrew is not on PATH — skipping package install."; exit 0; }

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

if ! brew bundle --file="$REPO_ROOT/Brewfile" </dev/null; then
  warn "Some Brewfile entries failed (e.g. a flaky download, or a cask that needs admin)."
  warn "Continuing setup — re-run 'brew bundle' later to retry the failures."
fi

# Surface the one entry that cannot complete unattended without an explicit
# licence acceptance from the user.
if ! brew list --versions msodbcsql18 >/dev/null 2>&1; then
  manual_step "Microsoft's ODBC driver needs you to accept its EULA (https://aka.ms/odbc18eula). If you accept, run: HOMEBREW_ACCEPT_EULA=Y brew install microsoft/mssql-release/msodbcsql18"
fi
