--==============================================================================
-- 主题配置 - Tokyo Night 透明 + 自动保存主题选择
--==============================================================================
-- 根据 LazyVim 官方文档配置主题
-- https://lazyvim.github.io/plugins/colorscheme

-- 默认开启透明模式
vim.g.transparent_enabled = true

-- 主题保存路径
local theme_file = vim.fn.stdpath("state") .. "/colorscheme"

-- 读取保存的主题
local function load_saved_theme()
	local f = io.open(theme_file, "r")
	if f then
		local theme = f:read("*a"):gsub("%s+", "")
		f:close()
		return theme ~= "" and theme or nil
	end
	return nil
end

-- 保存当前主题
local function save_theme(theme)
	vim.fn.mkdir(vim.fn.stdpath("state"), "p")
	local f = io.open(theme_file, "w")
	if f then
		f:write(theme)
		f:close()
	end
end

-- 默认主题
local default_theme = "tokyonight"

-- 读取保存的主题或使用默认
local saved_theme = load_saved_theme() or default_theme

-- 主题切换时自动保存的自动命令
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		local theme = vim.g.colors_name
		if theme then
			save_theme(theme)
		end
	end,
})

return {
	-- 配置 Tokyo Night 主题（启用透明背景和自定义高亮）
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true, -- 启用透明背景
			transparent_sidebar = true, -- 侧边栏透明
			transparent_floats = true, -- 浮动窗口透明
			style = "night", -- 风格: night, storm, day, moon
			styles = {
				comments = { italic = true },
				keywords = { italic = true },
				functions = {},
				variables = {},
				-- 背景透明
				sidebars = "transparent",
				floats = "transparent",
			},
			-- 自定义高亮 - 仅保留编辑器内部特定颜色覆盖
			on_highlights = function(hl, _) 
				hl.Visual = { bg = "#515c7e" } -- 选中文本背景（更亮的蓝色/灰色）
				hl.CursorLine = { bg = "#363d59" } -- 编辑器光标行（调亮后的颜色）
				hl.Comment = { fg = "#7a7a7a", italic = true } -- 注释颜色（纯浅灰色）
			end,
		},
	},

	-- 配置 LazyVim 默认颜色方案（支持持久化）
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = saved_theme,
		},
	},
}
