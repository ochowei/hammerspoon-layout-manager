--[[
  modules/url_handler.lua
  =========================
  註冊 hammerspoon:// URL scheme 的 handler

  支援的 URL：
    hammerspoon://savelayout?name=<name>
    hammerspoon://loadlayout?name=<name>
    hammerspoon://deletelayout?name=<name>
--]]

local M = {}

function M.register(layoutManager)
  -- savelayout
  hs.urlevent.bind("savelayout", function(eventName, params)
    local name = params.name
    if not name or name == "" then
      layoutManager.showSaveDialog()
      return
    end
    layoutManager.showSaveDialog(name)
  end)

  -- loadlayout
  hs.urlevent.bind("loadlayout", function(eventName, params)
    layoutManager.showLoadDialog()
  end)

  -- deletelayout
  hs.urlevent.bind("deletelayout", function(eventName, params)
    local name = params.name
    if not name or name == "" then
      hs.alert.show("缺少 name 參數")
      return
    end
    layoutManager.delete(name)
  end)
end

return M
