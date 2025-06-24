#!/usr/bin/env bash
set -euo pipefail

VAULT_NAME="ObsidiJan"
VAULT_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/ObsidiJan"
CONFIG_DIR="$HOME/Library/Application Support/obsidian"
VAULT_REGISTRY="$CONFIG_DIR/obsidian.json"

mkdir -p "$CONFIG_DIR"

# Create vault entry JSON
cat > "$VAULT_REGISTRY" <<EOF
{
  "vaults": {
    "$VAULT_NAME": {
      "path": "$VAULT_PATH",
      "ts": $(date +%s000)
    }
  }
}
EOF

echo "✅ Obsidian vault '$VAULT_NAME' configured at: $VAULT_PATH"

