local M = {}

---@class TransparencyOpts
---@field force? boolean

-- 透明设置函数
function M.apply_transparency()
	local highlights = {
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
		"Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb",
		"TelescopeNormal", "TelescopeBorder", "TelescopeTitle",
		"LazyNormal", "LazyButton",
		"MasonNormal", "MasonHeader",
		"NoiceCmdlinePopup", "NoiceCmdlinePopupBorder", "NoicePopup", "NoicePopupBorder",
	}
	for _, name in ipairs(highlights) do
		vim.api.nvim_set_hl(0, name, { bg = "NONE", force = true })
	end
end

-- 延迟应用透明（多次尝试确保覆盖主题设置）
function M.apply_transparency_delayed()
	local delays = { 0, 10, 50, 100 } -- 多个延迟时间
	for _, delay in ipairs(delays) do
		vim.defer_fn(M.apply_transparency, delay)
	end
end

return M
