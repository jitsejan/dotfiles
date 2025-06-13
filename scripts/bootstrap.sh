#!/usr/bin/env bash
set -e

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

echo "🔗 Symlinking configs..."
mkdir -p ~/.config
ln -sf "$PWD/.config/kitty" ~/.config/kitty
ln -sf "$PWD/.config/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/.config/fish" ~/.config/fish

echo "✅ Dotfiles setup complete!"
