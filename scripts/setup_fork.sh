#!/usr/bin/env bash
set -e

echo "🍴 Checking Fork Git client..."

if [[ ! -d "/Applications/Fork.app" ]]; then
  echo "❌ Fork.app not found. Please install it first with 'brew install --cask fork'"
  exit 1
fi

echo "✅ Fork Git client found"

if ! git config --global user.name >/dev/null 2>&1 || ! git config --global user.email >/dev/null 2>&1; then
  echo "⚠️  Git user configuration not found. Consider setting:"
  echo "   git config --global user.name 'Your Name'"
  echo "   git config --global user.email 'your.email@example.com'"
else
  echo "✅ Git configured for: $(git config --global user.name) <$(git config --global user.email)>"
fi
