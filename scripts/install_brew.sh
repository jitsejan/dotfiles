#!/usr/bin/env bash
set -e

if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update

echo "🍺 Installing packages from $PWD/Brewfile..."
if ! brew bundle --file="$PWD/Brewfile"; then
  echo "⚠️  Some Brewfile entries failed (e.g. a flaky cask download)."
  echo "   Continuing setup — re-run 'brew bundle' later to retry the failures."
fi

