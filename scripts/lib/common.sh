#!/usr/bin/env bash
# Shared helpers for the bootstrap scripts. Sourced, never executed directly.
#
# The central idea: this repo has to provision two very different machines — one
# where the user is a local admin (sudo, /Applications, /usr/local/bin all work)
# and one where they are not. Rather than forking the scripts, every script asks
# these helpers where things live and whether it may escalate.

# Guard against double-sourcing when one script sources another.
[[ -n "${DOTFILES_COMMON_SOURCED:-}" ]] && return 0
DOTFILES_COMMON_SOURCED=1

# --- Admin detection -------------------------------------------------------

# True when the current user is a local admin. dsmemberutil is the authoritative
# check on macOS; `sudo -n true` would also prompt-or-fail, but it pollutes the
# sudo timestamp and logs a failure, so prefer group membership.
is_admin() {
  case "$(uname -s)" in
    Darwin) dsmemberutil checkmembership -U "$(whoami)" -G admin 2>/dev/null | grep -q "is a member" ;;
    *) [[ "$(id -u)" -eq 0 ]] || groups 2>/dev/null | grep -qw sudo ;;
  esac
}

# DOTFILES_NO_ADMIN=1 forces the no-admin path even on an admin machine, which is
# how the mode gets tested without giving up privileges.
if [[ -z "${DOTFILES_NO_ADMIN:-}" ]]; then
  if is_admin; then DOTFILES_NO_ADMIN=0; else DOTFILES_NO_ADMIN=1; fi
fi
export DOTFILES_NO_ADMIN

# `brew` strips environment variables that are not HOMEBREW_-prefixed before
# evaluating the Brewfile, so the flag has to be mirrored under a name Homebrew
# will pass through. Without this the Brewfile always takes the admin branch.
export HOMEBREW_DOTFILES_NO_ADMIN="$DOTFILES_NO_ADMIN"

no_admin() { [[ "$DOTFILES_NO_ADMIN" == "1" ]]; }

# --- Locations -------------------------------------------------------------

# Where casks should drop .app bundles. Without admin, /Applications is read-only,
# so use the per-user Applications folder — macOS treats it as a first-class app
# location (Spotlight and Launchpad both index it).
app_install_dir() {
  if no_admin; then echo "$HOME/Applications"; else echo "/Applications"; fi
}

# Directories to search when checking "is this app installed?". Always search the
# per-user folder too, because an admin machine may still have user-scoped apps.
# ~/Documents is a legacy location: an earlier no-admin setup pointed
# HOMEBREW_CASK_OPTS there, so keep finding apps that were left behind.
app_search_dirs() {
  printf '%s\n' "$HOME/Applications" /Applications /System/Applications "$HOME/Documents"
}

# Echo the full path of an installed .app, or return 1. Takes the bundle name,
# e.g. find_app "Visual Studio Code.app".
find_app() {
  local name="$1" dir
  while IFS= read -r dir; do
    [[ -d "$dir/$name" ]] && { echo "$dir/$name"; return 0; }
  done < <(app_search_dirs)
  return 1
}

# Where user-scoped executables go when /usr/local/bin is not writable.
user_bin_dir() {
  echo "$HOME/.local/bin"
}

# A bin directory we can definitely write to, preferring the system one when the
# user is an admin so behaviour on an admin machine is unchanged.
writable_bin_dir() {
  if ! no_admin && [[ -w /usr/local/bin ]]; then
    echo /usr/local/bin
  else
    local dir; dir="$(user_bin_dir)"
    mkdir -p "$dir"
    echo "$dir"
  fi
}

# Homebrew's prefix. Resolve it rather than hardcoding /opt/homebrew, because a
# no-admin install lives somewhere under $HOME and that location can move.
# Order matters when more than one prefix exists: the documented fresh-install
# location first, then legacy user prefixes, then the admin defaults. Keep this
# list identical to the one in .config/fish/config.fish so bash and fish agree.
brew_prefix() {
  if command -v brew >/dev/null 2>&1; then
    brew --prefix
    return 0
  fi
  local candidate
  for candidate in "$HOME/homebrew" "$HOME/.brew" "$HOME/Documents/.brew" /opt/homebrew /usr/local; do
    [[ -x "$candidate/bin/brew" ]] && { echo "$candidate"; return 0; }
  done
  return 1
}

# Put brew on PATH for the rest of this script run, so a freshly installed brew
# is usable without the user opening a new shell.
activate_brew() {
  local prefix
  prefix="$(brew_prefix)" || return 1
  [[ ":$PATH:" == *":$prefix/bin:"* ]] || export PATH="$prefix/bin:$prefix/sbin:$PATH"
  local appdir
  appdir="$(app_install_dir)"
  export HOMEBREW_CASK_OPTS="--appdir=$appdir"
}

# --- Output ----------------------------------------------------------------

step() { echo "▶ $*"; }
ok()   { echo "  ✓ $*"; }
skip() { echo "  ↷ $*"; }
warn() { echo "  ⚠️  $*"; }

# Record something the user has to do by hand. bootstrap.sh prints the collected
# list at the end, so manual steps are not lost in the scroll of a long run.
MANUAL_STEPS_FILE="${MANUAL_STEPS_FILE:-${TMPDIR:-/tmp}/dotfiles-manual-steps.$$}"
export MANUAL_STEPS_FILE

manual_step() {
  echo "  📋 manual: $*"
  echo "- $*" >> "$MANUAL_STEPS_FILE"
}
