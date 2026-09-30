#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Python CLI tools live here rather than in the Brewfile because pipx keeps each
# in its own virtualenv and installs prebuilt wheels into $HOME — no compiler, no
# admin. That matters more than usual on this machine: several of these have
# Homebrew formulae whose dependency trees would compile from source in a user
# prefix. harlequin is the clearest case — `brew install harlequin` pulls in gcc
# and llvm@22, neither of which has a relocatable bottle, for a tool that pip
# ships as a ready-made wheel.
#
# uv itself comes from the Brewfile (its bottle pours fine).

# tool -> extra packages to inject into its virtualenv (space separated, or "")
PIPX_TOOLS="ruff pyright harlequin"

# harlequin talks to DuckDB out of the box; Postgres needs its adapter injected
# into the same virtualenv so the `harlequin -a postgres` profile works.
INJECT_harlequin="harlequin-postgres"

step "Installing Python tools..."
activate_brew || true

if ! command -v pipx &>/dev/null; then
  warn "pipx not found. Install it with: brew install pipx"
  exit 0
fi

for tool in $PIPX_TOOLS; do
  if pipx list --short 2>/dev/null | grep -q "^$tool "; then
    ok "$tool already installed"
  elif pipx install "$tool" >/dev/null 2>&1; then
    ok "installed $tool"
  else
    warn "failed to install $tool"
    manual_step "Install the Python tool by hand: pipx install $tool"
    continue
  fi

  # Indirect expansion keeps this readable and works in bash 3.2, which macOS
  # ships — associative arrays would not.
  eval "extras=\${INJECT_${tool}:-}"
  for extra in $extras; do
    if pipx runpip "$tool" show "$extra" >/dev/null 2>&1; then
      ok "  $tool already has $extra"
    elif pipx inject "$tool" "$extra" >/dev/null 2>&1; then
      ok "  injected $extra into $tool"
    else
      warn "  failed to inject $extra into $tool"
    fi
  done
done
