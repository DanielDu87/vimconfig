return {
	-- 1) Neogit (保留默认即可，不再作为主提交工具)
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
		},
		opts = {
			integrations = {
				diffview = true,
			},
		},
	},

	-- 2) Fugitive: 状态面板 (主审核入口)
	{
		"tpope/vim-fugitive",
		cmd = { "G", "Git" },
		config = function()
			-- 为 Fugitive 状态面板添加规范化提交映射
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "fugitive",
				                callback = function()
				                    local buf = vim.api.nvim_get_current_buf()
				                    -- 把 c 和 cc 都映射到规范化提交
				                    vim.keymap.set("n", "c", "<cmd>ConventionalCommit<CR>", { buffer = true, desc = "规范化提交" })
				                    vim.keymap.set("n", "cc", "<cmd>ConventionalCommit<CR>", { buffer = true, desc = "规范化提交" })
				                    -- 添加 q 直接退出
				                    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, desc = "退出 Fugitive" })
				                    -- 添加 a 全部暂存
				                    vim.keymap.set("n", "a", function()
				                        vim.fn.system("git add -A")
				                        vim.cmd("edit") -- 刷新 Fugitive 面板以显示最新状态
				                        vim.notify("所有更改已全部暂存", vim.log.levels.INFO, { title = "Git" })
				                    end, { buffer = true, desc = "全部暂存 (git add -A)" })
				                    -- 修改回车键为展开/折叠差异
				                    vim.keymap.set("n", "<CR>", "=", { remap = true, buffer = true, desc = "展开/折叠差异" })
				
				                    -- 注入常驻提示
				                    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
				                    vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
				                        " 💡 [回车:差异] [a:全存] [s:暂存] [u:取消] [c:提交] [q:退出]",
				                        " -------------------------------------------------------------",
				                    })
				                    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
				                end,			})
		end,
	},

	-- 2) Diffview: 审查已暂存的更改
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		opts = {
			enhanced_diff_hl = true,
			use_icons = true,
		},
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git差异 (工作区)" },
			{ "<leader>gD", "<cmd>DiffviewOpen --cached<cr>", desc = "Git差异 (已暂存)" },
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "关闭差异视图" },
		},
	},

	-- 3) 强大的 Git 搜索增强
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

	-- 4) Fugitive (作为辅助工具)
	{
		"tpope/vim-fugitive",
		cmd = { "G", "Git" },
	},

	-- 5) Telescope 增强
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		opts = {
			extensions = {
				advanced_git_search = {
					diff_plugin = "diffview",
				},
			},
		},
	},
}