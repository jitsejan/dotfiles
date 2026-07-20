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

# Make Fish the default shell if not already
FISH_PATH="$(which fish)"
CURRENT_SHELL="$(dscl . -read ~/ UserShell | awk '{print $2}')"

if [[ "$CURRENT_SHELL" != "$FISH_PATH" ]]; then
  echo "💡 Changing login shell to: $FISH_PATH"
  sudo sh -c "echo $FISH_PATH >> /etc/shells"
  chsh -s "$FISH_PATH"
else
  echo "✅ Fish is already your login shell"
fi

./scripts/install_python_tools.sh || true
./scripts/install_apps.sh || true
./scripts/setup_obsidian.sh || true
./scripts/setup_codex.sh || true
./scripts/setup_docker.sh || true
./scripts/setup_beyondcompare.sh || true
./scripts/setup_fork.sh || true
./scripts/setup_terraform.sh || true
./scripts/setup_git_filter_repo.sh || true
./scripts/setup_dock.sh || true

echo "🔗 Symlinking configs..."
mkdir -p ~/.config
ln -sf "$PWD/.config/ghostty" ~/.config/ghostty
ln -sf "$PWD/.config/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/.config/fish" ~/.config/fish

echo "✅ Dotfiles setup complete!"
