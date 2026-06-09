#!/bin/bash
# Sandboxed test for deployment scripts
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEST_SANDBOX="$PROJECT_ROOT/test-sandbox"
TEST_HS_DIR="$TEST_SANDBOX/hammerspoon"
TEST_RAYCAST_DIR="$TEST_SANDBOX/raycast"

# Clean sandbox on exit
cleanup() {
  echo "Cleaning up sandbox..."
  rm -rf "$TEST_SANDBOX"
}
trap cleanup EXIT

# Clean sandbox initially
rm -rf "$TEST_SANDBOX"
mkdir -p "$TEST_HS_DIR"
mkdir -p "$TEST_RAYCAST_DIR"

echo "Running deployment tests in sandbox: $TEST_SANDBOX"

# Create pre-existing init.lua to test backup
echo "original-init" > "$TEST_HS_DIR/init.lua"

# Run Hammerspoon deploy with custom env
export HAMMERSPOON_DIR="$TEST_HS_DIR"
export RAYCAST_DIR="$TEST_RAYCAST_DIR"

bash "$SCRIPT_DIR/deploy-hammerspoon.sh"
bash "$SCRIPT_DIR/deploy-raycast.sh"

# Assertions
echo "Verifying Hammerspoon deployment..."
if [ ! -f "$TEST_HS_DIR/init.lua" ]; then
  echo "FAIL: init.lua missing"
  exit 1
fi
if [ ! -f "$TEST_HS_DIR/init.lua.bak" ]; then
  echo "FAIL: Backup init.lua.bak missing"
  exit 1
fi
if [ "$(cat "$TEST_HS_DIR/init.lua.bak")" != "original-init" ]; then
  echo "FAIL: Backup init.lua.bak content incorrect"
  exit 1
fi
if [ ! -d "$TEST_HS_DIR/modules" ]; then
  echo "FAIL: modules directory missing"
  exit 1
fi
if [ ! -f "$TEST_HS_DIR/modules/layout_manager.lua" ]; then
  echo "FAIL: modules/layout_manager.lua missing"
  exit 1
fi

echo "Verifying Raycast deployment..."
if [ ! -f "$TEST_RAYCAST_DIR/save-layout.sh" ]; then
  echo "FAIL: save-layout.sh missing in Raycast folder"
  exit 1
fi
if [ ! -x "$TEST_RAYCAST_DIR/save-layout.sh" ]; then
  echo "FAIL: save-layout.sh is not executable"
  exit 1
fi

echo "ALL TESTS PASSED SUCCESSFULLY!"

