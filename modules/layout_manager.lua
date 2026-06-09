--[[
  modules/layout_manager.lua
  ===========================
  核心邏輯：儲存 / 載入 / 列出 / 刪除 layout

  每個 layout 是一個 JSON 檔，存在 ~/.hammerspoon/layouts/<name>.json
  結構：
  {
    "name": "work",
    "created_at": 1700000000,
    "screens": [ { "id": "...", "frame": {...} }, ... ],
    "windows": [
      {
        "app": "Google Chrome",
        "title": "...",
        "screen_id": "...",
        "frame": { "x": 0, "y": 0, "w": 1280, "h": 800 },
        "z_index": 0
      },
      ...
    ]
  }
--]]

local M = {}

local json     = hs.json
local fs       = hs.fs
local LAYOUT_DIR = os.getenv("HOME") .. "/.hammerspoon/layouts"

-- 確保 layout 目錄存在
local function ensureDir()
  if not fs.attributes(LAYOUT_DIR) then
    fs.mkdir(LAYOUT_DIR)
  end
end

local function layoutPath(name)
  return LAYOUT_DIR .. "/" .. name .. ".json"
end

function M.sanitizeName(name)
  if name == nil then return "" end
  name = tostring(name):gsub("^%s*(.-)%s*$", "%1")
  return name:gsub('[%/%\\%?%*%%&%|%^%`%;%<%>%:]', "")
end

-- ============================================================
-- 收集當前所有可見視窗的狀態
-- ============================================================
local function captureWindows()
  local windows = {}
  -- orderedWindows 回傳的順序就是 z-order（最前面的在第 1 個）
  local ordered = hs.window.orderedWindows()

  for i, win in ipairs(ordered) do
    -- 過濾掉非標準視窗（例如沒有標題列的浮動 UI 元件）
    if win:isStandard() and win:isVisible() then
      local app    = win:application()
      local screen = win:screen()
      local frame  = win:frame()

      table.insert(windows, {
        id        = win:id(),
        app       = app and app:name() or "Unknown",
        title     = win:title() or "",
        screen_id = tostring(screen:getUUID()),
        frame = {
          x = frame.x,
          y = frame.y,
          w = frame.w,
          h = frame.h,
        },
        -- z_index 數字越小越前面（最前景 = 0）
        z_index = i - 1,
      })
    end
  end

  return windows
end

-- 收集當前所有螢幕的資訊（給載入時對應用）
local function captureScreens()
  local screens = {}
  for _, scr in ipairs(hs.screen.allScreens()) do
    local frame = scr:frame()
    table.insert(screens, {
      id   = tostring(scr:getUUID()),
      name = scr:name(),
      frame = {
        x = frame.x,
        y = frame.y,
        w = frame.w,
        h = frame.h,
      },
    })
  end
  return screens
end

-- ============================================================
-- 儲存當前 layout
-- ============================================================
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
        if sel.id and tonumber(sel.id) == win.id then
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

-- ============================================================
-- 載入指定 layout
-- ============================================================
function M.load(name)
  local file = io.open(layoutPath(name), "r")
  if not file then
    hs.alert.show("找不到 layout：" .. name)
    return false
  end
  local content = file:read("*all")
  file:close()

  local layout = json.decode(content)
  if not layout or not layout.windows then
    hs.alert.show("Layout 檔案格式錯誤")
    return false
  end

  -- 先檢查哪些 app 沒在執行
  local missingApps = {}
  local seenApps    = {}
  for _, w in ipairs(layout.windows) do
    if not seenApps[w.app] then
      seenApps[w.app] = true
      if not hs.application.find(w.app) then
        table.insert(missingApps, w.app)
      end
    end
  end

  -- 若有缺少的 app，跳出提示讓使用者決定
  if #missingApps > 0 then
    local appList = table.concat(missingApps, ", ")
    local button = hs.dialog.blockAlert(
      "部分 app 未啟動",
      string.format("以下 app 沒在執行：\n%s\n\n要怎麼處理？", appList),
      "啟動並套用",
      "跳過未啟動的",
      "取消"
    )

    if button == "取消" then
      return false
    elseif button == "啟動並套用" then
      -- 啟動所有缺少的 app
      for _, appName in ipairs(missingApps) do
        hs.application.launchOrFocus(appName)
      end
      -- 等待 app 啟動（粗暴但簡單的做法）
      hs.alert.show("等待 app 啟動中...")
      hs.timer.doAfter(2.5, function()
        M._applyLayout(layout)
      end)
      return true
    end
    -- "跳過未啟動的" → 繼續往下，applyLayout 內會自己跳過
  end

  M._applyLayout(layout)
  return true
end

-- ============================================================
-- 實際套用 layout 到視窗上（內部函式）
-- ============================================================
function M._applyLayout(layout)
  -- 建立 screen UUID 對應表，方便比對
  local currentScreens = {}
  for _, scr in ipairs(hs.screen.allScreens()) do
    currentScreens[tostring(scr:getUUID())] = scr
  end

  -- 依 z_index 由大到小套用（最大的最先處理，最後處理的會在最前面）
  table.sort(layout.windows, function(a, b)
    return (a.z_index or 0) > (b.z_index or 0)
  end)

  local appliedCount = 0
  local skippedCount = 0

  for _, w in ipairs(layout.windows) do
    local app = hs.application.find(w.app)
    if app then
      -- 找出此 app 中最匹配的視窗：先比 title，再 fallback 到主視窗
      local targetWin = nil
      for _, win in ipairs(app:allWindows()) do
        if win:title() == w.title and win:isStandard() then
          targetWin = win
          break
        end
      end
      if not targetWin then
        targetWin = app:mainWindow()
      end

      if targetWin then
        -- 嘗試找到原本的螢幕；若該螢幕已不存在則退回主螢幕
        local targetScreen = currentScreens[w.screen_id] or hs.screen.primaryScreen()
        targetWin:moveToScreen(targetScreen, false, true)
        targetWin:setFrame(hs.geometry.rect(w.frame.x, w.frame.y, w.frame.w, w.frame.h))
        targetWin:raise()  -- 把它帶到前面（之後處理的會蓋過先處理的，達成 z-order）
        appliedCount = appliedCount + 1
      else
        skippedCount = skippedCount + 1
      end
    else
      skippedCount = skippedCount + 1
    end
  end

  hs.alert.show(string.format(
    "已套用 layout：%s（%d 套用 / %d 跳過）",
    layout.name, appliedCount, skippedCount
  ))
end

-- ============================================================
-- 列出所有已儲存的 layout
-- ============================================================
function M.list()
  ensureDir()
  local names = {}
  for file in fs.dir(LAYOUT_DIR) do
    -- 防護：fs.dir 可能丟出非字串值；gsub 回傳兩個值，要用括號只取第一個
    if type(file) == "string" and file:match("%.json$") then
      table.insert(names, (file:gsub("%.json$", "")))
    end
  end
  table.sort(names)
  return names
end

-- ============================================================
-- 刪除指定 layout
-- ============================================================
function M.delete(name)
  local ok, err = os.remove(layoutPath(name))
  if ok then
    hs.alert.show("已刪除：" .. name)
    return true
  else
    hs.alert.show("刪除失敗：" .. (err or "未知錯誤"))
    return false
  end
end

-- ============================================================
-- Webview 儲存對話視窗與過濾邏輯
-- ============================================================

-- 純文字替換函數（防止 gsub 的模式特有字元 % 崩潰）
local function plainReplace(str, search, replace)
  local result = {}
  local start = 1
  while true do
    local pos = str:find(search, start, true) -- true 代表純文字搜尋
    if not pos then
      table.insert(result, str:sub(start))
      break
    end
    table.insert(result, str:sub(start, pos - 1))
    table.insert(result, replace)
    start = pos + #search
  end
  return table.concat(result)
end

-- 轉義 HTML 腳本注入字元
local function escapeJSONForHTML(jsonStr)
  return jsonStr:gsub("<", "\\u003c")
end

local activeWebview = nil

function M.showSaveDialog(defaultName)
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

  -- 取得每個視窗的螢幕名稱以便呈現
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
  local currentFile = debug.getinfo(1).source:sub(2)
  local currentDir = currentFile:match("(.+)/[^/]+$") or "."
  local templatePath = currentDir .. "/layout_selector_tmpl.html"
  
  local templateFile = io.open(templatePath, "r")
  if not templateFile then
    hs.alert.show("無法讀取視窗選擇器範本：" .. templatePath)
    return
  end
  local templateContent = templateFile:read("*all")
  templateFile:close()

  -- 安全編碼並進行純文字替換
  local windowsJson = escapeJSONForHTML(json.encode(allWindows))
  local layoutsJson = escapeJSONForHTML(json.encode(existingLayouts))

  local defaultNameSafe = escapeJSONForHTML(defaultName or "")

  templateContent = plainReplace(templateContent, "{{WINDOWS_JSON}}", windowsJson)
  templateContent = plainReplace(templateContent, "{{LAYOUTS_JSON}}", layoutsJson)
  templateContent = plainReplace(templateContent, "{{DEFAULT_NAME}}", defaultNameSafe)

  -- 預先計算置中座標，避免 hswindow() 的非同步 race condition
  local mainScreen = hs.screen.mainScreen() or hs.screen.primaryScreen()
  local screenFrame = mainScreen and mainScreen:frame() or { x = 0, y = 0, w = 1920, h = 1080 }
  local w, h = 600, 500
  local x = screenFrame.x + (screenFrame.w - w) / 2
  local y = screenFrame.y + (screenFrame.h - h) / 2
  local rect = hs.geometry.rect(x, y, w, h)

  -- 設定 usercontent controller 處理來自 JavaScript 的訊息
  local uc = hs.webview.usercontent.new("hammerspoon")
  uc:setCallback(function(msg)
    if not msg or not msg.body then return end
    local body = msg.body
    if body.action == "cancel" then
      if activeWebview then
        activeWebview:delete()
        activeWebview = nil
      end
    elseif body.action == "save" then
      if body.name and body.name ~= "" then
        M.save(body.name, body.selected)
      end
      if activeWebview then
        activeWebview:delete()
        activeWebview = nil
      end
    end
  end)

  -- 初始化 hs.webview，傳入 usercontent controller
  activeWebview = hs.webview.new(rect, { developerExtrasEnabled = true }, uc)
  activeWebview:windowStyle(hs.webview.windowMasks.borderless)
  activeWebview:closeOnEscape(true)
  activeWebview:html(templateContent)
  activeWebview:level(hs.drawing.windowLevels.floating)
  activeWebview:allowTextEntry(true)

  activeWebview:show()
  
  -- 延遲取得焦點，以防非同步視窗尚未建立完成
  hs.timer.doAfter(0.1, function()
    if activeWebview then
      local win = activeWebview:hswindow()
      if win then
        win:focus()
      end
    end
  end)
end

return M
