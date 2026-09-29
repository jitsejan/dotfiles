#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

VAULT_NAME="ObsidiJan"
VAULT_PATH="$HOME/Documents/Obsidian"
CONFIG_DIR="$HOME/Library/Application Support/obsidian"
VAULT_REGISTRY="$CONFIG_DIR/obsidian.json"
VAULT_CONFIG_DIR="$VAULT_PATH/.obsidian"
DOTFILES_OBSIDIAN_CONFIG="$(cd "$SCRIPT_DIR/.." && pwd)/.config/obsidian"

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
  
  # Copy plugin configurations (ready for when plugins are installed)
  if [[ -d "$DOTFILES_OBSIDIAN_CONFIG/plugins" ]]; then
    echo "📦 Copying plugin configurations..."
    mkdir -p "$VAULT_CONFIG_DIR/plugins"
    cp -r "$DOTFILES_OBSIDIAN_CONFIG/plugins/"* "$VAULT_CONFIG_DIR/plugins/" 2>/dev/null || true
  fi
  
  echo "✅ Configuration files copied"
  echo "📝 Configured plugins: Bases, Notebook Navigator"
  echo "🎨 Configured theme: Cupertino 2"
  echo "⚙️  Plugin settings pre-configured"
else
  echo "⚠️  No Obsidian configuration found in dotfiles"
fi

echo "✅ Obsidian vault '$VAULT_NAME' configured at: $VAULT_PATH"
echo ""
echo "📋 Next steps to complete setup:"
echo "   1. Open Obsidian"
echo "   2. Go to Settings (⚙️) → Community plugins"
echo "   3. Click 'Turn on community plugins'"
echo "   4. Click 'Browse' and install:"
echo "      • 'Bases' plugin"
echo "      • 'Notebook Navigator' plugin"
echo "   5. Enable both plugins in Community plugins list"
echo "   6. Restart Obsidian to apply Cupertino 2 theme"
echo ""
echo "💡 Plugin settings are pre-configured and will work immediately!"

