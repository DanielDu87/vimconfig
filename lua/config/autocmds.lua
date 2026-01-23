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
		pcall(vim.diagnostic.config, {
			underline = true,
			virtual_text = true,
			signs = true,
			update_in_insert = true, -- 在插入模式下也实时更新 (更快反馈)
		}, { bufnr = args.buf })
	end,
})

-- 针对 Runner 日志的语法高亮
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "runnerlog" },
	callback = function(args)
		pcall(vim.treesitter.stop, args.buf)
		vim.api.nvim_set_hl(0, "RunnerLogTime", { fg = "#ff9e64", ctermfg = 215 })
		vim.api.nvim_set_hl(0, "RunnerDjangoCmdPath", { fg = "#7dcfff", ctermfg = 117 })
		vim.api.nvim_set_hl(0, "RunnerDjangoCmdContinuation", { fg = "#7dcfff", ctermfg = 117 })
		vim.api.nvim_set_hl(0, "RunnerPythonCmdLine", { fg = "#7dcfff", ctermfg = 117 })
		vim.api.nvim_set_hl(0, "RunnerDjangoServerUrl", { fg = "#7dcfff", underline = true, ctermfg = 117 })
		vim.api.nvim_set_hl(0, "RunnerLogPrefix", { link = "DiagnosticInfo" })
		vim.api.nvim_set_hl(0, "RunnerLogCommand", { fg = "#7dcfff", ctermfg = 117 })
		vim.api.nvim_set_hl(0, "RunnerLogPythonFlag", { fg = "#7dcfff", ctermfg = 117 })
		vim.api.nvim_set_hl(0, "RunnerLogOutput", { fg = "#E0E0E0", ctermfg = 254 })
		vim.api.nvim_set_hl(0, "RunnerLogPlainLine", { fg = "#E0E0E0", ctermfg = 254 })
		vim.api.nvim_set_hl(0, "RunnerLogErrorLine", { link = "DiagnosticError" })
		vim.api.nvim_set_hl(0, "RunnerLogWarnLine", { link = "DiagnosticWarn" })
		vim.api.nvim_set_hl(0, "RunnerLogSuccessLine", { link = "DiagnosticOk" })
		vim.api.nvim_set_hl(0, "RunnerLogUrl", { fg = "#7dcfff", underline = true })
		vim.api.nvim_set_hl(0, "RunnerLogPath", { fg = "#7dcfff" })
		vim.api.nvim_set_hl(0, "RunnerLogPathFull", { fg = "#7dcfff" })
		vim.api.nvim_set_hl(0, "RunnerLogInfo", { link = "DiagnosticInfo" })
		vim.api.nvim_set_hl(0, "RunnerLogDjangoRunserver", { fg = "#7dcfff", ctermfg = 117 })
		vim.api.nvim_set_hl(0, "RunnerLogDebugLine", { fg = "#888888", ctermfg = 245 })
	end,
})

-------------------------------------------------------------------------------
-- 全局透明效果增强 (支持任意主题切换)
-------------------------------------------------------------------------------

local function apply_transparency()
	-- 1. 基础背景透明组 (补全所有可能的背景层)
	local hl_groups = {
		"Normal",
		"NormalNC",
		"NonText",
		"EndOfBuffer",
		"Folded",
		"SignColumn",
		"StatusLine",
		"StatusLineNC",
		"VertSplit",
		"WinSeparator",
		"WinBar",
		"WinBarNC",
		"TabLine",
		"TabLineFill",
		"TabLineSel",
		"BufferLineFill",
		"BufferLineBackground",
		"BufferLineSeparator",
		"BufferLineSeparatorVisible",
		"BufferLineSeparatorSelected",
		"NormalFloat",
		"Pmenu",
		"PmenuSbar",
		"BlinkCmpMenu",
		"BlinkCmpDoc",
		"BlinkCmpSignatureHelp",
	}
	for _, group in ipairs(hl_groups) do
		vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
	end

	-- 2. 补全列表项细节透明 (BlinkCmp 专用)
	local blink_sub_groups = {
		"BlinkCmpLabel",
		"BlinkCmpLabelMatch",
		"BlinkCmpLabelDetail",
		"BlinkCmpLabelDescription",
		"BlinkCmpKind",
		"BlinkCmpKindIcon",
		"BlinkCmpSource",
		"BlinkCmpGhostText",
	}
	for _, group in ipairs(blink_sub_groups) do
		local ok, old_hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
		if ok then
			vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", old_hl, { bg = "NONE" }))
		else
			vim.api.nvim_set_hl(0, group, { bg = "NONE" })
		end
	end

	-- 3. 统一浮窗边框颜色 (蓝色风格)
	local border_color = "#2b85b7"
	local border_groups = {
		"FloatBorder",
		"FloatTitle",
		"NoiceConfirmBorder",
		"NoicePopupBorder",
		"NoiceCmdlinePopupBorder",
		"SnacksInputBorder",
		"SnacksWinBorder",
		"SnacksPickerBorder",
		"BlinkCmpMenuBorder",
		"BlinkCmpDocBorder",
		"BlinkCmpSignatureHelpBorder",
	}
	for _, group in ipairs(border_groups) do
		vim.api.nvim_set_hl(0, group, { fg = border_color, bg = "NONE" })
	end
end

-- 监听主题切换事件 (使用 schedule 确保在主题完全加载后执行)
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		vim.schedule(apply_transparency)
	end,
})

-- 立即执行一次
vim.schedule(apply_transparency)