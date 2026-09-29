#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# On an admin machine the Brewfile's `npm` entries handle these and this script
# is a no-op. Without admin they can't live in the Brewfile: `brew bundle`
# satisfies an `npm` entry by installing the Homebrew node formula even when a
# perfectly good node is already on PATH, and that formula compiles from source
# in a user prefix and drags in LLVM. So install them here against fnm's node.
NPM_GLOBALS=(
  "@anthropic-ai/claude-code"
  "@mermaid-js/mermaid-cli"
  "pptxgenjs"
  "opencode-ai"        # prebuilt opencode; the brew formula needs LLVM to build
)

step "Installing npm global packages..."

if ! no_admin; then
  skip "npm globals come from the Brewfile on an admin machine"
  exit 0
fi

# shellcheck source=scripts/install_node.sh
source "$SCRIPT_DIR/install_node.sh"

if ! command -v npm >/dev/null 2>&1; then
  warn "npm not available — skipping npm globals."
  exit 0
fi

for pkg in "${NPM_GLOBALS[@]}"; do
  if npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
    ok "$pkg already installed"
  elif npm install -g "$pkg" >/dev/null 2>&1; then
    ok "installed $pkg"
  else
    warn "failed to install $pkg"
    manual_step "Install the npm package by hand: npm install -g $pkg"
  fi
done
