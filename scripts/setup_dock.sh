#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Setting up Dock..."
activate_brew || true

# This script clears the Dock and rebuilds it from the layout below, which throws
# away anything not listed — including apps a managed Mac's IT pushed there. That
# is the intent when you run it deliberately, but it is a poor default the first
# time you provision a machine, before the apps it wants to add even exist.
# DOTFILES_SKIP_DOCK=1 opts out for a run.
if [[ "${DOTFILES_SKIP_DOCK:-0}" == "1" ]]; then
  skip "Dock rebuild (DOTFILES_SKIP_DOCK=1)"
  exit 0
fi

# The Dock is per-user state, so dockutil needs no admin — but the apps it points
# at may live in ~/Applications on a no-admin machine, hence find_app.
if ! command -v dockutil &>/dev/null; then
  warn "dockutil not found. Install it with: brew install dockutil"
  exit 0
fi

# Add an app by bundle name, wherever it is installed. Skips silently when the
# app is absent so a cask removed from the Brewfile doesn't break the script.
add_app() {
  local name="$1" path
  if path="$(find_app "$name")"; then
    dockutil --add "$path" --no-restart >/dev/null
    echo "  + $name"
  else
    skip "$name (not installed)"
  fi
}

# Add the first of several candidate bundle names that is actually installed.
# Used where one app has more than one common bundle name (Homebrew's "iTerm.app"
# versus a hand-installed "iTerm 2.app") so only one icon ends up in the Dock.
add_first_app() {
  local name path
  for name in "$@"; do
    if path="$(find_app "$name")"; then
      dockutil --add "$path" --no-restart >/dev/null
      echo "  + $name"
      return 0
    fi
  done
  skip "$* (none installed)"
}

spacer()       { dockutil --add '' --type spacer --section apps --no-restart >/dev/null; }
small_spacer() { dockutil --add '' --type small-spacer --section apps --no-restart >/dev/null; }

# Clear current Dock items
dockutil --remove all --no-restart >/dev/null

# 🗂️ File Management (Far Left)
add_app "Beyond Compare.app"
spacer

# 🧠 Notes & Knowledge
add_app "Obsidian.app"
add_app "Notes.app"
spacer

# 👨‍💻 Dev & Ops
add_first_app "iTerm 2.app" "iTerm.app"
add_app "Fork.app"
add_app "Visual Studio Code.app"
add_app "Bruno.app"
spacer

# 🌐 Web & AI
add_app "Google Chrome.app"
small_spacer
add_app "ChatGPT.app"
add_app "Claude.app"
add_app "Safari.app"
spacer

# 🧘 Lifestyle & System
add_app "Music.app"
add_app "Messages.app"
add_app "System Settings.app"

# 📂 Folders
dockutil --add '' --type flex-spacer --section others --no-restart >/dev/null
dockutil --add "$HOME/Downloads" --view grid --display folder --sort dateadded --section others --no-restart >/dev/null

# Stop macOS from auto-adding recently used apps — keeps this curated layout
# intact instead of growing an unmanaged tail of icons. This writes the user's
# own preference domain, so it works without admin.
defaults write com.apple.dock show-recents -bool false

# Restart through launchd rather than `killall Dock`. A bare kill leaves the Dock
# to be respawned by launchd anyway, but it has been observed coming back in a
# state where the process runs and nothing draws — launchd reported the agent
# exiting with code 1 across repeated respawns. kickstart -k tears the service
# down and brings it up cleanly, which recovers reliably.
if ! launchctl kickstart -k "gui/$(id -u)/com.apple.Dock.agent" 2>/dev/null; then
  killall Dock 2>/dev/null || true
fi
ok "Dock setup complete"
