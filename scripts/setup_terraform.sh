#!/usr/bin/env bash
set -e

echo "🏗️  Setting up Terraform and Terragrunt..."

if ! command -v terraform &>/dev/null; then
  echo "❌ Terraform not found. Please install it first with 'brew install terraform'"
  exit 1
fi

if ! command -v terragrunt &>/dev/null; then
  echo "❌ Terragrunt not found. Please install it first with 'brew install terragrunt'"
  exit 1
fi

echo "✅ Terraform found: $(terraform version | head -n1 | cut -d' ' -f2)"
echo "✅ Terragrunt found: $(terragrunt --version | head -n1 | cut -d' ' -f3)"

mkdir -p "$HOME/.terraform.d"

echo "✅ Terraform and Terragrunt setup complete!"
