#!/usr/bin/env bash
set -e

echo "🚀 Bootstrapping your dev environment..."

# Safely (re)create a symlink at $2 pointing to $1, replacing any existing
# file/dir/symlink so we never nest a link inside an existing directory.
link_config() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "  ✓ $dest already linked"
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "  ↻ replacing existing $dest"
    rm -rf "$dest"
  fi
  ln -s "$src" "$dest"
  echo "  → linked $dest"
}

# Warn early if the Swift/Command Line Tools toolchain is broken — otherwise
# Homebrew casks that move .app bundles fail cryptically mid-run.
check_swift_toolchain() {
  if ! printf 'print("ok")\n' | swift - >/dev/null 2>&1; then
    echo "⚠️  Swift / Command Line Tools look broken — casks that move .app bundles may fail."
    echo "    Fix: sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --install"
  fi
}

OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
  check_swift_toolchain
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
./scripts/setup_dock.sh || true

echo "🔗 Symlinking configs..."
mkdir -p ~/.config
link_config "$PWD/.config/ghostty" ~/.config/ghostty
link_config "$PWD/.config/starship.toml" ~/.config/starship.toml
link_config "$PWD/.config/fish" ~/.config/fish

echo "✅ Dotfiles setup complete!"
