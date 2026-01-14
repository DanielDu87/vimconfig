--==============================================================================
-- Neovim 自动命令配置
--==============================================================================
-- 这些自动命令会在 VeryLazy 事件时自动加载
--
-- LazyVim 已经预配置了大量实用的自动命令
-- 完整列表: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- 在此文件中添加任何额外的自定义自动命令

-- 注意：启动时自动打开 Explorer 的配置已移至 lua/plugins/explorer.lua

-- 示例：高亮复制（yank）的文本（根据需要取消注释）
-- vim.api.nvim_create_autocmd("TextYankPost", {
--   callback = function()
--     vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
--   end,
--   desc = "高亮被复制的文本",
-- })
