# 儲存時選擇特定視窗 (Window Selection on Save) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓使用者在按下 `Cmd + Alt + S` 儲存視窗配置時，彈出一個自訂的 HTML/CSS 介面，以 App 為分組呈現所有可見視窗，供勾選篩選，並在同一個介面完成 Layout 名稱輸入與儲存。

**Architecture:** 在 Lua 中讀取靜態 HTML 範本，透過 JSON 取代注入當前視窗與已儲存 Layout 名單。使用 `hs.webview` 渲染彈出視窗並置頂居中。前端透過 `window.webkit.messageHandlers.hammerspoon.postMessage` 與 Lua 通訊，傳回篩選後的視窗清單及名稱進行安全過濾與寫入。

**Tech Stack:** Hammerspoon API (hs.webview, hs.window, hs.json, hs.screen), HTML5, CSS3 (Vanilla CSS), JavaScript (Vanilla JS).

---

## 預計異動與建立的檔案 (Files Map)
- **新增測試檔案**：`scratch/test_helpers.lua` (測試純 Lua 的輔助邏輯)
- **新增網頁範本**：`modules/layout_selector_tmpl.html` (前端選單 HTML/JS/CSS)
- **修改核心模組**：`modules/layout_manager.lua` (載入範本、開啟 Webview、處理 Callback、過濾儲存)
- **修改入口檔案**：`init.lua` (修改 S 鍵的觸發行為)

---

### Task 1: 實作檔名安全過濾邏輯與單元測試 (Pure Lua Helper Logic)

**Files:**
- Create: `scratch/test_helpers.lua`
- Modify: `modules/layout_manager.lua:40-42` (新增 sanitizeName 函數位置)

- [ ] **Step 1: 撰寫測試腳本**
  建立 `scratch/test_helpers.lua` 檔案，用來驗證 Lua 的檔名安全過濾邏輯。

  ```lua
  -- scratch/test_helpers.lua
  local M = {}
  
  -- 待測試的邏輯實作（暫時直接寫在測試中以利執行）
  function M.sanitizeName(name)
    if not name then return "" end
    -- 過濾 / \ ? * % & | ^ ` ; < > :
    return name:gsub('[%/%\\%?%*%%&%|%^%`%;%<%>%:]', "")
  end
  
  -- 測試用例
  local test_cases = {
    { input = "work-focus", expected = "work-focus" },
    { input = "work/focus", expected = "workfocus" },
    { input = "work\\focus?*today", expected = "workfocustoday" },
    { input = "my:layout;name", expected = "mylayoutname" },
    { input = nil, expected = "" }
  }
  
  local failed = false
  for _, tc in ipairs(test_cases) do
    local result = M.sanitizeName(tc.input)
    if result ~= tc.expected then
      print(string.format("FAIL: input: %s, expected: %s, got: %s", tostring(tc.input), tc.expected, result))
      failed = true
    else
      print(string.format("PASS: input: %s -> %s", tostring(tc.input), result))
    end
  end
  
  if failed then
    os.exit(1)
  else
    print("ALL HELPER TESTS PASSED!")
    os.exit(0)
  end
  ```

- [ ] **Step 2: 執行測試確認失敗或正確運作**
  Run: `lua scratch/test_helpers.lua`
  Expected: 印出 `ALL HELPER TESTS PASSED!` 並退出。

- [ ] **Step 3: 將 sanitizeName 邏輯寫入 layout_manager.lua**
  修改 `modules/layout_manager.lua`，在 `layoutPath` 下方加入安全過濾函數 `M.sanitizeName`。

  ```lua
  -- modules/layout_manager.lua
  -- 在原本的 layoutPath 函數後方加入：
  function M.sanitizeName(name)
    if not name then return "" end
    return name:gsub('[%/%\\%?%*%%&%|%^%`%;%<%>%:]', "")
  end
  ```

- [ ] **Step 4: 執行 Commit**
  ```bash
  git add scratch/test_helpers.lua modules/layout_manager.lua
  git commit -m "feat: add sanitizeName function and helper tests"
  ```

---

### Task 2: 建立 Webview 彈出選單的 HTML 範本 (WebView Template)

**Files:**
- Create: `modules/layout_selector_tmpl.html`

- [ ] **Step 1: 建立 HTML/CSS/JS 網頁範本**
  建立 `/Users/william/gitRepo/hammerspoon-layout-manager/modules/layout_selector_tmpl.html` 檔案，此為前端的完整靜態與互動頁面。

  ```html
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <style>
      body {
        margin: 0;
        padding: 0;
        background: #1e1e24;
        color: #f0f0f5;
        font-family: system-ui, -apple-system, sans-serif;
        font-size: 14px;
        user-select: none;
        overflow: hidden;
      }
      .container {
        display: flex;
        flex-direction: column;
        height: 100vh;
        box-sizing: border-box;
      }
      .header {
        background: #25252d;
        padding: 16px 20px;
        border-bottom: 1px solid #2f2f38;
        font-size: 16px;
        font-weight: 600;
      }
      .content {
        flex: 1;
        padding: 20px;
        overflow-y: auto;
        box-sizing: border-box;
      }
      .form-group {
        margin-bottom: 20px;
      }
      .form-group label {
        display: block;
        font-size: 12px;
        font-weight: 600;
        color: #a0a0b0;
        margin-bottom: 8px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
      }
      .form-group input {
        width: 100%;
        padding: 12px;
        border-radius: 6px;
        border: 1px solid #3e3e4a;
        background: #15151a;
        color: #fff;
        font-size: 14px;
        outline: none;
        box-sizing: border-box;
      }
      .form-group input:focus {
        border-color: #007acc;
      }
      .window-list-label {
        font-size: 12px;
        font-weight: 600;
        color: #a0a0b0;
        margin-bottom: 8px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
      }
      .app-group {
        background: #25252d;
        border-radius: 8px;
        padding: 12px;
        margin-bottom: 12px;
        border: 1px solid #2f2f38;
      }
      .app-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 8px;
        padding-bottom: 6px;
        border-bottom: 1px solid #32323d;
      }
      .app-title {
        font-weight: bold;
        color: #4fc1ff;
      }
      .screen-badge {
        font-size: 11px;
        background: #32323d;
        color: #a0a0b0;
        padding: 2px 6px;
        border-radius: 4px;
      }
      .window-items {
        display: flex;
        flex-direction: column;
        gap: 8px;
      }
      .window-item {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        cursor: pointer;
        color: #d0d0d8;
      }
      .window-item input[type="checkbox"] {
        margin-top: 3px;
        cursor: pointer;
      }
      .footer {
        padding: 16px 20px;
        border-top: 1px solid #2f2f38;
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        background: #1e1e24;
      }
      button {
        padding: 10px 20px;
        border-radius: 6px;
        border: none;
        font-size: 14px;
        cursor: pointer;
        font-weight: 500;
      }
      .btn-cancel {
        background: #32323d;
        color: #fff;
      }
      .btn-cancel:hover {
        background: #3e3e4a;
      }
      .btn-save {
        background: #007acc;
        color: #fff;
        font-weight: 600;
        box-shadow: 0 4px 12px rgba(0,122,204,0.3);
      }
      .btn-save:hover {
        background: #0098ff;
      }
      .error-msg {
        color: #ff5f56;
        font-size: 12px;
        margin-top: 6px;
        display: none;
      }
      .warning-msg {
        color: #ffbd2e;
        font-size: 12px;
        margin-top: 6px;
        display: none;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">💾 儲存視窗配置 (Save Layout)</div>
      <div class="content">
        <div class="form-group">
          <label for="layout-name">Layout 名稱</label>
          <input type="text" id="layout-name" placeholder="例如: Work, Coding, Browsing..." autofocus>
          <div id="error-msg" class="error-msg">請輸入 Layout 名稱</div>
          <div id="warning-msg" class="warning-msg">此名稱已存在，儲存將覆蓋舊配置</div>
        </div>
        
        <div class="window-list-label">選擇要包含的視窗</div>
        <div id="window-list">
          <!-- 視窗列表由 JS 動態生成 -->
        </div>
      </div>
      
      <div class="footer">
        <button class="btn-cancel" onclick="onCancel()">取消</button>
        <button class="btn-save" onclick="onSave()">儲存 Layout</button>
      </div>
    </div>

    <script>
      // Lua 注入的佔位符
      const windows = {{WINDOWS_JSON}};
      const existingLayouts = {{LAYOUTS_JSON}};

      // 初始化渲染
      const listContainer = document.getElementById('window-list');
      const inputField = document.getElementById('layout-name');
      const errorMsg = document.getElementById('error-msg');
      const warningMsg = document.getElementById('warning-msg');

      // 依 App 分組視窗
      const groups = {};
      windows.forEach(win => {
        if (!groups[win.app]) {
          groups[win.app] = {
            app: win.app,
            screen_name: win.screen_name,
            items: []
          };
        }
        groups[win.app].items.push(win);
      });

      // 生成 HTML
      Object.keys(groups).forEach(appKey => {
        const g = groups[appKey];
        const groupEl = document.createElement('div');
        groupEl.className = 'app-group';

        const headerEl = document.createElement('div');
        headerEl.className = 'app-header';
        headerEl.innerHTML = `
          <span class="app-title">${g.app}</span>
          <span class="screen-badge">🖥️ ${g.screen_name}</span>
        `;
        groupEl.appendChild(headerEl);

        const itemsEl = document.createElement('div');
        itemsEl.className = 'window-items';

        g.items.forEach((win, index) => {
          const itemEl = document.createElement('label');
          itemEl.className = 'window-item';
          // 使用唯一識別方式：z_index 或是 app+title+index
          const checkId = `win_${win.z_index}`;
          itemEl.innerHTML = `
            <input type="checkbox" id="${checkId}" checked data-app="${win.app}" data-title="${win.title.replace(/"/g, '&quot;')}">
            <span>${win.title || '(無標題視窗)'}</span>
          `;
          itemsEl.appendChild(itemEl);
        });

        groupEl.appendChild(itemsEl);
        listContainer.appendChild(groupEl);
      });

      // 重名檢測監聽器
      inputField.addEventListener('input', () => {
        errorMsg.style.display = 'none';
        const name = inputField.value.trim();
        const safeName = name.replace(/[\/\\?*%&|^`;<>:]/g, "");
        if (safeName && existingLayouts.includes(safeName)) {
          warningMsg.style.display = 'block';
        } else {
          warningMsg.style.display = 'none';
        }
      });

      // 快速鍵監聽 ESC
      window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
          onCancel();
        }
      });

      function onCancel() {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.hammerspoon) {
          window.webkit.messageHandlers.hammerspoon.postMessage({ action: "cancel" });
        }
      }

      function onSave() {
        const name = inputField.value.trim();
        if (!name) {
          errorMsg.style.display = 'block';
          inputField.focus();
          return;
        }

        // 收集所有被勾選的視窗資訊
        const selected = [];
        const checkboxes = listContainer.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(cb => {
          if (cb.checked) {
            selected.push({
              app: cb.getAttribute('data-app'),
              title: cb.getAttribute('data-title')
            });
          }
        });

        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.hammerspoon) {
          window.webkit.messageHandlers.hammerspoon.postMessage({
            action: "save",
            name: name,
            selected: selected
          });
        }
      }
    </script>
  </body>
  </html>
  ```

- [ ] **Step 2: 執行 Commit**
  ```bash
  git add modules/layout_selector_tmpl.html
  git commit -m "feat: create html template for layout selector webview"
  ```

---

### Task 3: 在 layout_manager 中實現儲存對話視窗與過濾儲存邏輯 (Core Module Changes)

**Files:**
- Modify: `modules/layout_manager.lua:98-119` (重構 save 函數，並新增 showSaveDialog)

- [ ] **Step 1: 修改 M.save 函數以支援視窗過濾**
  修改 `modules/layout_manager.lua` 的 `M.save` 函數，使其在傳入第二個參數 `selectedWindows` 時，僅儲存被勾選的視窗。

  ```lua
  -- modules/layout_manager.lua
  -- 修改原 M.save 函數：
  function M.save(name, selectedWindows)
    ensureDir()
    
    -- 安全過濾檔名
    local safeName = M.sanitizeName(name)
    if safeName == "" then
      hs.alert.show("無效的 Layout 名稱")
      return false
    end
  
    local allWindows = captureWindows()
    local finalWindows = allWindows
  
    -- 如果有提供過濾清單，進行篩選
    if selectedWindows then
      finalWindows = {}
      for _, win in ipairs(allWindows) do
        local isSelected = false
        for _, sel in ipairs(selectedWindows) do
          if sel.app == win.app and sel.title == win.title then
            isSelected = true
            break
          end
        end
        if isSelected then
          table.insert(finalWindows, win)
        end
      end
    end
  
    local layout = {
      name       = safeName,
      created_at = os.time(),
      screens    = captureScreens(),
      windows    = finalWindows,
    }
  
    local encoded = json.encode(layout, true) -- true = pretty print
    local file = io.open(layoutPath(safeName), "w")
    if not file then
      hs.alert.show("無法寫入 layout 檔案")
      return false
    end
    file:write(encoded)
    file:close()
  
    hs.alert.show(string.format("已儲存 layout：%s (%d 個視窗)", safeName, #layout.windows))
    return true
  end
  ```

- [ ] **Step 2: 實作 M.showSaveDialog 啟動 Webview 對話窗**
  在 `modules/layout_manager.lua` 的 `M.save` 上方或下方，新增 `M.showSaveDialog` 函數。

  ```lua
  -- modules/layout_manager.lua
  -- 新增 showSaveDialog 實作：
  local activeWebview = nil
  
  function M.showSaveDialog()
    -- 如果已有開啟的視窗，先將其關閉
    if activeWebview then
      activeWebview:delete()
      activeWebview = nil
    end
  
    local allWindows = captureWindows()
    if #allWindows == 0 then
      hs.alert.show("當前沒有可儲存的視窗")
      return
    end
  
    -- 取得每個視窗的螢幕中文/英文名稱以便呈現
    local allScreens = hs.screen.allScreens()
    for _, win in ipairs(allWindows) do
      for _, scr in ipairs(allScreens) do
        if tostring(scr:getUUID()) == win.screen_id then
          win.screen_name = scr:name()
          break
        end
      end
      win.screen_name = win.screen_name or "未知螢幕"
    end
  
    local existingLayouts = M.list()
  
    -- 動態取得範本檔案的路徑
    local currentFile = debug.getinfo(1).source:sub(2) -- 去除開頭的 '@'
    local currentDir = currentFile:match("(.+)/[^/]+$") or "."
    local templatePath = currentDir .. "/layout_selector_tmpl.html"
    
    local templateFile = io.open(templatePath, "r")
    if not templateFile then
      hs.alert.show("無法讀取視窗選擇器範本：" .. templatePath)
      return
    end
    local templateContent = templateFile:read("*all")
    templateFile:close()
  
    -- 取代佔位符
    templateContent = templateContent:gsub("{{WINDOWS_JSON}}", json.encode(allWindows))
    templateContent = templateContent:gsub("{{LAYOUTS_JSON}}", json.encode(existingLayouts))
  
    -- 初始化 hs.webview
    local rect = hs.geometry.rect(0, 0, 600, 500)
    activeWebview = hs.webview.new(rect, { developerExtrasEnabled = true })
    activeWebview:windowStyle(hs.webview.windowMasks.borderless)
    activeWebview:closeOnEscape(true)
    activeWebview:html(templateContent)
  
    -- 設定 callback 處理來自 JavaScript 的訊息
    activeWebview:userCallback(function(msg)
      if not msg then return end
      if msg.action == "cancel" then
        if activeWebview then
          activeWebview:delete()
          activeWebview = nil
        end
      elseif msg.action == "save" then
        if msg.name and msg.name ~= "" then
          M.save(msg.name, msg.selected)
        end
        if activeWebview then
          activeWebview:delete()
          activeWebview = nil
        end
      end
    end)
  
    activeWebview:show()
    
    -- 將視窗置中並取得焦點
    local win = activeWebview:hswindow()
    if win then
      win:centerOnScreen()
      win:focus()
    end
  end
  ```

- [ ] **Step 3: 執行 Commit**
  ```bash
  git add modules/layout_manager.lua
  git commit -m "feat: implement showSaveDialog and update save function to filter windows in layout_manager"
  ```

---

### Task 4: 更新快捷鍵綁定呼叫自訂對話框 (Keybinding Update)

**Files:**
- Modify: `init.lua:23-36`

- [ ] **Step 1: 修改 init.lua 快捷鍵綁定**
  開啟 `init.lua`，修改 `Cmd + Alt + S` 快捷鍵綁定，改為直接呼叫 `layoutManager.showSaveDialog()`。

  ```lua
  -- init.lua
  -- 修改前：
  -- hs.hotkey.bind(hyper, "S", function()
  --   hs.focus()
  --   local button, name = hs.dialog.textPrompt(...)
  --   ...
  -- end)
  
  -- 修改後：
  -- Cmd + Alt + S：開啟儲存 Layout 選擇器對話框
  hs.hotkey.bind(hyper, "S", function()
    layoutManager.showSaveDialog()
  end)
  ```

- [ ] **Step 2: 執行 Commit**
  ```bash
  git add init.lua
  git commit -m "feat: update S key shortcut to launch new window selection dialog"
  ```

---

## 驗證與測試流程 (Manual Testing Checklists)

在完成上述 Tasks 後，將專案部署至實際 Hammerspoon 環境，並依序進行以下測試以確認符合預期：

### 1. 部署配置
- 執行本地部署腳本將修改同步至 `~/.hammerspoon/`：
  ```bash
  bash scripts/deploy-hammerspoon.sh
  ```
- 重新載入 Hammerspoon 配置（點選選單列圖示 -> Reload Config 或重啟 Hammerspoon）。

### 2. 測試對話框彈出與焦點
- [ ] 開啟多個應用程式視窗，按下 `Cmd + Alt + S`。
- [ ] 驗證是否彈出無邊框的深色網頁視窗，且位置是否正好處在螢幕中央。
- [ ] 驗證 Layout 輸入欄位是否預設取得輸入焦點。
- [ ] 驗證是否能用鍵盤直接輸入字元。

### 3. 測試過濾儲存
- [ ] 勾選某些視窗並取消勾選某些視窗（例如取消勾選某個瀏覽器視窗）。
- [ ] 在輸入欄位輸入 `test_selection`。
- [ ] 點選「儲存 Layout」。
- [ ] 檢查 `~/.hammerspoon/layouts/test_selection.json` 檔案。
- [ ] 驗證 `windows` 欄位中是否確實**不包含**剛才取消勾選的視窗。

### 4. 測試取消與重名
- [ ] 按下 `Cmd + Alt + S` 叫出對話視窗。
- [ ] 按下鍵盤 `ESC` 鍵或點選「取消」按鈕，驗證對話框是否順利消失。
- [ ] 再次按 `Cmd + Alt + S`，輸入剛才已存過的 `test_selection`。
- [ ] 驗證輸入框下方是否出現黃色警告字體 `此名稱已存在，儲存將覆蓋舊配置`。
- [ ] 點擊「儲存 Layout」，驗證設定檔是否更新（時間戳變更）。

### 5. 測試 URL 觸發相容性
- [ ] 在終端機執行：
  ```bash
  open "hammerspoon://savelayout?name=auto_quick_save"
  ```
- [ ] 驗證是否**沒有**彈出任何 UI，且直接在 `~/.hammerspoon/layouts/auto_quick_save.json` 中背景寫入成功（包含當時所有的視窗，此為背景自動化相容功能）。
