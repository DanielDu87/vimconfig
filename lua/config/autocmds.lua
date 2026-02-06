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
-- 全局透明背景配置（所有主题通用）
-------------------------------------------------------------------------------

-- 当开启透明模式时，自动应用透明设置到任何主题
if vim.g.transparent_enabled then
	local theme_util = require("util.theme")
	-- 主题加载后应用（多次延迟确保生效）
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			theme_util.apply_transparency_delayed()
		end,
	})
	-- User 主题配置加载后再应用一次
	vim.api.nvim_create_autocmd("User", {
		pattern = "LazyVimThemeChanged",
		callback = function()
			theme_util.apply_transparency_delayed()
		end,
	})
	-- 启动时应用
	vim.defer_fn(function()
		theme_util.apply_transparency()
	end, 100)
end

-------------------------------------------------------------------------------
-- 文件类型检测
-------------------------------------------------------------------------------

-- 将文件名包含 "docker" 或 "dk" 的文件识别为 dockerfile（忽略大小写）
-- 注意：使用更精确的模式，避免匹配到路径中的目录名（如 /Code/Docker/index.html）
vim.filetype.add({
	pattern = {
		-- 匹配文件名中包含 docker（忽略大小写）的文件
		-- 例如：dockerfile-copy, django-dockerfile, Dockerfile.prod, Dockerfile.dev
		[".*[Dd][Oo][Cc][Kk][Ee][Rr].*"] = "dockerfile",
		-- 匹配文件名中包含 dk（忽略大小写）的文件
		-- 例如：Dockerfile.dk, app.dk
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

-- 针对 Runner 日志的语法高亮
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "runnerlog" },
	callback = function(args)
		pcall(vim.treesitter.stop, args.buf)
		vim.api.nvim_set_hl(0, 'RunnerLogTime', { fg = '#ff9e64', ctermfg = 215 })
		vim.api.nvim_set_hl(0, 'RunnerDjangoCmdPath', { fg = '#7dcfff', ctermfg = 117 })
		vim.api.nvim_set_hl(0, 'RunnerDjangoCmdContinuation', { fg = '#7dcfff', ctermfg = 117 })
		vim.api.nvim_set_hl(0, 'RunnerPythonCmdLine', { fg = '#7dcfff', ctermfg = 117 })
		vim.api.nvim_set_hl(0, 'RunnerDjangoServerUrl', { fg = '#7dcfff', underline = true, ctermfg = 117 })
		vim.api.nvim_set_hl(0, 'RunnerLogPrefix', { link = 'DiagnosticInfo' })
		vim.api.nvim_set_hl(0, 'RunnerLogCommand', { fg = '#7dcfff', ctermfg = 117 })
		vim.api.nvim_set_hl(0, 'RunnerLogPythonFlag', { fg = '#7dcfff', ctermfg = 117 })
		vim.api.nvim_set_hl(0, 'RunnerLogOutput', { fg = '#E0E0E0', ctermfg = 254 })
		vim.api.nvim_set_hl(0, 'RunnerLogPlainLine', { fg = '#E0E0E0', ctermfg = 254 })
		vim.api.nvim_set_hl(0, 'RunnerLogErrorLine', { link = 'DiagnosticError' })
		vim.api.nvim_set_hl(0, 'RunnerLogWarnLine', { link = 'DiagnosticWarn' })
		vim.api.nvim_set_hl(0, 'RunnerLogSuccessLine', { link = 'DiagnosticOk' })
		vim.api.nvim_set_hl(0, 'RunnerLogUrl', { fg = '#7dcfff', underline = true })
		vim.api.nvim_set_hl(0, 'RunnerLogPath', { fg = '#7dcfff' })
		vim.api.nvim_set_hl(0, 'RunnerLogPathFull', { fg = '#7dcfff' })
		vim.api.nvim_set_hl(0, 'RunnerLogInfo', { link = 'DiagnosticInfo' })
		vim.api.nvim_set_hl(0, 'RunnerLogDjangoRunserver', { fg = '#7dcfff', ctermfg = 117 })
		vim.api.nvim_set_hl(0, 'RunnerLogDebugLine', { fg = '#888888', ctermfg = 245 })
	end,
})

-------------------------------------------------------------------------------
-- Tailwind CSS 自动激活逻辑
-------------------------------------------------------------------------------

-- 编辑 HTML 时，若无 tailwind 配置，则自动创建一个最简版以激活 LSP
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	pattern = { "*.html", "*.htm", "*.htmldjango" },
	callback = function()
		-- 获取当前文件所在目录
		local file_path = vim.api.nvim_buf_get_name(0)
		if file_path == "" or file_path:match("^[a-z]+://") then return end
		local file_dir = vim.fn.fnamemodify(file_path, ":p:h")
		
		-- 寻找项目根目录 (优先寻找 .git 或 package.json)
		local root = file_dir
		local ok, lspconfig_util = pcall(require, "lspconfig.util")
		if ok then
			local lsp_root = lspconfig_util.root_pattern(".git", "package.json", "tailwind.config.js")(file_path)
			if lsp_root then
				root = lsp_root
			end
		end

		-- 如果根目录是家目录，为了安全起见，回退到文件所在目录
		if root == vim.fn.expand("~") then
			root = file_dir
		end

		local tailwind_config = root .. "/tailwind.config.js"

		-- 如果配置文件不存在，则创建一个最简版本
		if vim.fn.filereadable(tailwind_config) == 0 then
			local content = {
				"/** @type {import('tailwindcss').Config} */",
				"module.exports = {",
				"	content: [\"./**/*.{html,js,vue,jsx,tsx}\"],",
				"	theme: {",
				"		extend: {},",
				"	},",
				"	plugins: [],",
				"}",
			}
			vim.fn.writefile(content, tailwind_config)

			-- 重要：文件创建后，需要强制重启服务器以确保它重新扫描项目根目录
			vim.defer_fn(function()
				vim.cmd("LspRestart tailwindcss")
				vim.defer_fn(function()
					if not vim.api.nvim_get_option_value("modified", { buf = 0 }) then
						vim.cmd("edit")
					end
				end, 500)
			end, 500)
		end
	end,
})

