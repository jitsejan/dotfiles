#!/usr/bin/env bash
set -e

echo "🗂️ Setting up ForkLift file manager..."

# Check if ForkLift is installed
if [[ ! -d "/Applications/ForkLift.app" ]]; then
  echo "❌ ForkLift.app not found. Please install it first with 'brew install --cask forklift'"
  exit 1
fi

echo "✅ ForkLift.app found"

# Set ForkLift as default for directories (requires user approval)
echo "💡 To set ForkLift as your default file manager:"
echo "   1. Right-click on any folder"
echo "   2. Select 'Get Info'"  
echo "   3. Under 'Open with:', select ForkLift"
echo "   4. Click 'Change All...'"

# Create basic preferences (if user wants to customize)
echo "📝 ForkLift preferences can be customized from:"
echo "   ForkLift > Preferences"

echo "✅ ForkLift setup complete!"
echo "💡 Launch ForkLift from Applications or Spotlight"
echo "💡 Consider setting up your favorite locations in Favorites"