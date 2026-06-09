#!/bin/bash
set -e

# Load settings from .env if present
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$PROJECT_ROOT/.env" ]; then
  set -a
  source "$PROJECT_ROOT/.env"
  set +a
fi

# Fallback to default if not set
HAMMERSPOON_DIR="${HAMMERSPOON_DIR:-~/.hammerspoon}"

# Resolve ~ to absolute path safely
HAMMERSPOON_DIR="${HAMMERSPOON_DIR/#\~/$HOME}"

echo "Deploying Hammerspoon configuration to: $HAMMERSPOON_DIR"

# Ensure target directories exist
mkdir -p "$HAMMERSPOON_DIR/modules"
mkdir -p "$HAMMERSPOON_DIR/layouts"

# Backup existing init.lua if it exists
if [ -f "$HAMMERSPOON_DIR/init.lua" ]; then
  echo "Backing up existing $HAMMERSPOON_DIR/init.lua to $HAMMERSPOON_DIR/init.lua.bak"
  cp "$HAMMERSPOON_DIR/init.lua" "$HAMMERSPOON_DIR/init.lua.bak"
fi

# Copy files
echo "Copying configuration files..."
cp "$PROJECT_ROOT/init.lua" "$HAMMERSPOON_DIR/init.lua"
cp -R "$PROJECT_ROOT/modules/." "$HAMMERSPOON_DIR/modules/"

echo "Hammerspoon deployment completed successfully."

# Auto-reload Hammerspoon config
echo "Reloading Hammerspoon configuration..."
if osascript -e 'tell application "Hammerspoon" to execute lua code "hs.reload()"' >/dev/null 2>&1; then
  echo "Hammerspoon configuration reloaded successfully!"
else
  echo "Could not reload Hammerspoon. Make sure Hammerspoon is running."
fi
