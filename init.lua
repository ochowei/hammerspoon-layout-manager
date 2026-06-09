--[[
  Hammerspoon Window Layout Manager
  ===================================
  入口檔案：載入模組、註冊快捷鍵、註冊 URL handler

  安裝方式：
    1. 安裝 Hammerspoon (https://www.hammerspoon.org/)
    2. 把這整個資料夾的內容放到 ~/.hammerspoon/
    3. 開啟 Hammerspoon，授予 Accessibility 權限
    4. 點選選單列的 Hammerspoon 圖示 → Reload Config
--]]

-- 載入核心模組
local layoutManager = require("modules.layout_manager")
local urlHandler   = require("modules.url_handler")

-- ============================================================
-- 快捷鍵綁定
-- ============================================================
-- 修飾鍵組合：cmd + alt (Option)
local hyper = {"cmd", "alt"}

-- Cmd + Alt + S：開啟儲存 Layout 選擇器對話框
hs.hotkey.bind(hyper, "S", function()
  layoutManager.showSaveDialog()
end)

-- Cmd + Alt + L：載入 layout（會彈出選單讓你選）
hs.hotkey.bind(hyper, "L", function()
  local layouts = layoutManager.list()
  if #layouts == 0 then
    hs.alert.show("尚無已儲存的 layout")
    return
  end

  -- 用 chooser 做選單
  local choices = {}
  for _, name in ipairs(layouts) do
    table.insert(choices, { text = name })
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      layoutManager.load(choice.text)
    end
  end)
  chooser:choices(choices)
  chooser:placeholderText("選擇要載入的 layout")
  chooser:show()
end)

-- Cmd + Alt + D：刪除 layout
hs.hotkey.bind(hyper, "D", function()
  local layouts = layoutManager.list()
  if #layouts == 0 then
    hs.alert.show("尚無已儲存的 layout")
    return
  end

  local choices = {}
  for _, name in ipairs(layouts) do
    table.insert(choices, { text = name })
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      layoutManager.delete(choice.text)
    end
  end)
  chooser:choices(choices)
  chooser:placeholderText("選擇要刪除的 layout")
  chooser:show()
end)

-- ============================================================
-- URL handler 註冊（給 Raycast 用）
-- ============================================================
-- 註冊後可以這樣呼叫：
--   open "hammerspoon://savelayout?name=work"
--   open "hammerspoon://loadlayout?name=work"
--   open "hammerspoon://listlayouts"
urlHandler.register(layoutManager)

-- 啟動完成提示
hs.alert.show("Layout Manager 已載入 ✓")
print("[LayoutManager] Ready. Shortcuts: Cmd+Alt+S (save), Cmd+Alt+L (load), Cmd+Alt+D (delete)")
