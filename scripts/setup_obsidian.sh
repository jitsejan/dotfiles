#!/usr/bin/env bash
set -euo pipefail

VAULT_NAME="ObsidiJan"
VAULT_PATH="$HOME/Documents/Obsidian"
CONFIG_DIR="$HOME/Library/Application Support/obsidian"
VAULT_REGISTRY="$CONFIG_DIR/obsidian.json"
VAULT_CONFIG_DIR="$VAULT_PATH/.obsidian"
DOTFILES_OBSIDIAN_CONFIG="$PWD/.config/obsidian"

echo "🔮 Setting up Obsidian configuration..."

# Create directories
mkdir -p "$CONFIG_DIR"
mkdir -p "$VAULT_PATH"
mkdir -p "$VAULT_CONFIG_DIR"

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

# Copy configuration files to vault
if [[ -d "$DOTFILES_OBSIDIAN_CONFIG" ]]; then
  echo "📁 Copying Obsidian configurations..."
  
  # Copy main configuration files
  [[ -f "$DOTFILES_OBSIDIAN_CONFIG/app.json" ]] && cp "$DOTFILES_OBSIDIAN_CONFIG/app.json" "$VAULT_CONFIG_DIR/"
  [[ -f "$DOTFILES_OBSIDIAN_CONFIG/appearance.json" ]] && cp "$DOTFILES_OBSIDIAN_CONFIG/appearance.json" "$VAULT_CONFIG_DIR/"
  [[ -f "$DOTFILES_OBSIDIAN_CONFIG/community-plugins.json" ]] && cp "$DOTFILES_OBSIDIAN_CONFIG/community-plugins.json" "$VAULT_CONFIG_DIR/"
  
  echo "✅ Configuration files copied"
  echo "📝 Configured plugins: Bases, Notebook Navigator"
  echo "🎨 Configured theme: Cupertino 2"
else
  echo "⚠️  No Obsidian configuration found in dotfiles"
fi

echo "✅ Obsidian vault '$VAULT_NAME' configured at: $VAULT_PATH"
echo "💡 Open Obsidian and enable community plugins, then install the configured plugins"

