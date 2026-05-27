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
function M.save(name)
  ensureDir()

  local layout = {
    name       = name,
    created_at = os.time(),
    screens    = captureScreens(),
    windows    = captureWindows(),
  }

  local encoded = json.encode(layout, true) -- true = pretty print
  local file = io.open(layoutPath(name), "w")
  if not file then
    hs.alert.show("無法寫入 layout 檔案")
    return false
  end
  file:write(encoded)
  file:close()

  hs.alert.show(string.format("已儲存 layout：%s (%d 個視窗)", name, #layout.windows))
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

return M
