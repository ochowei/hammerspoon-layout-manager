# Design Spec: Remove List Layouts Feature

This spec details the removal of the redundant "list layouts" feature, including its Raycast script, URL scheme handler, and documentation.

## 1. Background & Goals

Currently, the layout manager has two ways to view stored layouts:
1. Pressing `Cmd+Alt+L` (Load Layout), which opens a beautiful interactive webview picker showcasing all layouts with options to load or delete them.
2. Running the "List Window Layouts" command in Raycast or calling `hammerspoon://listlayouts`, which merely displays a plain alert listing the layout names.

The latter alert-based layout list feature is redundant and cluttering the codebase. The goal of this task is to completely remove the public-facing "list layouts" feature to simplify the user interface and codebase while preserving the internal `M.list()` helper which is still required for the picker UI and the delete chooser interface.

## 2. Proposed Changes

### A. Delete Redundant Script File
- Remove `raycast/list-layouts.sh`.

### B. Remove URL Handler Route
- In [modules/url_handler.lua](file:///Users/william/gitRepo/hammerspoon-layout-manager/modules/url_handler.lua), remove the registration for the `listlayouts` route.

### C. Update Documentation
- Remove references to `List Window Layouts` and `hammerspoon://listlayouts` in:
  - [README.md](file:///Users/william/gitRepo/hammerspoon-layout-manager/README.md)
  - [README.zh-TW.md](file:///Users/william/gitRepo/hammerspoon-layout-manager/README.zh-TW.md)

## 3. Detailed File Changes

### 1. `raycast/list-layouts.sh`
- Delete this file entirely.

### 2. `modules/url_handler.lua`
- Remove the `listlayouts` URL scheme event binding:
```diff
--- a/modules/url_handler.lua
+++ b/modules/url_handler.lua
-  -- listlayouts
-  hs.urlevent.bind("listlayouts", function()
-    local names = layoutManager.list()
-    if #names == 0 then
-      hs.alert.show("尚無已儲存的 layout")
-    else
-      hs.alert.show("已儲存：\n" .. table.concat(names, "\n"), 3)
-    end
-    -- 也印到 console，方便 debug
-    print("[LayoutManager] Layouts:", hs.inspect(names))
-  end)
```

### 3. `README.md`
- Update the Raycast setup and URL scheme sections to exclude references to `List Window Layouts` and `hammerspoon://listlayouts`.
- Update the file list structure to exclude `list-layouts.sh`.

### 4. `README.zh-TW.md`
- Update the Raycast setup and URL scheme sections to exclude references to `List Window Layouts` and `hammerspoon://listlayouts`.
- Update the file list structure to exclude `list-layouts.sh`.

## 4. Verification Plan

1. **Functional Check**:
   - Verify that other layout-related hotkeys (`Cmd+Alt+S`, `Cmd+Alt+L`, `Cmd+Alt+D`) still function correctly.
   - Verify that the webview picker lists the layout items correctly.
2. **Raycast / URL Handler Check**:
   - Verify that calling `open "hammerspoon://listlayouts"` no longer pops up the Hammerspoon alert or causes any errors in Hammerspoon console.
   - Verify that the Raycast command directory no longer contains `list-layouts.sh`.
