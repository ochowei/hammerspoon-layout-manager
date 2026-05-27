#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Load Window Layout
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📐
# @raycast.packageName Window Layouts
# @raycast.argument1 { "type": "text", "placeholder": "Layout name" }

# Documentation:
# @raycast.description 載入指定名稱的視窗 layout
# @raycast.author You

NAME="$1"
if [ -z "$NAME" ]; then
  echo "請輸入 layout 名稱"
  exit 1
fi

open "hammerspoon://loadlayout?name=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$NAME")"
