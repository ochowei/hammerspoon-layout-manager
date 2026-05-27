--[[
  modules/url_handler.lua
  =========================
  註冊 hammerspoon:// URL scheme 的 handler

  支援的 URL：
    hammerspoon://saveLayout?name=<name>
    hammerspoon://loadLayout?name=<name>
    hammerspoon://listLayouts            (回傳到 console / alert)
    hammerspoon://deleteLayout?name=<name>
--]]

local M = {}

function M.register(layoutManager)
  -- saveLayout
  hs.urlevent.bind("saveLayout", function(eventName, params)
    local name = params.name
    if not name or name == "" then
      hs.alert.show("缺少 name 參數")
      return
    end
    layoutManager.save(name)
  end)

  -- loadLayout
  hs.urlevent.bind("loadLayout", function(eventName, params)
    local name = params.name
    if not name or name == "" then
      hs.alert.show("缺少 name 參數")
      return
    end
    layoutManager.load(name)
  end)

  -- listLayouts
  hs.urlevent.bind("listLayouts", function()
    local names = layoutManager.list()
    if #names == 0 then
      hs.alert.show("尚無已儲存的 layout")
    else
      hs.alert.show("已儲存：\n" .. table.concat(names, "\n"), 3)
    end
    -- 也印到 console，方便 debug
    print("[LayoutManager] Layouts:", hs.inspect(names))
  end)

  -- deleteLayout
  hs.urlevent.bind("deleteLayout", function(eventName, params)
    local name = params.name
    if not name or name == "" then
      hs.alert.show("缺少 name 參數")
      return
    end
    layoutManager.delete(name)
  end)
end

return M
