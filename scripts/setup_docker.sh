#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Setting up Docker..."
activate_brew || true

wait_for_daemon() {
  local label="$1" tries=12 i
  for ((i = 1; i <= tries; i++)); do
    docker info >/dev/null 2>&1 && return 0
    echo "   Still waiting for $label... ($((i * 5))s)"
    sleep 5
  done
  return 1
}

# --- Docker Desktop (admin machines) ---------------------------------------

setup_docker_desktop() {
  local app="$1"
  ok "Docker Desktop found at $app"

  if ! docker info >/dev/null 2>&1; then
    step "Starting Docker Desktop..."
    open -a "$app"
    if ! wait_for_daemon "Docker Desktop"; then
      warn "Docker is taking longer than expected to start. Check Docker Desktop manually."
      return 0
    fi
  fi
  ok "Docker daemon is running"
}

# --- colima (no-admin machines) --------------------------------------------

# Docker Desktop installs a privileged helper on first launch and asks for an
# admin password. colima runs the same Docker API inside a user-owned Lima VM,
# so the `docker` CLI behaves identically with no escalation anywhere.
setup_colima() {
  if ! command -v colima >/dev/null 2>&1; then
    warn "colima not installed — it comes from the Brewfile's no-admin branch."
    warn "Run: brew install colima docker docker-compose"
    return 0
  fi

  ok "colima found: $(colima version 2>/dev/null | head -n1)"

  if colima status >/dev/null 2>&1; then
    ok "colima VM is already running"
  else
    step "Starting the colima VM (first start downloads an image and takes a few minutes)..."
    if ! colima start; then
      warn "colima failed to start. Inspect with: colima status && colima logs"
      return 0
    fi
  fi

  if ! docker info >/dev/null 2>&1; then
    warn "colima is up but the docker CLI cannot reach it."
    warn "Try: docker context use colima"
    return 0
  fi
  ok "Docker daemon is running via colima"
}

if DOCKER_APP="$(find_app "Docker.app")"; then
  setup_docker_desktop "$DOCKER_APP"
elif no_admin; then
  echo "  (no admin: Docker Desktop needs a privileged helper — using colima instead)"
  setup_colima
else
  warn "Docker.app not found. Install it with: brew install --cask docker-desktop"
  exit 0
fi

# Homebrew installs docker-compose as a standalone binary, but `docker compose`
# (the subcommand form everything uses now) only finds it via the CLI plugin
# directory. Without this link the daemon works yet `docker compose` reports
# "not available", which looks like a broken install.
link_compose_plugin() {
  command -v docker >/dev/null 2>&1 || return 0
  docker compose version >/dev/null 2>&1 && return 0

  local prefix plugin_src plugin_dir
  prefix="$(brew_prefix)" || return 0
  plugin_src="$prefix/opt/docker-compose/bin/docker-compose"
  [[ -x "$plugin_src" ]] || return 0

  plugin_dir="$HOME/.docker/cli-plugins"
  mkdir -p "$plugin_dir"
  ln -sf "$plugin_src" "$plugin_dir/docker-compose"
  if docker compose version >/dev/null 2>&1; then
    ok "linked docker compose plugin into $plugin_dir"
  else
    warn "linked $plugin_dir/docker-compose but 'docker compose' still not resolving"
  fi
}

link_compose_plugin

if command -v docker >/dev/null 2>&1; then
  echo "📋 Docker summary:"
  echo "   Docker:  $(docker --version 2>/dev/null || echo 'not available')"
  echo "   Compose: $(docker compose version 2>/dev/null || echo 'not available')"
fi
