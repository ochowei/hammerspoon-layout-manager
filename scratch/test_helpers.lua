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
