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
RAYCAST_DIR="${RAYCAST_DIR:-~/.raycast-script}"

# Resolve ~ to absolute path safely
RAYCAST_DIR="${RAYCAST_DIR/#\~/$HOME}"

echo "Deploying Raycast scripts to: $RAYCAST_DIR"

# Ensure target directory exists
mkdir -p "$RAYCAST_DIR"

# Copy Raycast scripts
echo "Copying Raycast script commands..."
cp "$PROJECT_ROOT"/raycast/*.sh "$RAYCAST_DIR/"

# Ensure executable permissions
echo "Setting execution permissions..."
chmod +x "$RAYCAST_DIR"/*.sh

echo "Raycast script deployment completed successfully."
