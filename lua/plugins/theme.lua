--==============================================================================
-- 主题配置 - 启用透明背景
--==============================================================================

return {
	-- 配置 Tokyo Night 主题（LazyVim 默认主题）
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,           -- 启用透明背景
			transparent_sidebar = true,   -- 侧边栏透明
			transparent_floats = true,    -- 浮动窗口透明
			style = "night",              -- 风格: night, storm, day, moon
			styles = {
				comments = { italic = true },
				keywords = { italic = true },
				functions = {},
				variables = {},
				-- 背景透明
				sidebars = "transparent",
				floats = "transparent",
			},
		},
	},
}
