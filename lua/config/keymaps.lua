--==============================================================================
-- Neovim 键位映射配置
--==============================================================================
-- 这些键位映射会在 VeryLazy 事件时自动加载
--
-- LazyVim 已经预配置了大量实用的键位映射
-- 完整列表: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- 使用 :LazyKeys 命令或 <leader>sk 查看所有键位映射

--==============================================================================
-- K 键关键词查询（中文化错误提示）
--==============================================================================
vim.keymap.set("n", "K", function()
	local keyword = vim.fn.expand("<cword>")
	local cmd = "man " .. vim.fn.shellescape(keyword) .. " 2>&1"

	local output = vim.fn.system(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		-- 翻译错误信息
		local translated = output:gsub("no manual entry for", "未找到手册条目：")
		vim.notify(translated, vim.log.levels.WARN, { title = "关键词查询" })
	else
		-- 正常显示手册页
		vim.cmd("Man " .. keyword)
	end
end, { desc = "关键词查询" })
