#!/bin/bash
# 启用所有 LazyVim extras

CONFIG_FILE="$HOME/.config/nvim/lua/plugins/extras.lua"

# 取消注释所有 extras
sed -i '' 's/^  -- { import = "/  { import = "/g' "$CONFIG_FILE"

echo "✅ Extras 已启用！"
echo "请重启 Neovim："
echo "  :qa!"
echo "  nvim"
