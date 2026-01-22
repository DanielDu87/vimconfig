--==============================================================================
-- 数据库管理配置 (Dadbod)
--==============================================================================
-- 1. vim-dadbod: 核心引擎
-- 2. vim-dadbod-ui: 可视化侧边栏 (快捷键: <leader>D)
-- 3. vim-dadbod-completion: SQL 补全增强

return {
	{
		"tpope/vim-dadbod",
		lazy = true,
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		init = function()
			-- 数据库 UI 设置
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_help = 0
			vim.g.db_ui_win_width = 35
		end,
		keys = {
			{ "<leader>D", "<cmd>DBUIToggle<cr>", desc = "数据库管理器" },
		},
	},
}
