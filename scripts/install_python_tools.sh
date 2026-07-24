#!/usr/bin/env bash
set -e

echo "🐍 Installing Python tools..."

# uv is installed via Brewfile — nothing to do here.

# Python dev tools via pipx.
# ruff covers linting + formatting + import sorting (replaces black & isort).
pipx install ruff pyright
