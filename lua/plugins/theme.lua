--==============================================================================
-- 主题配置 - Tokyo Night 透明 + 自动保存主题选择
--==============================================================================
-- 根据 LazyVim 官方文档配置主题
-- https://lazyvim.github.io/plugins/colorscheme

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
			-- 自定义高亮 - 统一管理所有界面颜色覆盖
			on_highlights = function(hl, c)
				-- 1. 编辑器基础颜色覆盖
				hl.CursorLine = { bg = "#3d4458" } -- 编辑器光标行（更暗的灰色）
				hl.Comment = { fg = "#7a7a7a", italic = true } -- 注释颜色（纯浅灰色）

				-- 2. 透明背景强制覆盖 (WinBar)
				hl.WinBar = { bg = c.none, fg = c.fg } -- WinBar 透明
				hl.WinBarNC = { bg = c.none, fg = c.dark3 } -- WinbarNC 透明

				-- 3. 浮动窗口边框颜色 (统一蓝色风格)
				local border_color = "#2b85b7"

				-- 通用浮窗
				hl.FloatBorder = { fg = border_color }
				hl.FloatTitle = { fg = border_color }
				hl.NormalFloat = { link = "Normal" } -- 浮窗背景跟随 Normal（透明）

				-- Noice 弹窗
				hl.NoiceConfirmBorder = { fg = border_color }
				hl.NoicePopupBorder = { fg = border_color }
				hl.NoiceCmdlinePopupBorder = { fg = border_color }

				-- Snacks 组件
				hl.SnacksInputBorder = { fg = border_color }
				hl.SnacksWinBorder = { fg = border_color }
				hl.SnacksPickerBorder = { fg = border_color }
				hl.SnacksPickerListCursorLine = { link = "CursorLine" } -- Picker 光标行

				-- 4. 补全窗口 (BlinkCmp) 样式
				hl.BlinkCmpMenu = { bg = c.none }
				hl.BlinkCmpMenuBorder = { fg = border_color, bg = c.none }
				hl.BlinkCmpDoc = { bg = c.none }
				hl.BlinkCmpDocBorder = { fg = border_color, bg = c.none }
				hl.BlinkCmpDocCursorLine = { bg = "#3d4458" }
				hl.BlinkCmpSignatureHelp = { bg = c.none }
				hl.BlinkCmpSignatureHelpBorder = { fg = border_color, bg = c.none }
				hl.BlinkCmpSignatureHelpActiveParameter = { fg = "#7dcfff", bold = true }

				-- 彻底清除列表项内部所有组件的背景
				hl.BlinkCmpLabel = { bg = c.none }
				hl.BlinkCmpLabelMatch = { fg = "#7dcfff", bg = c.none, bold = true }
				hl.BlinkCmpLabelDetail = { fg = "#565f89", bg = c.none }
				hl.BlinkCmpLabelDescription = { fg = "#565f89", bg = c.none }
				hl.BlinkCmpKind = { bg = c.none }
				hl.BlinkCmpKindIcon = { bg = c.none }
				hl.BlinkCmpSource = { bg = c.none }
				hl.BlinkCmpGhostText = { fg = "#565f89", bg = c.none }

				-- 也要清理通用的 Pmenu，因为 blink 可能会继承它
				hl.Pmenu = { bg = c.none }
				hl.PmenuSel = { bg = "#3d4458" }
				hl.PmenuSbar = { bg = c.none }
				hl.PmenuThumb = { bg = "#3d4458" }

				-- 5. 强制所有背景透明 (覆盖可能漏掉的组件)
				hl.Normal = { bg = "none" }
				hl.NormalNC = { bg = "none" }
				hl.NonText = { bg = "none" }
				hl.EndOfBuffer = { bg = "none" }
				hl.Folded = { bg = "none" }
				hl.SignColumn = { bg = "none" }
				hl.StatusLine = { bg = "none" }
				hl.StatusLineNC = { bg = "none" }
				hl.VertSplit = { bg = "none" }
				hl.TabLine = { bg = "none" }
				hl.TabLineFill = { bg = "none" }
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
