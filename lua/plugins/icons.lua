--==============================================================================
-- mini.icons 图标配置
--==============================================================================
-- 为特定文件名自定义图标（覆盖默认图标）
-- 解决某些 Nerd Font 字体中特定图标字符不显示的问题

return {
	{
		"nvim-mini/mini.icons",
		opts = function()
			return {
				-- 为特定文件名覆盖图标
				file = {
					-- init.lua: 使用 Lua 图标（与 .lua 扩展名一致）
					["init.lua"] = { glyph = "󰢱", hl = "MiniIconsAzure" },
					-- stylua.toml: 使用 JSON 配置图标（更通用）
					["stylua.toml"] = { glyph = "󰘦", hl = "MiniIconsYellow" },
					[".stylua.toml"] = { glyph = "󰘦", hl = "MiniIconsYellow" },
				},
			}
		end,
	},
}
