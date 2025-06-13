#!/usr/bin/env bash
set -e

if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update
echo $PWD;
brew bundle --file="$PWD/Brewfile"

