# 視窗配置管理器 - 儲存時選擇特定視窗設計文件 (Window Selection on Save Design Spec)

本文件說明如何在 Hammerspoon Layout Manager 中實現「儲存 Layout 時可選擇特定視窗」的功能設計。

## 1. 背景與動機 (Context & Motivation)
目前的系統在按下 `Cmd + Alt + S` 儲存配置時，會透過 `hs.dialog.textPrompt` 詢問 Layout 名稱，並將當前所有可見的標準視窗自動全部寫入設定檔中。然而，使用者在工作時常有臨時開啟的視窗（例如臨時瀏覽網頁、通訊軟體等），這些視窗通常不希望被包含在長期保存的 Layout 配置中。

因此，本設計旨在提供一個圖形化介面（利用 `hs.webview`），讓使用者在儲存時可以勾選需要保留的視窗，並直接在介面中輸入檔名儲存，增進使用體驗。

## 2. 功能需求與範疇 (Requirements & Scope)
- **多選視窗列表**：儲存時彈出一個獨立的自訂網頁視窗 (`hs.webview`)，顯示所有目前可見的標準視窗。
- **預設全部勾選**：為節省操作時間，預設勾選清單中的所有視窗，使用者僅需取消勾選不想要的視窗。
- **依應用程式 (App) 分組**：視窗清單依據其所屬 App 進行分組展示。
- **顯示螢幕資訊**：在每個視窗或 App 分組旁邊，顯示該視窗目前所處的螢幕名稱，幫助使用者辨識。
- **直觀的輸入與操作**：
  - 提供文字輸入框輸入 Layout 名稱（帶有預設值或自動聚焦）。
  - 提供「儲存」與「取消」按鈕，並支援 `ESC` 鍵取消。
  - 對重名的 Layout 提供覆蓋警告提示。
- **檔名安全性驗證**：自動過濾或提示不合法的檔名特殊字元。

---

## 3. 系統架構與資料流 (Architecture & Data Flow)

本功能主要由 Hammerspoon (Lua) 端與內嵌網頁 (HTML/JS/CSS) 前端所組成，透過 `hs.webview` 的雙向溝通橋樑進行資料傳遞。

```
+--------------------------+                      +----------------------------+
|    Hammerspoon (Lua)     |                      |   WebView (HTML/JS/CSS)    |
|                          |                      |                            |
| 1. 按下 Cmd+Alt+S        |                      |                            |
| 2. 收集當前可見視窗資料  |                      |                            |
| 3. 開啟 Webview 視窗     |  -- 注入視窗 JSON ->  | 4. 渲染視窗列表與勾選框    |
|                          |                      | 5. 使用者輸入名稱與勾選    |
| 7. 驗證資料、儲存 JSON   |  <- 回傳勾選結果 --- | 6. 點選「儲存」發送 message|
| 8. 關閉並銷毀 Webview    |                      |                            |
+--------------------------+                      +----------------------------+
```

### 3.1 前後端通訊合約 (Communication Contract)
網頁端按下儲存時，將使用以下 JSON 格式將資料送回 Lua 的 `userCallback`：

```json
{
  "action": "save",
  "name": "Work Focus",
  "selected": [
    { "app": "Google Chrome", "title": "GitHub - hammerspoon-layout-manager" },
    { "app": "Visual Studio Code", "title": "layout_manager.lua" }
  ]
}
```

若點擊「取消」或按 `ESC` 關閉：
```json
{
  "action": "cancel"
}
```

---

## 4. 詳細設計 (Detailed Design)

### 4.1 檔案結構異動 (File Changes)
- **新增** `modules/layout_selector_tmpl.html`：儲存視窗選擇器的網頁範本檔案（內含 HTML, CSS, JavaScript）。
- **修改** `modules/layout_manager.lua`：
  - 新增 `M.showSaveDialog()` 方法，用來啟動 `hs.webview` 並載入視窗資訊。
  - 修改 `M.save()` 方法，使其接受經過篩選的視窗列表並寫入檔案，支援非互動式儲存（例如 URL 呼叫時維持原樣直接全存）。
- **修改** `init.lua`：
  - 將原本的 `hs.dialog.textPrompt` 儲存邏輯改為呼叫 `layoutManager.showSaveDialog()`。

### 4.2 Webview 介面設計 (UI Layout Specs)
- **視窗尺寸**：寬 600px，高 500px，不可縮放。
- **視窗外觀**：
  - 使用無邊框外觀 (`hs.webview.windowMasks.borderless`)。
  - 背景採用 macOS 質感的深灰色底色 (`#1e1e24`)。
- **組件排版**：
  1. **輸入框**：具有焦點的文字輸入框，佔滿寬度。
  2. **視窗列表區**：高度固定（如 300px）且支援垂直滾動 (`overflow-y: auto`)。
  3. **App 卡片**：
     - 使用背景色 `#25252d` 與邊框。
     - App 名稱文字粗體且顏色為亮藍色。
     - 視窗項目採用 Flex 排版，Checkbox 與標題垂直對齊。
  4. **底部按鈕區**：固定於底部，右對齊。

### 4.3 檔名安全性與重名防護邏輯
1. **空白檔名防護**：網頁端在點擊儲存時，會檢查名稱長度。若為空則在輸入框下方以紅色字體提示。
2. **非法字元過濾**：Lua 端在寫入檔案前，會利用 Lua Pattern 將檔名中的特殊字元移去：
   ```lua
   local safeName = name:gsub('[%/%\\%?%*%%&%|%^%`%;%<%>%:]', "")
   ```
3. **覆蓋提示**：若檔名已存在（`layouts/<safeName>.json` 檔案存在），網頁前端會跳出提示「此配置已存在，是否要覆蓋儲存？」，使用者點選確定後才繼續傳送給 Lua，否則中止。

---

## 5. 測試與驗證計畫 (Testing Plan)

### 5.1 功能性測試 (Functional Testing)
- **測試點 1：清單收集與分組**
  - 開啟 Chrome（多視窗）、VS Code 與 Slack。
  - 按下 `Cmd + Alt + S` 叫出視窗，驗證 Chrome 視窗是否正確在同一個分組卡片內，且螢幕名稱顯示正確。
- **測試點 2：勾選過濾**
  - 取消勾選某個 VS Code 視窗，輸入 `TestLayout` 並點選儲存。
  - 開啟 `~/.hammerspoon/layouts/TestLayout.json`，檢查 `windows` 陣列中是否確實沒有包含該 VS Code 視窗。
- **測試點 3：重名與取消**
  - 重複儲存同名 Layout，確認是否有覆蓋警示。
  - 開啟視窗後按下「取消」或鍵盤 `ESC`，確認 Webview 視窗順利關閉，且未在磁碟產生新檔案。

### 5.2 異常與邊界測試 (Edge Case Testing)
- **無任何標準視窗時**：若當前桌面沒有任何可見的標準視窗，應在列表區顯示「當前無任何可儲存的視窗」。
- **特殊字元輸入**：輸入名稱如 `work/focus:today`，確認儲存後的檔名被安全過濾為 `workfocustoday.json`。
- **URL Handler 相容性**：透過 Raycast 或瀏覽器呼叫 `hammerspoon://savelayout?name=auto_save`，驗證其是否會繞過 UI 介面，直接以預設「全選」方式進行背景儲存，不影響自動化腳本。
