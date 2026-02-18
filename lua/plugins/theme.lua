--==============================================================================
-- 主题配置 - Tokyo Night / Solarized 透明 + 自动保存主题选择
--==============================================================================
-- 根据 LazyVim 官方文档配置主题
-- https://lazyvim.github.io/plugins/colorscheme

-- 默认开启透明模式
vim.g.transparent_enabled = true

-- 主题保存路径
local theme_file = vim.fn.expand("~/Documents/neovim_files/colorscheme")

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
	-- ~/Documents 目录已存在，无需创建
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
				-- 强制应用全局透明补丁
				pcall(function()
					require("util.theme").apply_transparency()
				end)

				hl.PmenuSel = { bg = "#4e5a7e", bold = true } -- 补全菜单选中行（调亮并加粗）
				hl.BlinkCmpMenuSelection = { bg = "#4e5a7e", bold = true } -- blink.cmp 补全菜单选中项
				hl.Visual = { bg = "#515c7e" } -- 选中文本背景（更亮的蓝色/灰色）
				hl.CursorLine = { bg = "#363d59" } -- 编辑器光标行（调亮后的颜色）
				hl.Comment = { fg = "#7a7a7a", italic = true } -- 注释颜色（纯浅灰色）

				-- Copilot 虚文本补全颜色（更亮的灰色）
				hl.CopilotSuggestion = { fg = "#a9b1d6" }

				-- 强制清除 blink.cmp 标签的背景色，防止插件干扰
				hl.BlinkCmpLabel = { bg = "NONE" }
				hl.BlinkCmpLabelMatch = { bg = "NONE" }
				hl.BlinkCmpLabelDescription = { bg = "NONE" }

				-- 分割线颜色（WinSeparator 是 Nvim 0.10+ 的标准，VertSplit 是兼容旧版）
				hl.WinSeparator = { fg = "#565f89", bold = true }
				hl.VertSplit = { fg = "#565f89" }

				-- 诊断颜色 - 确保边缘符号和文字颜色一致（tiny-inline-diagnostic）
				-- 定义完整的诊断高亮组（包括 fg 和 sp）
				hl.DiagnosticError = { fg = "#f7768e", sp = "#f7768e" }
				hl.DiagnosticWarn = { fg = "#e0af68", sp = "#e0af68" }
				hl.DiagnosticInfo = { fg = "#7dcfff", sp = "#7dcfff" }
				hl.DiagnosticHint = { fg = "#9aa5ce", sp = "#9aa5ce" }

				-- Underline 风格（用于诊断下划线）
				hl.DiagnosticUnderlineError = { sp = "#f7768e", undercurl = true }
				hl.DiagnosticUnderlineWarn = { sp = "#e0af68", undercurl = true }
				hl.DiagnosticUnderlineInfo = { sp = "#7dcfff", undercurl = true }
				hl.DiagnosticUnderlineHint = { sp = "#9aa5ce", undercurl = true }

				-- Virtual text 风格（用于内联诊断）
				hl.DiagnosticVirtualTextError = { fg = "#f7768e", bg = "NONE" }
				hl.DiagnosticVirtualTextWarn = { fg = "#e0af68", bg = "NONE" }
				hl.DiagnosticVirtualTextInfo = { fg = "#7dcfff", bg = "NONE" }
				hl.DiagnosticVirtualTextHint = { fg = "#9aa5ce", bg = "NONE" }

				-- Sign 风格（用于符号列）
				hl.DiagnosticSignError = { fg = "#f7768e", bg = "NONE" }
				hl.DiagnosticSignWarn = { fg = "#e0af68", bg = "NONE" }
				hl.DiagnosticSignInfo = { fg = "#7dcfff", bg = "NONE" }
				hl.DiagnosticSignHint = { fg = "#9aa5ce", bg = "NONE" }
			end,
		},
	},

	-- Solarized 主题配置
	{
		"svrana/neosolarized.nvim",
		lazy = false,
		priority = 1000,
		dependencies = { "tjdevries/colorbuddy.nvim" },
		opts = {
			comment_italics = true,
			background_set = false, -- 透明背景
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
