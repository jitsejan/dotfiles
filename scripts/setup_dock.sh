#!/usr/bin/env bash
set -euo pipefail

echo "🧱 Setting up Dock..."

# Ensure dockutil is installed
if ! command -v dockutil &> /dev/null; then
  echo "❌ dockutil not found. Please install it with Homebrew: brew install dockutil"
  exit 1
fi

# Clear current Dock items
dockutil --remove all --no-restart

# -----------------------
# 🧠 Notes & Knowledge
# -----------------------
dockutil --add "/Applications/Obsidian.app" --no-restart
dockutil --add "/System/Applications/Notes.app" --no-restart
dockutil --add '' --type spacer --section apps --no-restart

# -----------------------
# 👨‍💻 Dev & Ops
# -----------------------
dockutil --add "/Applications/Fork.app" --no-restart
dockutil --add "/Applications/Ghostty.app" --no-restart
dockutil --add "/Applications/Visual Studio Code.app" --no-restart
dockutil --add '' --type spacer --section apps --no-restart

# -----------------------
# 🌐 Web & AI
# -----------------------
dockutil --add "/Applications/Google Chrome.app" --no-restart
dockutil --add "/Applications/Microsoft Edge.app" --no-restart
dockutil --add "/Applications/ChatGPT.app" --no-restart
dockutil --add "/Applications/Claude.app" --no-restart
dockutil --add "/Applications/Safari.app" --no-restart
dockutil --add '' --type spacer --section apps --no-restart

# -----------------------
# 🧘 Lifestyle & System
# -----------------------
# dockutil --add "/System/Applications/Calendar.app" --no-restart
# dockutil --add "/System/Applications/Reminders.app" --no-restart
dockutil --add "/System/Applications/Music.app" --no-restart
dockutil --add "/System/Applications/Messages.app" --no-restart
dockutil --add "/System/Applications/System Settings.app" --no-restart
# dockutil --add "/System/Applications/Siri.app" --no-restart
# dockutil --add "/System/Applications/Home.app" --no-restart

# -----------------------
# 📂 Folders
# -----------------------
dockutil --add '~/Downloads' --view grid --display folder --sort dateadded --section others --no-restart

# Restart Dock
killall Dock
echo "✅ Dock setup complete!"
