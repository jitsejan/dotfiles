#!/usr/bin/env bash
set -e

echo "🔍 Setting up Beyond Compare..."

# Check if Beyond Compare is installed
if [[ ! -d "/Applications/Beyond Compare.app" ]]; then
  echo "❌ Beyond Compare.app not found. Please install it first with 'brew install --cask beyond-compare'"
  exit 1
fi

echo "✅ Beyond Compare found"

# Set up command line tools (bcomp)
if [[ ! -L "/usr/local/bin/bcomp" ]]; then
  echo "🔗 Setting up command line tools..."
  sudo ln -sf "/Applications/Beyond Compare.app/Contents/MacOS/bcomp" /usr/local/bin/bcomp 2>/dev/null || {
    echo "⚠️  Could not create command line symlink. You may need to run:"
    echo "   sudo ln -sf '/Applications/Beyond Compare.app/Contents/MacOS/bcomp' /usr/local/bin/bcomp"
  }
else
  echo "✅ Command line tools already configured"
fi

# Verify command line access
if command -v bcomp &>/dev/null; then
  echo "✅ Command line access verified: $(which bcomp)"
else
  echo "⚠️  Command line access not available. You can set it up manually from Beyond Compare > Install Command Line Tools"
fi

echo "📝 Beyond Compare features:"
echo "   • File and folder comparison"
echo "   • 3-way merge capabilities"  
echo "   • Image, text, and binary diff"
echo "   • Integration with version control systems"
echo "   • Scripting and automation support"

echo "💡 Usage tips:"
echo "   • GUI: Launch from Applications or Spotlight"
echo "   • CLI: Use 'bcomp file1 file2' for quick comparisons"
echo "   • Git integration: Set as difftool/mergetool in git config"

echo "✅ Beyond Compare setup complete!"
echo "💡 Consider configuring it as your default diff/merge tool for development"