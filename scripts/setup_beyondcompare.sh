#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Checking Beyond Compare..."

if ! BC_APP="$(find_app "Beyond Compare.app")"; then
  warn "Beyond Compare.app not found. Install it with: brew install --cask beyond-compare"
  exit 0
fi
ok "Beyond Compare found at $BC_APP"

# /usr/local/bin is root-owned, so without admin the CLI shim goes into
# ~/.local/bin instead — already on PATH via config.fish's fish_add_path.
BIN_DIR="$(writable_bin_dir)"
TARGET="$BIN_DIR/bcomp"
SOURCE="$BC_APP/Contents/MacOS/bcomp"

if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$SOURCE" ]]; then
  ok "bcomp already linked at $TARGET"
elif ln -sf "$SOURCE" "$TARGET" 2>/dev/null; then
  ok "linked bcomp → $TARGET"
else
  warn "Could not link bcomp into $BIN_DIR."
  manual_step "Install the Beyond Compare CLI from its menu: Beyond Compare > Install Command Line Tools"
fi

command -v bcomp >/dev/null 2>&1 && ok "bcomp is on PATH: $(command -v bcomp)"
