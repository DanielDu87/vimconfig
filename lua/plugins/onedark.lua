--==============================================================================
-- OneDark 主题配置 (完整版)
--==============================================================================

return {
	{
		"navarasu/onedark.nvim",
		main = "onedark", -- 显式指定模块名，防止 lazy.nvim 报错
		lazy = false,
		priority = 1000,
		opts = {
			-- 主题风格: dark, darker, cool, deep, warm, abyss
			style = "darker",
			transparent = true, -- 启用透明
			term_colors = true, -- 终端颜色支持
			ending_tildes = false, -- 显示文件末尾的 ~
			cmp_itemkind_reverse = false, -- 翻转补全图标颜色

			-- 扩展代码样式 (全面开启)
			code_style = {
				comments = "italic",
				keywords = "italic",
				functions = "bold",
				strings = "none",
				variables = "none",
			},

			-- 插件支持适配 (全面开启)
			plugin_list = {
				ts_rainbow = true,
				compound_keywords = true,
				["nvim-tree"] = true,
				["bufferline"] = true,
				["telescope"] = true,
				["which-key"] = true,
				["indentline"] = true,
				["dashboard"] = true,
				["neogit"] = true,
				["todo-comments"] = true,
			},

			-- 诊断信息样式
			diagnostics = {
				darker = true, -- 诊断背景更柔和
				undercurls = true, -- 错误使用下波浪线
				background = true, -- 开启背景色
			},
		},
	},
}