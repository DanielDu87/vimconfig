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
-- 自动格式化
-------------------------------------------------------------------------------

-- 所有文件保存时：统一使用自定义格式化逻辑
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = {
		"*.html",
		"*.htm",
		"*.css",
		"*.js",
		"*.ts",
		"*.tsx",
		"*.jsx",
		"*.vue",
		"*.json",
		"*.md",
		"*.lua",
		"*.sh",
		"*.py",
		"*.sql",
		"*.go",
		"Dockerfile*",
		"*dockerfile*",
		"dockerfile",
	},
	callback = function()
		vim.b.autoformat = false
		require("util.format").format()
	end,
})

-------------------------------------------------------------------------------
-- 针对特定文件类型的特殊设置
-------------------------------------------------------------------------------

-- 针对 Markdown 文件的视觉优化 (极致清净模式)
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown" },
	callback = function(args)
		-- 1. 禁用内显提示 (保持文字清爽)
		pcall(vim.lsp.inlay_hint.enable, false, { bufnr = args.buf })
		-- 2. 彻底关闭该 Buffer 的诊断显示 (Neovim 0.10+ 标准写法)
		pcall(vim.diagnostic.enable, false, { bufnr = args.buf })
		-- 3. 强制清空已有的报错数据
		vim.diagnostic.reset(nil, args.buf)
	end,
})

-- 针对 HTML 文件的纠错增强 (实时显示错误)
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "html" },
	callback = function(args)
		-- 1. 强制启用该 Buffer 的诊断引擎
		pcall(vim.diagnostic.enable, true, { bufnr = args.buf })
		-- 2. 开启所有视觉提示：行尾文字、下划线、侧边栏图标
		vim.diagnostic.config({
			underline = true,
			virtual_text = true,
			signs = true,
			update_in_insert = true, -- 在插入模式下也实时更新 (更快反馈)
		}, args.buf)
	end,
})
