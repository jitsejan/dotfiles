#!/usr/bin/env bash
set -euo pipefail

echo "🧱 Setting up Dock..."

# Ensure dockutil is installed
if ! command -v dockutil &> /dev/null; then
  echo "❌ dockutil not found. Please install it with Homebrew: brew install dockutil"
  exit 1
fi

# Add an app to the Dock only if it's actually installed, so a cask removed
# from the Brewfile doesn't break this script.
add_app() {
  local app="$1"
  if [[ -d "$app" ]]; then
    dockutil --add "$app" --no-restart
  else
    echo "  ↷ skipping $app (not installed)"
  fi
}

# Clear current Dock items
dockutil --remove all --no-restart

# -----------------------
# 🗂️ File Management (Far Left)
# -----------------------
add_app "/Applications/Beyond Compare.app"
dockutil --add '' --type spacer --section apps --no-restart

# -----------------------
# 🧠 Notes & Knowledge
# -----------------------
add_app "/Applications/Obsidian.app"
add_app "/System/Applications/Notes.app"
dockutil --add '' --type spacer --section apps --no-restart

# -----------------------
# 👨‍💻 Dev & Ops
# -----------------------
add_app "/Applications/Fork.app"
add_app "/Applications/Ghostty.app"
add_app "/Applications/Visual Studio Code.app"
dockutil --add '' --type spacer --section apps --no-restart

# -----------------------
# 🌐 Web & AI
# -----------------------
add_app "/Applications/Google Chrome.app"
add_app "/Applications/Microsoft Edge.app"
add_app "/Applications/ChatGPT.app"
add_app "/Applications/Claude.app"
add_app "/Applications/Safari.app"
dockutil --add '' --type spacer --section apps --no-restart

# -----------------------
# 🧘 Lifestyle & System
# -----------------------
add_app "/System/Applications/Music.app"
add_app "/System/Applications/Messages.app"
add_app "/System/Applications/System Settings.app"

# -----------------------
# 📂 Folders
# -----------------------
dockutil --add '~/Downloads' --view grid --display folder --sort dateadded --section others --no-restart

# Restart Dock
killall Dock
echo "✅ Dock setup complete!"
