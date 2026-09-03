#!/usr/bin/env bash
set -e

echo "🔧 Checking git-filter-repo..."

if ! command -v git-filter-repo &>/dev/null; then
  echo "❌ git-filter-repo not found. Please install it first with 'brew install git-filter-repo'"
  exit 1
fi

echo "✅ git-filter-repo found: $(git filter-repo --version 2>/dev/null)"
