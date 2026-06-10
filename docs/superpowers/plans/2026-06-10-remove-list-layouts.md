# Remove List Layouts Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the redundant public-facing "list layouts" feature (Raycast command, URL handler, and README references) to clean up the interface and codebase, while leaving the internal helper `M.list()` intact.

**Architecture:** We will delete the Raycast script file, remove the `listlayouts` binding in the URL scheme listener, and update the English and Traditional Chinese README files to exclude all references to the list layouts command.

**Tech Stack:** Bash, Lua (Hammerspoon APIs), Markdown

---

### Task 1: Delete Raycast Script

**Files:**
- Delete: `raycast/list-layouts.sh`

- [ ] **Step 1: Delete the file**

  Run:
  ```bash
  rm raycast/list-layouts.sh
  ```

- [ ] **Step 2: Verify the file is deleted**

  Run:
  ```bash
  ls raycast/list-layouts.sh
  ```
  Expected: Command outputs `ls: raycast/list-layouts.sh: No such file or directory` (exit code non-zero).

- [ ] **Step 3: Commit the deletion**

  Run:
  ```bash
  git add raycast/list-layouts.sh
  git commit -m "feat: delete raycast list layouts script"
  ```

---

### Task 2: Remove URL Handler Route

**Files:**
- Modify: `modules/url_handler.lua`

- [ ] **Step 1: Remove listlayouts route**

  In `modules/url_handler.lua`, remove the entire block for the `listlayouts` event:
  ```lua
  -- Remove this exact block:
  -- listlayouts
  hs.urlevent.bind("listlayouts", function()
    local names = layoutManager.list()
    if #names == 0 then
      hs.alert.show("尚無已儲存的 layout")
    else
      hs.alert.show("已儲存：\n" .. table.concat(names, "\n"), 3)
    end
    -- 也印到 console，方便 debug
    print("[LayoutManager] Layouts:", hs.inspect(names))
  end)
  ```

- [ ] **Step 2: Verify URL route removal**

  Run:
  ```bash
  grep -q "listlayouts" modules/url_handler.lua
  ```
  Expected: Command exits with status code 1 (which means "listlayouts" was not found in the file).

- [ ] **Step 3: Commit the change**

  Run:
  ```bash
  git add modules/url_handler.lua
  git commit -m "feat: remove listlayouts route from url handler"
  ```

---

### Task 3: Update Documentation

**Files:**
- Modify: `README.md`
- Modify: `README.zh-TW.md`

- [ ] **Step 1: Update README.md**

  In `README.md`, make the following modifications:
  1. Modify line 61:
     - Old: `4. Search for \`Save Window Layout\` / \`Load Window Layout\` / \`List Window Layouts\` in Raycast`
     - New: `4. Search for \`Save Window Layout\` / \`Load Window Layout\` in Raycast`
  2. Remove line 80 entirely:
     - Line to remove: `open "hammerspoon://listlayouts"`
  3. Remove line 117 (or list-layouts.sh under the directory structure) entirely:
     - Line to remove: `    └── list-layouts.sh`

- [ ] **Step 2: Update README.zh-TW.md**

  In `README.zh-TW.md`, make the following modifications:
  1. Modify line 61:
     - Old: `4. 在 Raycast 搜尋 \`Save Window Layout\` / \`Load Window Layout\` / \`List Window Layouts\``
     - New: `4. 在 Raycast 搜尋 \`Save Window Layout\` / \`Load Window Layout\``
  2. Remove line 78 entirely:
     - Line to remove: `open "hammerspoon://listlayouts"`
  3. Remove line 106 (or list-layouts.sh under the directory structure) entirely:
     - Line to remove: `    └── list-layouts.sh`

- [ ] **Step 3: Verify documentation changes**

  Run:
  ```bash
  git diff README.md README.zh-TW.md
  ```
  Expected: Diff shows removal of the line `open "hammerspoon://listlayouts"`, removal of `list-layouts.sh` from the tree representation, and the updated Raycast command search list.

- [ ] **Step 4: Commit the documentation updates**

  Run:
  ```bash
  git add README.md README.zh-TW.md
  git commit -m "docs: update readmes to remove list layouts references"
  ```
