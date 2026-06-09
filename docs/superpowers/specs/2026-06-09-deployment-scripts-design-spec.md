# Design Spec: Hammerspoon & Raycast Deployment Scripts

This spec details the design and implementation of automated deployment scripts to copy the Hammerspoon configuration files and Raycast scripts from the project repository to their respective execution paths on the user's system.

## 1. Background & Goals

Currently, users have to manually copy `init.lua` and `modules/` to `~/.hammerspoon/`, and manually configure or copy Raycast script directories to use the layout manager.
To improve developer and user experience, we want to provide automated scripts to deploy changes to:
1. **Hammerspoon**: `~/.hammerspoon` (or custom folder).
2. **Raycast**: `~/.raycast-script` (or custom folder).

The deployment target paths should be configurable via a local `.env` configuration file, falling back to sensible defaults.

## 2. File Structure

We will introduce the following files and directory structure:

```
hammerspoon-layout-manager/
├── .env.example                     # Reference config template
├── .gitignore                       # Updated to exclude local .env
└── scripts/
    ├── deploy-hammerspoon.sh        # Copy Hammerspoon configuration files
    └── deploy-raycast.sh            # Copy Raycast scripts & ensure execution permissions
```

## 3. Configuration Design

### `.env.example` & `.env`
We will use a `.env` file at the project root to store user-defined target directories. A `.env.example` will be provided as a template:

```ini
# Hammerspoon configuration destination (default: ~/.hammerspoon)
HAMMERSPOON_DIR=~/.hammerspoon

# Raycast scripts destination (default: ~/.raycast-script)
RAYCAST_DIR=~/.raycast-script
```

- If `.env` does not exist, the scripts will fall back to the defaults.
- Paths starting with `~` will be resolved to the user's home directory.

## 4. Scripts Design

### A. Hammerspoon Deployment Script (`scripts/deploy-hammerspoon.sh`)
This script copies Hammerspoon files (`init.lua`, `modules/`) to the designated path.

**Detailed Logic:**
1. **Load Environment**: Read `.env` if it exists. If the variables are not defined, fallback to `HAMMERSPOON_DIR=~/.hammerspoon`.
2. **Path Expansion**: Resolve `~` to absolute `$HOME` paths.
3. **Backup Check**: If `$HAMMERSPOON_DIR/init.lua` exists, rename it to `init.lua.bak` before overwriting.
4. **Create Directories**: Run `mkdir -p "$HAMMERSPOON_DIR/modules"` and `mkdir -p "$HAMMERSPOON_DIR/layouts"`.
5. **Copy Files**:
   - `cp init.lua "$HAMMERSPOON_DIR/init.lua"`
   - `cp -R modules/ "$HAMMERSPOON_DIR/"`
6. **Auto-Reload Hammerspoon**: Run `osascript` to trigger configuration reload in Hammerspoon:
   ```bash
   osascript -e 'tell application "Hammerspoon" to execute lua code "hs.reload()"'
   ```

### B. Raycast Deployment Script (`scripts/deploy-raycast.sh`)
This script copies Raycast script commands (`raycast/*.sh`) to the designated path and grants execution permissions.

**Detailed Logic:**
1. **Load Environment**: Read `.env` if it exists. Fallback to `RAYCAST_DIR=~/.raycast-script`.
2. **Path Expansion**: Resolve `~` to absolute `$HOME` paths.
3. **Create Directory**: Run `mkdir -p "$RAYCAST_DIR"`.
4. **Copy Files**: Copy all files matching `raycast/*.sh` to `$RAYCAST_DIR/`.
5. **Ensure Executable**: Run `chmod +x "$RAYCAST_DIR"/*.sh` to ensure Raycast can run them.

## 5. Verification Plan

We will test the deployment scripts by verifying that:
1. Running the scripts without a `.env` file successfully deploys files to `~/.hammerspoon` and `~/.raycast-script`.
2. Hammerspoon successfully reloads after deployment (showing standard Hammerspoon load alerts).
3. Raycast scripts in `~/.raycast-script` are marked as executable.
4. Creating a `.env` file with custom directories correctly changes the deployment target paths.
5. Directory creation, backups, and script exits handle edge cases elegantly (e.g. spaces in paths, missing directories).
