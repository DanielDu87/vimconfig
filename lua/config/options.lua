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

-- 编辑器背景透明
local function set_transparent_highlights()
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "NonText", { bg = "none" })
	vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
	vim.api.nvim_set_hl(0, "Folded", { bg = "none" })
	vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
	vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
	vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "VertSplit", { bg = "none" })
	vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
	vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })
	-- WinBar 透明
	vim.api.nvim_set_hl(0, "WinBar", { bg = "none" })
	vim.api.nvim_set_hl(0, "WinBarNC", { bg = "none" })
	-- 浮动窗口和侧边栏透明（兼容不同主题）
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatTitle", { bg = "none" })
	-- Snacks explorer 透明
	vim.api.nvim_set_hl(0, "SnacksPickerNormal", { bg = "none" })
	vim.api.nvim_set_hl(0, "SnacksPickerNormalNC", { bg = "none" })
	vim.api.nvim_set_hl(0, "SnacksPickerBorder", { bg = "none" })
	-- Snacks picker WinBar 透明
	vim.api.nvim_set_hl(0, "SnacksPickerWinBar", { bg = "none" })
	vim.api.nvim_set_hl(0, "SnacksPickerWinBarNC", { bg = "none" })
end

-- 主题加载时应用
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("TransparentBackground", { clear = true }),
	callback = function()
		set_transparent_highlights()
		-- 光标行固定颜色（所有主题）
		vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3d4458" })
		vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { link = "CursorLine" })
		-- WinBar 强制透明（所有主题）- 使用 default=true 强制覆盖
		vim.cmd("highlight! clear WinBar")
		vim.cmd("highlight! WinBar guibg=none ctermbg=none")
		vim.cmd("highlight! clear WinBarNC")
		vim.cmd("highlight! WinBarNC guibg=none ctermbg=none")
		-- 延迟再次应用，确保覆盖主题的后续设置
		vim.schedule(function()
			set_transparent_highlights()
			vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3d4458" })
			vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { link = "CursorLine" })
			vim.cmd("highlight! clear WinBar")
			vim.cmd("highlight! WinBar guibg=none ctermbg=none")
			vim.cmd("highlight! clear WinBarNC")
			vim.cmd("highlight! WinBarNC guibg=none ctermbg=none")
		end)
	end,
})

-- 立即应用一次
set_transparent_highlights()
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3d4458" })
vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { link = "CursorLine" })
vim.cmd("highlight! clear WinBar")
vim.cmd("highlight! WinBar guibg=none ctermbg=none")
vim.cmd("highlight! clear WinBarNC")
vim.cmd("highlight! WinBarNC guibg=none ctermbg=none")
-- 延迟再次应用
vim.schedule(function()
	set_transparent_highlights()
	vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3d4458" })
	vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { link = "CursorLine" })
	vim.cmd("highlight! clear WinBar")
	vim.cmd("highlight! WinBar guibg=none ctermbg=none")
	vim.cmd("highlight! clear WinBarNC")
	vim.cmd("highlight! WinBarNC guibg=none ctermbg=none")
end)

--==============================================================================
-- Tab 和缩进设置
--==============================================================================

-- 使用 tab 字符（而不是空格）
vim.opt.expandtab = false

-- Tab 宽度为 4
vim.opt.tabstop = 4

-- 自动缩进宽度为 4
vim.opt.shiftwidth = 4

-- 软制表符宽度（用于编辑操作）
vim.opt.softtabstop = 4

-- 示例：设置 Python 文件的缩进（根据需要取消注释）
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "python",
--   callback = function()
--     vim.opt_local.shiftwidth = 4
--     vim.opt_local.tabstop = 4
--   end,
-- })

--==============================================================================
-- 诊断设置：已移至 lua/plugins/diagnostics.lua（LazyVim 正规方式）
--==============================================================================

--==============================================================================
-- 折叠设置（修复 LSP folding 错误）
--==============================================================================

-- 使用 treesitter 折叠（而非 LSP folding）
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""

-- 默认展开所有折叠
vim.opt.foldenable = true
vim.opt.foldlevel = 99
