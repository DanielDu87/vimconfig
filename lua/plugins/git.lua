return {
	-- 基础 Git 操作插件
	{
		"tpope/vim-fugitive",
		cmd = { "G", "Git" },
	},

	-- Neogit: Magit 风格的 Git 交互界面
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = true,
		opts = {
			disable_insert_on_commit = "auto",
			graph_style = "unicode",
			integrations = {
				diffview = true,
			},
		},
	},

	-- 强大的 Git 搜索增强
	{
		"aaronhallaert/advanced-git-search.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
			"tpope/vim-fugitive",
			"sindrets/diffview.nvim",
		},
		config = function()
			require("telescope").load_extension("advanced_git_search")
		end,
	},

	-- 差异查看器 (advanced-git-search 的推荐依赖)
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		opts = {
			enhanced_diff_hl = true,
		},
	},

	-- Telescope (虽然主 Picker 是 Snacks，但该插件依赖 Telescope)
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		opts = {
			extensions = {
				advanced_git_search = {
					-- 使用 fugitive 打开差异
					diff_plugin = "diffview",
				},
			},
		},
	},
}