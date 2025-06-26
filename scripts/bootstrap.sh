#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Bootstrapping your dev environment..."

OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
  ./scripts/install_brew.sh
elif [[ "$OS" == "Linux" ]]; then
  ./scripts/install_apt.sh || echo "Skip (not implemented)"
else
  echo "❌ Unsupported OS: $OS"
  exit 1
fi

./scripts/install_python_tools.sh || true
./scripts/install_apps.sh || true
./scripts/install_whisperx.sh || true

echo "🔗 Symlinking configs..."
mkdir -p ~/.config

link_config() {
  local src=$1
  local dest=$2
  echo "  → Linking $src → $dest"
  ln -sf "$PWD/$src" "$dest"
}

link_config ".config/kitty"        "$HOME/.config/kitty"
link_config ".config/fish"         "$HOME/.config/fish"
link_config ".config/starship.toml" "$HOME/.config/starship.toml"

# Optional: Zed editor config
ZED_DEST="$HOME/Library/Application Support/dev.zed.Zed/settings.json"
ZED_SRC=".config/zed/settings.json"
if [[ -f "$ZED_SRC" ]]; then
  mkdir -p "$(dirname "$ZED_DEST")"
  echo "  → Linking $ZED_SRC → $ZED_DEST"
  ln -sf "$PWD/$ZED_SRC" "$ZED_DEST"
fi

echo "✅ Dotfiles setup complete!"
