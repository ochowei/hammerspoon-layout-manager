# Hammerspoon Window Layout Manager

一個用 [Hammerspoon](https://www.hammerspoon.org/) 寫的 macOS 視窗 layout 管理工具。支援儲存當前視窗排列（位置、大小、螢幕、z-order）、之後一鍵還原，並可以從 Raycast 觸發。

> 🇬🇧 English version: [README.md](README.md)

## 功能

- 💾 **儲存當前 layout**：把所有可見視窗的位置、大小、所在螢幕、前後順序存成 JSON
- 📐 **載入 layout**：一鍵還原視窗排列；若有 app 沒啟動會跳出對話框問你
- 🎹 **快捷鍵**：`Cmd+Alt+S` 儲存、`Cmd+Alt+L` 載入、`Cmd+Alt+D` 刪除
- 🚀 **Raycast 整合**：透過 `hammerspoon://` URL scheme，從 Raycast 直接呼叫

## 安裝

### 1. 安裝 Hammerspoon

```bash
brew install --cask hammerspoon
```

或從 [hammerspoon.org](https://www.hammerspoon.org/) 下載。

### 2. Clone 這個 repo 並部署

```bash
# Clone 到任意位置
git clone https://github.com/<你的帳號>/hammerspoon-layout-manager.git
cd hammerspoon-layout-manager

# 部署到 ~/.hammerspoon/
cp init.lua ~/.hammerspoon/
cp -r modules ~/.hammerspoon/
mkdir -p ~/.hammerspoon/layouts
```

或者如果你想直接讓 `~/.hammerspoon/` 本身就是這個 repo：

```bash
# 先備份原本的設定（如果有的話）
mv ~/.hammerspoon ~/.hammerspoon.bak 2>/dev/null

git clone https://github.com/<你的帳號>/hammerspoon-layout-manager.git ~/.hammerspoon
```

### 3. 啟動並授權

1. 開啟 Hammerspoon：`open -a Hammerspoon`
2. 首次執行會要求 **Accessibility 權限**：系統設定 → 隱私權與安全性 → 輔助使用 → 勾選 Hammerspoon
3. 點選選單列的 🔨 圖示 → **Reload Config**
4. 看到「Layout Manager 已載入 ✓」就代表 OK

### 4. 設定 Raycast Script Commands（選用）

1. 給 raycast 腳本執行權限：
   ```bash
   chmod +x raycast/*.sh
   ```
2. 在 Raycast 中：`Settings → Extensions → Script Commands → Add Script Directory`
3. 選擇本 repo 的 `raycast/` 資料夾
4. 在 Raycast 搜尋 `Save Window Layout` / `Load Window Layout`

## 使用方式

### 快捷鍵

| 快捷鍵        | 功能                          |
| ------------- | ----------------------------- |
| `Cmd+Alt+S`   | 儲存當前 layout（輸入名稱）   |
| `Cmd+Alt+L`   | 載入 layout（選單選擇）       |
| `Cmd+Alt+D`   | 刪除 layout（選單選擇）       |

### URL Scheme（給 Raycast / Shortcuts / 其他工具）

```bash
open "hammerspoon://savelayout?name=work"
open "hammerspoon://loadlayout?name=work"
open "hammerspoon://deletelayout?name=work"
```

### 範例情境

1. 排好你工作用的視窗（編輯器、瀏覽器、Slack 等）
2. 按 `Cmd+Alt+S`，輸入 `work` → 儲存
3. 排好寫程式用的視窗
4. 按 `Cmd+Alt+S`，輸入 `coding` → 儲存
5. 之後隨時按 `Cmd+Alt+L`，選擇要切換到哪個 layout

## 檔案結構

```
hammerspoon-layout-manager/
├── README.md
├── LICENSE
├── .gitignore
├── init.lua                    入口，載入模組與綁定快捷鍵
├── modules/
│   ├── layout_manager.lua      核心：save / load / list / delete
│   └── url_handler.lua         hammerspoon:// URL 處理
├── layouts/                    儲存的 layout JSON 檔（被 gitignore）
│   └── .gitkeep
└── raycast/                    Raycast Script Commands
    ├── save-layout.sh
    └── load-layout.sh
```

## 已知限制與後續可改進

- **App 視窗匹配靠 title**：同 app 多個視窗時靠 title 比對；title 變了會 fallback 到主視窗
- **z-order 用 `raise()` 模擬**：macOS 不允許直接設定 z-order，靠依序 raise 近似還原
- **app 啟動等待時間固定 2.5 秒**：對慢開的 app 可能不夠

## License

MIT
