--==============================================================================
-- Neovim 基础选项配置
--==============================================================================
-- 这些选项会在 lazy.nvim 启动之前自动加载
--
-- LazyVim 已经预配置了大量合理的默认选项
-- 完整列表: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
--
-- 在此文件中添加任何额外的自定义选项即可

--==============================================================================
-- 背景透明设置
--==============================================================================

-- 启用透明背景
vim.opt.winblend = 20                   -- 浮动窗口透明度 (0-100，越大越透明)
vim.opt.pumblend = 20                   -- 补全菜单透明度 (0-100，越大越透明)

-- 设置背景为暗色（配合透明效果）
vim.opt.background = "dark"

-- 启用真颜色支持
vim.opt.termguicolors = true

-- 设置窗口边框样式（单字符）
vim.opt.winborder = "single"

-- 示例：设置 Python 文件的缩进（根据需要取消注释）
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "python",
--   callback = function()
--     vim.opt_local.shiftwidth = 4
--     vim.opt_local.tabstop = 4
--   end,
-- })
