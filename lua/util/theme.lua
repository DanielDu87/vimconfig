local M = {}

---@class TransparencyOpts
---@field force? boolean

-- 透明设置函数
function M.apply_transparency()
	local highlights = {
		-- 核心背景（最关键）
		"Normal", "NormalNC",
		-- 浮动窗口
		"NormalFloat", "FloatBorder",
		-- 文件浏览器
		"SnacksExplorer", "SnacksExplorerTitle",
		-- 状态栏和标签栏
		"StatusLine", "StatusLineNC", "TabLine", "TabLineFill", "WinBar", "WinBarNC",
		-- WhichKey 菜单
		"WhichKeyFloat", "WhichKeyBorder", "WhichKeyTitle", "WhichKeyGroup",
		"WhichKeySeparator", "WhichKeyValue", "WhichKeyIcon", "WhichKeyDesc",
		-- Snacks Picker
		"SnacksPicker", "SnacksPickerBorder", "SnacksPickerTitle",
		-- 其他常见 UI 元素
		"Pmenu", "PmenuSbar", "PmenuThumb",
		"TelescopeNormal", "TelescopeBorder", "TelescopeTitle",
		"LazyNormal", "LazyButton",
		"MasonNormal", "MasonHeader",
		"NoiceCmdlinePopup", "NoiceCmdlinePopupBorder", "NoicePopup", "NoicePopupBorder",
		-- 终端
		"Terminal", "TermNormal",
		-- 其他可能影响透明度的元素
		"Folded", "SignColumn", "WinSeparator",
	}
	for _, name in ipairs(highlights) do
		vim.api.nvim_set_hl(0, name, { bg = "NONE", force = true })
	end
	-- 单独设置分割线前景色（防止被重置为白色）
	vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#565f89", bg = "NONE", bold = true, force = true })
	vim.api.nvim_set_hl(0, "VertSplit", { fg = "#565f89", bg = "NONE", force = true })
	-- 单独设置 WhichKey 前景色（防止被重置为白色）
	vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#2b85b7", bg = "NONE", force = true })
	vim.api.nvim_set_hl(0, "WhichKeyIcon", { fg = "#9aa5ce", bg = "NONE", force = true })
	vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = "#9aa5ce", bg = "NONE", force = true })
	vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = "#565f89", bg = "NONE", force = true })
	vim.api.nvim_set_hl(0, "WhichKeyValue", { fg = "#7dcfff", bg = "NONE", force = true })
	vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = "#c0caf5", bg = "NONE", force = true })
end

-- 延迟应用透明（多次尝试确保覆盖主题设置）
function M.apply_transparency_delayed()
	local delays = { 0, 10, 50, 100 } -- 多个延迟时间
	for _, delay in ipairs(delays) do
		vim.defer_fn(M.apply_transparency, delay)
	end
end

return M
