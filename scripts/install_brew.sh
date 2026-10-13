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

# msodbcsql18 cannot be installed unattended unless its EULA is pre-accepted.
# With HOMEBREW_ACCEPT_EULA unset the formula falls back to `STDIN.gets`, and
# because Homebrew runs a formula's install in a separate build process, the
# `</dev/null` on the bundle call below never reaches it. The run then blocks
# forever with no output rather than failing — it cost a 50-minute hang once on
# an upgrade, and hung again later on a first-time install.
#
# Accepting a licence is the user's decision, not the script's, so acceptance is
# recorded explicitly and read back here. Two things count as accepted:
#   - the driver is already installed, so it was accepted at install time;
#   - the user recorded it in the accepted-eulas file (see the manual step).
# This is machine-local state, deliberately not tracked in the repo: a licence
# acceptance belongs to the person on the machine, not to a git history.
#
# When it is NOT accepted the Brewfile omits the formula entirely (it reads
# HOMEBREW_DOTFILES_MSODBCSQL), so an unattended run cannot hang on it at all.
EULA_FILE="${DOTFILES_EULA_FILE:-$HOME/.config/dotfiles/accepted-eulas}"

msodbcsql_eula_accepted() {
  brew list --versions msodbcsql18 >/dev/null 2>&1 && return 0
  [[ -f "$EULA_FILE" ]] && grep -qx "msodbcsql18" "$EULA_FILE"
}

if msodbcsql_eula_accepted; then
  export HOMEBREW_ACCEPT_EULA="${HOMEBREW_ACCEPT_EULA:-Y}"
  export HOMEBREW_DOTFILES_MSODBCSQL=1
else
  export HOMEBREW_DOTFILES_MSODBCSQL=0
  manual_step "Microsoft's ODBC driver (msodbcsql18) is skipped until you accept its EULA (https://aka.ms/odbc18eula). To accept: mkdir -p ~/.config/dotfiles && echo msodbcsql18 >> ~/.config/dotfiles/accepted-eulas, then re-run bootstrap."
fi

# brew bundle exits non-zero if any single entry fails. A flaky cask download or
# a cask that turns out to need admin should not abort the whole bootstrap, so
# the failure is reported and the run continues. stdin is still closed so any
# other formula that tries to prompt fails fast instead of hanging.
if ! brew bundle --file="$REPO_ROOT/Brewfile" </dev/null; then
  warn "Some Brewfile entries failed (e.g. a flaky download, or a cask that needs admin)."
  warn "Continuing setup — re-run 'brew bundle' later to retry the failures."
fi
