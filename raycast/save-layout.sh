#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Save Window Layout
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 💾
# @raycast.packageName Window Layouts
# @raycast.argument1 { "type": "text", "placeholder": "Layout name" }

# Documentation:
# @raycast.description 將當前視窗排列儲存為指定名稱的 layout
# @raycast.author You

NAME="$1"
if [ -z "$NAME" ]; then
  echo "請輸入 layout 名稱"
  exit 1
fi

# URL encode (簡單版，名稱不含特殊字元就 OK)
open "hammerspoon://savelayout?name=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$NAME")"
