--==============================================================================
-- 自动启用 LazyVim Extras 脚本
--==============================================================================
-- 本脚本用于批量启用 lua/plugins/extras.lua 中所有被注释的 extras
--
-- 使用方法：
--   在终端运行：nvim -l ~/.config/nvim/enable_extras.lua
--
-- 功能说明：
--   该脚本会自动取消 extras.lua 文件中所有被注释的 import 语句
--   例如：-- { import = "lazyvim.plugins.extras.lang.go" }
--   会变为：{ import = "lazyvim.plugins.extras.lang.go" }
--
-- 注意事项：
--   1. 运行前建议备份配置文件
--   2. 启用更多 extras 会增加首次启动时间（需要安装更多插件）
--   3. 某些 extras 可能需要额外的系统依赖（如 go、rust 等语言环境）
--   4. 修改后需要重启 Neovim 才能生效

--==============================================================================
-- 读取 extras.lua 文件
--==============================================================================
local file = vim.fn.expand("~/.config/nvim/lua/plugins/extras.lua")
local content = vim.fn.readfile(file)

--==============================================================================
-- 启用所有被注释的 extras
--==============================================================================
-- 遍历文件每一行，匹配被注释的 extras import 语句
-- 匹配模式：行首有两个空格，然后是 --，接着是 { import = "lazyvim.plugins.extras...
for i, line in ipairs(content) do
  if line:match("^  -- { import = \"lazyvim%.plugins%.extras") then
    -- 取消注释（删除行首的 "-- "）
    content[i] = line:gsub("^  -- ", "  ")
  end
end

--==============================================================================
-- 写回文件并提示
--==============================================================================
vim.fn.writefile(content, file)
print("✅ 所有 extras 已启用！")
print("请重启 Neovim：nvim")
