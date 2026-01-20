--==============================================================================
-- 统一所有浮窗边框颜色
--==============================================================================
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local border_color = "#2b85b7"
		-- 通用浮窗边框
		vim.api.nvim_set_hl(0, "FloatBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
		vim.api.nvim_set_hl(0, "FloatTitle", { fg = border_color, default = true })
		-- Noice 相关边框（包括删除确认弹窗）
		vim.api.nvim_set_hl(0, "NoiceConfirmBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "NoicePopupBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = border_color, default = true })
		-- Snacks 相关边框
		vim.api.nvim_set_hl(0, "SnacksInputBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "SnacksWinBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = border_color, default = true })
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		local border_color = "#2b85b7"
		vim.api.nvim_set_hl(0, "FloatBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal" })
		vim.api.nvim_set_hl(0, "FloatTitle", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "NoiceConfirmBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "NoicePopupBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "SnacksInputBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "SnacksWinBorder", { fg = border_color, default = true })
		vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = border_color, default = true })
	end,
})

return {}
