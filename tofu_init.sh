#!/bin/bash

# Define paths
CACHE_DIR="$HOME/.terraform.d/plugin-cache"
CONFIG_FILE="$HOME/.tofurc"

echo "🔍 Searching for OpenTofu provider directories..."

# Get the current project’s provider directory
CURRENT_PROJECT_PROVIDER="$(pwd)/.terraform/providers"

# Find and delete old providers, but keep the ones in the cache
find ~ -type d -path "*/.terraform/providers" ! -path "$CURRENT_PROJECT_PROVIDER" ! -path "$CACHE_DIR" -exec rm -rf {} +

echo "✅ Removed unused OpenTofu providers."

# Ensure the cache directory exists
if [ ! -d "$CACHE_DIR" ]; then
  echo "📂 Creating OpenTofu provider cache directory..."
  mkdir -p "$CACHE_DIR"
fi

# Move any remaining providers into the cache
if [ -d "$CURRENT_PROJECT_PROVIDER" ]; then
  echo "♻️ Moving project providers to cache..."
  mv "$CURRENT_PROJECT_PROVIDER"/* "$CACHE_DIR"/
fi

# Set up OpenTofu/Terraform to use the cache
echo "⚙️ Configuring OpenTofu provider cache..."
cat <<EOF > "$CONFIG_FILE"
plugin_cache_dir = "$CACHE_DIR"
EOF

echo "✅ OpenTofu provider cache set up successfully!"
echo "📌 Cached providers can be found in: $CACHE_DIR"
echo "📜 OpenTofu is now configured to use cached providers in: $CONFIG_FILE"

echo "🔄 Run 'tofu init' again in your projects to apply these changes."