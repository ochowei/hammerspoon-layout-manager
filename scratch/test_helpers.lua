-- scratch/test_helpers.lua
-- Mock hs table to satisfy requirements of modules/layout_manager.lua
_G.hs = {
  json = {},
  fs = {}
}

-- Add current directory to package path to load modules
package.path = "./?.lua;" .. package.path
local layout_manager = require("modules.layout_manager")

-- 測試用例
local test_cases = {
  -- Standard strings
  { input = "work-focus", expected = "work-focus" },
  { input = "work/focus", expected = "workfocus" },
  { input = "work\\focus?*today", expected = "workfocustoday" },
  { input = "my:layout;name", expected = "mylayoutname" },
  
  -- Whitespace trimming
  { input = "  work-focus  ", expected = "work-focus" },
  { input = "   ", expected = "" },
  { input = "\twork-focus\n", expected = "work-focus" },
  
  -- Non-string inputs
  { input = 123, expected = "123" },
  { input = true, expected = "true" },
  { input = false, expected = "false" },
  { input = nil, expected = "" },
  
  -- Missing/New blacklisted characters: %, &, |, ^, `, <, >
  { input = "percent%test", expected = "percenttest" },
  { input = "ampersand&test", expected = "ampersandtest" },
  { input = "pipe|test", expected = "pipetest" },
  { input = "caret^test", expected = "carettest" },
  { input = "backtick`test", expected = "backticktest" },
  { input = "less<test", expected = "lesstest" },
  { input = "greater>test", expected = "greatertest" },
  { input = "all/%\\?*%&|^`;<>:chars", expected = "allchars" }
}

local failed = false
for _, tc in ipairs(test_cases) do
  local result = layout_manager.sanitizeName(tc.input)
  if result ~= tc.expected then
    print(string.format("FAIL: input: %s (%s), expected: %q, got: %q", 
      tostring(tc.input), type(tc.input), tc.expected, result))
    failed = true
  else
    print(string.format("PASS: input: %s (%s) -> %q", 
      tostring(tc.input), type(tc.input), result))
  end
end

if failed then
  os.exit(1)
else
  print("ALL HELPER TESTS PASSED!")
  os.exit(0)
end
