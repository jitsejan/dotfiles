#!/usr/bin/env bash
set -e

echo "🔍 Checking Beyond Compare..."

if [[ ! -d "/Applications/Beyond Compare.app" ]]; then
  echo "❌ Beyond Compare.app not found. Please install it first with 'brew install --cask beyond-compare'"
  exit 1
fi

echo "✅ Beyond Compare found"

if [[ ! -L "/usr/local/bin/bcomp" ]]; then
  echo "🔗 Setting up command line tools..."
  sudo ln -sf "/Applications/Beyond Compare.app/Contents/MacOS/bcomp" /usr/local/bin/bcomp 2>/dev/null || {
    echo "⚠️  Could not create command line symlink. You may need to run:"
    echo "   sudo ln -sf '/Applications/Beyond Compare.app/Contents/MacOS/bcomp' /usr/local/bin/bcomp"
  }
fi

if command -v bcomp &>/dev/null; then
  echo "✅ Command line access verified: $(which bcomp)"
else
  echo "⚠️  Command line access not available. You can set it up manually from Beyond Compare > Install Command Line Tools"
fi
