#!/usr/bin/env bash
set -e

echo "🍴 Setting up Fork Git client..."

# Check if Fork is installed
if [[ ! -d "/Applications/Fork.app" ]]; then
  echo "❌ Fork.app not found. Please install it first with 'brew install --cask fork'"
  exit 1
fi

echo "✅ Fork Git client found"

# Check if git is configured
if ! git config --global user.name >/dev/null 2>&1 || ! git config --global user.email >/dev/null 2>&1; then
  echo "⚠️  Git user configuration not found. Consider setting:"
  echo "   git config --global user.name 'Your Name'"
  echo "   git config --global user.email 'your.email@example.com'"
else
  GIT_USER=$(git config --global user.name)
  GIT_EMAIL=$(git config --global user.email)
  echo "✅ Git configured for: $GIT_USER <$GIT_EMAIL>"
fi

echo "📝 Fork Git client features:"
echo "   • Visual Git interface with intuitive workflow"
echo "   • Advanced diff viewer and merge conflict resolution"
echo "   • Interactive rebase and commit management"
echo "   • Branch visualization and repository navigation"
echo "   • Stash management and submodule support"

echo "💡 Usage tips:"
echo "   • Open repositories: Drag folders to Fork or use File > Open"
echo "   • Quick access: Right-click in Finder > Services > Open in Fork"
echo "   • Integration: Set Fork as default Git GUI in preferences"
echo "   • Themes: Configure dark/light theme in Fork > Preferences"

echo "🔧 Recommended Git configuration for Fork:"
echo "   • Set Fork as default Git GUI: git config --global gui.program fork"
echo "   • Enable SSH agent: Fork > Preferences > Git > Use system SSH agent"

echo "✅ Fork setup complete!"
echo "💡 Launch Fork from Applications to start managing Git repositories visually"