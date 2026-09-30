#!/usr/bin/env bash
# Ensure node + npm exist before `brew bundle` processes its npm entries.
#
# SOURCE THIS, don't execute it — it puts node on PATH for the calling script,
# and that only works in the caller's own shell.
#
# Why this exists: homebrew-core's `node` bottle is stamped for /opt/homebrew, so
# in a user-owned prefix Homebrew falls back to building node from source — and
# node's build needs LLVM, which also has no relocatable bottle. That cascade is
# a multi-hour compile for a runtime that upstream ships as a ready-made binary.
# fnm has a `:any_skip_relocation` bottle, installs in seconds, and downloads
# those official prebuilt Node binaries.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

ensure_node() {
  activate_brew || true

  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    ok "node $(node --version) and npm $(npm --version) already available"
    return 0
  fi

  # With admin, the Brewfile's `node` entry pours a bottle normally.
  if ! no_admin; then
    skip "node comes from the Brewfile on an admin machine"
    return 0
  fi

  step "Providing node via fnm (avoids a source build of node + LLVM)..."

  if ! command -v fnm >/dev/null 2>&1; then
    # Installed directly rather than waiting for `brew bundle`, because the
    # Brewfile's npm entries are processed during that same bundle run and need
    # npm to already exist. fnm is also tracked in the Brewfile's no-admin branch
    # so it isn't invisible to the drift check.
    brew install fnm || { warn "could not install fnm — npm packages will be skipped"; return 0; }
  fi

  fnm install --lts || { warn "fnm could not install the Node LTS"; return 0; }
  fnm default lts-latest 2>/dev/null || true

  # Put the selected node on PATH for the remainder of this shell.
  eval "$(fnm env --shell bash)" 2>/dev/null || true
  fnm use lts-latest >/dev/null 2>&1 || true
  eval "$(fnm env --shell bash)" 2>/dev/null || true

  if command -v node >/dev/null 2>&1; then
    ok "node $(node --version) via fnm"
  else
    warn "node still not on PATH after fnm setup — npm packages will be skipped"
  fi
}

ensure_node
