# Hammerspoon Window Layout Manager

A macOS window layout manager built with [Hammerspoon](https://www.hammerspoon.org/). Save your current window arrangement (position, size, screen, z-order) and restore it later with a single keystroke. Integrates with [Raycast](https://www.raycast.com/).

> 🇹🇼 中文版說明：[README.zh-TW.md](README.zh-TW.md)

## Features

- 💾 **Save current layout** — opens an interactive Webview window list to let you select which windows to save (capturing position, size, screen, and z-order)
- 📐 **Load layout** — opens an interactive Webview selector to let you search, select, or delete layouts with mouse or keyboard shortcuts (`↑`/`↓`/`Enter`/`Backspace`)
- 🎹 **Keyboard shortcuts** — `Cmd+Alt+S` to save layout, `Cmd+Alt+L` to load layout, `Cmd+Alt+D` to delete layout (via Hammerspoon chooser fallback)
- 🚀 **Raycast integration** — trigger layouts via the `hammerspoon://` URL scheme

## Installation

### 1. Install Hammerspoon

```bash
brew install --cask hammerspoon
```

Or download from [hammerspoon.org](https://www.hammerspoon.org/).

### 2. Clone and deploy

```bash
# Clone anywhere
git clone https://github.com/<your-username>/hammerspoon-layout-manager.git
cd hammerspoon-layout-manager

# Deploy to ~/.hammerspoon/
cp init.lua ~/.hammerspoon/
cp -r modules ~/.hammerspoon/
mkdir -p ~/.hammerspoon/layouts
```

Alternatively, make `~/.hammerspoon/` itself the repo:

```bash
# Back up your existing config first if you have one
mv ~/.hammerspoon ~/.hammerspoon.bak 2>/dev/null

git clone https://github.com/<your-username>/hammerspoon-layout-manager.git ~/.hammerspoon
```

### 3. Launch and authorize

1. Open Hammerspoon: `open -a Hammerspoon`
2. Grant **Accessibility permission** when prompted (or manually: System Settings → Privacy & Security → Accessibility → enable Hammerspoon)
3. Click the 🔨 icon in the menu bar → **Reload Config**
4. You should see the alert "Layout Manager 已載入 ✓"

### 4. Set up Raycast Script Commands (optional)

1. Make the scripts executable:
   ```bash
   chmod +x raycast/*.sh
   ```
2. In Raycast: `Settings → Extensions → Script Commands → Add Script Directory`
3. Select the `raycast/` folder of this repo
4. Search for `Save Window Layout` / `Load Window Layout` in Raycast

## Usage

### Keyboard shortcuts

| Shortcut      | Action                              |
| ------------- | ----------------------------------- |
| `Cmd+Alt+S`   | Save current layout (prompts name)  |
| `Cmd+Alt+L`   | Load layout (shows picker)          |
| `Cmd+Alt+D`   | Delete layout (shows picker)        |

### URL scheme

For Raycast, Shortcuts.app, or any other launcher:

```bash
# Opens the save dialog with the name pre-filled as "work"
open "hammerspoon://savelayout?name=work"

# Opens the load dialog/picker
open "hammerspoon://loadlayout"

# Deletes the layout named "work" directly
open "hammerspoon://deletelayout?name=work"
```

### Example workflow

1. Arrange your windows however you like for "work" (editor, browser, Slack, etc.)
2. Press `Cmd+Alt+S`, type `work`, hit save
3. Rearrange windows for "coding"
4. Press `Cmd+Alt+S`, type `coding`, hit save
5. Anytime: press `Cmd+Alt+L` and pick a layout to restore

### Handling missing apps

When loading a layout, if some apps aren't running, you'll get a dialog with three choices:

- **Launch and apply** — launches the missing apps, waits a moment, then applies the layout
- **Skip missing** — applies the layout to whatever's currently running
- **Cancel** — abort

## Project structure

```
hammerspoon-layout-manager/
├── README.md                   English (this file)
├── README.zh-TW.md             繁體中文
├── LICENSE
├── .gitignore
├── init.lua                    Entry point: loads modules, binds shortcuts
├── modules/
│   ├── layout_manager.lua      Core logic: save / load / list / delete
│   ├── url_handler.lua         hammerspoon:// URL scheme handler
│   ├── layout_selector_tmpl.html Save layout UI template (webview)
│   └── layout_loader_tmpl.html   Load layout UI template (webview)
├── layouts/                    Stored layout JSON files (gitignored)
│   └── .gitkeep
└── raycast/                    Raycast Script Commands
    ├── save-layout.sh
    └── load-layout.sh
```

## How it works

Layouts are stored as JSON files in `~/.hammerspoon/layouts/<name>.json`. Each file contains:

- All connected screens (by UUID, so multi-monitor setups can be restored correctly)
- All visible standard windows, with:
  - App name and window title
  - Frame (x, y, width, height)
  - Screen UUID
  - Z-index (front-to-back order)

On load, windows are matched to running apps by name, then to specific windows by title (falling back to the app's main window if no title match). Z-order is approximated by raising windows back-to-front.

## Known limitations

- **Window matching by title** — when an app has multiple windows, matching falls back to the main window if titles don't match exactly
- **Z-order is approximated** — macOS doesn't allow direct z-order control, so it's reconstructed by calling `raise()` in order
- **Fixed 2.5s wait for app launch** — may not be enough for slow-starting apps (Xcode, IntelliJ, etc.)

## Roadmap

- [ ] Poll for app readiness instead of fixed wait time
- [ ] Smarter window matching (frame similarity as fallback)
- [x] Overwrite confirmation when saving over an existing layout
- [ ] Predefined layout templates (declare apps + positions, launch and arrange in one shot)
- [ ] Layout preview in the picker (window count, screen count, thumbnails)
- [ ] Auto-trigger on display configuration change (e.g. external monitor connect)

## License

MIT — see [LICENSE](LICENSE)
