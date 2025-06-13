#!/usr/bin/env bash
set -e

echo "🐍 Installing Python tools..."

# Install uv
if ! command -v uv &>/dev/null; then
  curl -sSf https://astral.sh/uv/install.sh | sh
fi

# Install Rye
if ! command -v rye &>/dev/null; then
  curl -sSf https://rye-up.com/get | bash
fi

# Optionally install common tools
pipx install black ruff isort pyright
