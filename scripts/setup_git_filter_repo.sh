#!/usr/bin/env bash
set -e

echo "🔧 Setting up git-filter-repo..."

# Check if git-filter-repo is installed
if ! command -v git-filter-repo &>/dev/null; then
  echo "❌ git-filter-repo not found. Please install it first with 'brew install git-filter-repo'"
  exit 1
fi

# Get version
GIT_FILTER_REPO_VERSION=$(git filter-repo --version 2>/dev/null || echo "version check failed")
echo "✅ git-filter-repo found: $GIT_FILTER_REPO_VERSION"

echo ""
echo "⚠️  IMPORTANT SAFETY WARNINGS:"
echo "   • ALWAYS work on repository clones, never originals"
echo "   • Backup repositories before performing operations"
echo "   • Coordinate with team before rewriting shared history"
echo "   • Understand implications of force-pushing rewritten history"
echo "   • Test operations on small repositories first"

echo ""
echo "📝 git-filter-repo capabilities:"
echo "   • Fast repository filtering (10-100x faster than git-filter-branch)"
echo "   • Remove sensitive data from Git history"
echo "   • Extract subdirectories into separate repositories"
echo "   • Remove large files to reduce repository size"
echo "   • Clean up commit authorship and messages"
echo "   • Split monorepos or combine repositories"

echo ""
echo "💡 Common usage patterns:"
echo "   • Remove file: git filter-repo --path filename --invert-paths"
echo "   • Extract directory: git filter-repo --path subdirectory/ --path-rename subdirectory/:"
echo "   • Remove large files: git filter-repo --strip-blobs-bigger-than 10M"
echo "   • Change author: git filter-repo --mailmap mailmap.txt"
echo "   • Analyze repo: git filter-repo --analyze"

echo ""
echo "🔒 Security best practices:"
echo "   • Use for removing passwords, API keys, tokens from history"
echo "   • Verify sensitive data removal with: git log --all --full-history -- filename"
echo "   • After cleanup, force-push: git push --force-with-lease origin --all"
echo "   • Consider repository re-clone for team members"

echo ""
echo "📖 Documentation and examples:"
echo "   • Official docs: https://github.com/newren/git-filter-repo"
echo "   • Manual: git filter-repo --help"
echo "   • Analysis mode: git filter-repo --analyze (safe, read-only)"

echo ""
echo "✅ git-filter-repo setup complete!"
echo "💡 Remember: Practice on test repositories before production use!"