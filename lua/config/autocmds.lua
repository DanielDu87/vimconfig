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

-------------------------------------------------------------------------------
-- 文件类型检测
-------------------------------------------------------------------------------

-- 将文件名包含 "docker" 或 "dk" 的文件识别为 dockerfile（忽略大小写）
vim.filetype.add({
	pattern = {
		-- 匹配文件名包含 docker（忽略大小写）
		[".*[Dd][Oo][Cc][Kk][Ee][Rr].*"] = "dockerfile",
		-- 匹配文件名包含 dk（忽略大小写）
		[".*[Dd][Kk].*"] = "dockerfile",
	},
})

-------------------------------------------------------------------------------
-- 统一的格式化函数
-------------------------------------------------------------------------------

-- 通用格式化函数：保存时和 <leader>cf 都调用此函数
_G.UniversalFormat = function()
	local ft = vim.bo.filetype

	if ft == "html" then
		-- HTML 格式化 + 清理空行
		local pos = vim.fn.getpos(".")
		require("conform").format({ lsp_format = "fallback" })
		vim.cmd([[silent! %s/\s\+$//e]])
		vim.cmd([[silent! %g/^\s*$/d]])
		vim.fn.setpos(".", pos)
	elseif ft == "python" then
		-- Python 格式化 + 清理行尾空白
		vim.b.autoformat = false
		local pos = vim.fn.getpos(".")
		require("conform").format({ lsp_format = "never" })
		vim.cmd([[silent! %s/\s\+$//e]])
		vim.fn.setpos(".", pos)
	else
		-- 其他文件：LazyVim 格式化 + 清理行尾空白
		local pos = vim.fn.getpos(".")
		require("lazyvim.util.format").format({ force = true })
		vim.cmd([[silent! %s/\s\+$//e]])
		vim.fn.setpos(".", pos)
	end
end

-- 所有文件保存时：统一使用 UniversalFormat
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = {
		"*.html", "*.htm",
		"*.css", "*.js", "*.ts", "*.tsx", "*.jsx", "*.vue",
		"*.json", "*.md", "*.lua", "*.sh", "*.py",
	},
	callback = function()
		_G.UniversalFormat()
	end,
})
