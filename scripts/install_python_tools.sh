#!/usr/bin/env bash
set -e

echo "🐍 Installing Python tools..."

# Install uv (package installer, resolver, and project/Python-version manager;
# also replaces Rye, which is now maintenance-only).
if ! command -v uv &>/dev/null; then
  curl -sSf https://astral.sh/uv/install.sh | sh
fi

# Python dev tools via pipx.
# ruff covers linting + formatting + import sorting (replaces black & isort).
pipx install ruff pyright
