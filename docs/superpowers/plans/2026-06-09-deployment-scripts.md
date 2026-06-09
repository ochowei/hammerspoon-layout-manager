# Hammerspoon & Raycast Deployment Scripts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create automated shell scripts to deploy Hammerspoon config files and Raycast scripts using customizable paths from a local `.env` configuration file.

**Architecture:** Use two separate Bash scripts (`deploy-hammerspoon.sh` and `deploy-raycast.sh`) inside a `scripts/` folder that source a `.env` settings file. We use a sandboxed test script (`test-deploy.sh`) to perform unit testing of our copying, backup, and permission setting logic before deployment.

**Tech Stack:** Bash, macOS CLI tools (`osascript`, `chmod`, `cp`).

---

### Task 1: Initialize Git Ignore and Environment Example

**Files:**
- Create: `.env.example`
- Modify: `.gitignore`

- [ ] **Step 1: Append `.env` to `.gitignore`**
  
  Add `.env` to the end of [/.gitignore](file:///Users/william/gitRepo/hammerspoon-layout-manager/.gitignore).

  ```diff
  # Hammerspoon 自身產生的檔案（萬一你把 ~/.hammerspoon 整個變成 git repo）
  .hammerspoon.log
  console.log
  
+ # Environment variables file
+ .env
  ```

- [ ] **Step 2: Create `.env.example`**
  
  Write the following content to [/.env.example](file:///Users/william/gitRepo/hammerspoon-layout-manager/.env.example):

  ```ini
  # Hammerspoon configuration destination (default: ~/.hammerspoon)
  HAMMERSPOON_DIR=~/.hammerspoon

  # Raycast scripts destination (default: ~/.raycast-script)
  RAYCAST_DIR=~/.raycast-script
  ```

- [ ] **Step 3: Verify git status**
  
  Run: `git diff .gitignore`
  Expected: Shows the addition of `.env`.

- [ ] **Step 4: Commit**
  
  Run:
  ```bash
  git add .gitignore .env.example
  git commit -m "chore: add .env config template and update gitignore"
  ```

---

### Task 2: Create Sandboxed Verification Test Script

**Files:**
- Create: `scripts/test-deploy.sh`

- [ ] **Step 1: Write `scripts/test-deploy.sh`**
  
  Create directory `scripts/` if it does not exist, and write the following code to [/scripts/test-deploy.sh](file:///Users/william/gitRepo/hammerspoon-layout-manager/scripts/test-deploy.sh):

  ```bash
  #!/bin/bash
  # Sandboxed test for deployment scripts
  set -e

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

  TEST_SANDBOX="$PROJECT_ROOT/test-sandbox"
  TEST_HS_DIR="$TEST_SANDBOX/hammerspoon"
  TEST_RAYCAST_DIR="$TEST_SANDBOX/raycast"

  # Clean sandbox
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

  echo "Verifying Raycast deployment..."
  if [ ! -f "$TEST_RAYCAST_DIR/save-layout.sh" ]; then
    echo "FAIL: save-layout.sh missing in Raycast folder"
    exit 1
  fi
  if [ ! -x "$TEST_RAYCAST_DIR/save-layout.sh" ]; then
    echo "FAIL: save-layout.sh is not executable"
    exit 1
  fi

  # Clean up sandbox
  rm -rf "$TEST_SANDBOX"

  echo "ALL TESTS PASSED SUCCESSFULLY!"
  ```

- [ ] **Step 2: Run test to verify it fails**
  
  Run: `chmod +x scripts/test-deploy.sh && bash scripts/test-deploy.sh`
  Expected: FAIL with message like `scripts/deploy-hammerspoon.sh: No such file or directory`.

- [ ] **Step 3: Commit**
  
  Run:
  ```bash
  git add scripts/test-deploy.sh
  git commit -m "test: add sandboxed deployment test script"
  ```

---

### Task 3: Implement Hammerspoon Deployment Script

**Files:**
- Create: `scripts/deploy-hammerspoon.sh`

- [ ] **Step 1: Write `scripts/deploy-hammerspoon.sh`**
  
  Write the following code to [/scripts/deploy-hammerspoon.sh](file:///Users/william/gitRepo/hammerspoon-layout-manager/scripts/deploy-hammerspoon.sh):

  ```bash
  #!/bin/bash
  set -e

  # Load settings from .env if present
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

  if [ -f "$PROJECT_ROOT/.env" ]; then
    # Load env variables, ignoring comments
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
  fi

  # Fallback to default if not set
  HAMMERSPOON_DIR="${HAMMERSPOON_DIR:-~/.hammerspoon}"

  # Resolve ~ to absolute path
  eval HAMMERSPOON_DIR="$HAMMERSPOON_DIR"

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
  ```

- [ ] **Step 2: Make executable**
  
  Run: `chmod +x scripts/deploy-hammerspoon.sh`

- [ ] **Step 3: Run test to verify it still fails**
  
  Run: `bash scripts/test-deploy.sh`
  Expected: FAIL with message like `scripts/deploy-raycast.sh: No such file or directory`.

- [ ] **Step 4: Commit**
  
  Run:
  ```bash
  git add scripts/deploy-hammerspoon.sh
  git commit -m "feat: implement hammerspoon deployment script"
  ```

---

### Task 4: Implement Raycast Deployment Script

**Files:**
- Create: `scripts/deploy-raycast.sh`

- [ ] **Step 1: Write `scripts/deploy-raycast.sh`**
  
  Write the following code to [/scripts/deploy-raycast.sh](file:///Users/william/gitRepo/hammerspoon-layout-manager/scripts/deploy-raycast.sh):

  ```bash
  #!/bin/bash
  set -e

  # Load settings from .env if present
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

  if [ -f "$PROJECT_ROOT/.env" ]; then
    # Load env variables, ignoring comments
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
  fi

  # Fallback to default if not set
  RAYCAST_DIR="${RAYCAST_DIR:-~/.raycast-script}"

  # Resolve ~ to absolute path
  eval RAYCAST_DIR="$RAYCAST_DIR"

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
  ```

- [ ] **Step 2: Make executable**
  
  Run: `chmod +x scripts/deploy-raycast.sh`

- [ ] **Step 3: Run test to verify it passes**
  
  Run: `bash scripts/test-deploy.sh`
  Expected: Success output ending with `ALL TESTS PASSED SUCCESSFULLY!`.

- [ ] **Step 4: Commit**
  
  Run:
  ```bash
  git add scripts/deploy-raycast.sh
  git commit -m "feat: implement raycast deployment script"
  ```
