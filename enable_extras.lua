-- 自动启用 extras 的脚本
-- 运行: nvim -l ~/.config/nvim/enable_extras.lua

local file = vim.fn.expand("~/.config/nvim/lua/plugins/extras.lua")
local content = vim.fn.readfile(file)

-- 启用所有被注释的 extras
for i, line in ipairs(content) do
  if line:match("^  -- { import = \"lazyvim%.plugins%.extras") then
    content[i] = line:gsub("^  -- ", "  ")
  end
end

vim.fn.writefile(content, file)
print("✅ 所有 extras 已启用！")
print("请重启 Neovim：nvim")
