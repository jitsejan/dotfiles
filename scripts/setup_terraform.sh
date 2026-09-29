#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Checking Terraform and Terragrunt..."
activate_brew || true

# Terraform is no longer in homebrew-core (HashiCorp's BUSL relicense), so the
# install hint has to be tap-qualified; a bare `brew install terraform` fails.
missing=0
for tool in terraform terragrunt; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool found: $("$tool" --version 2>/dev/null | head -n1)"
  else
    case "$tool" in
      terraform) warn "terraform not found. Install it with: brew install hashicorp/tap/terraform" ;;
      *)         warn "$tool not found. Install it with: brew install $tool" ;;
    esac
    missing=1
  fi
done

[[ "$missing" == "1" ]] && exit 0

mkdir -p "$HOME/.terraform.d"
ok "Terraform and Terragrunt setup complete"
