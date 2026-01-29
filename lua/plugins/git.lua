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
				                    										
				                    										-- 回车恢复为 Fugitive 原生的展开/折叠差异
				                    										vim.keymap.set("n", "<CR>", "=", { remap = true, buffer = true, desc = "展开/折叠差异" })
				                    										
				                    															-- d 映射为打开全屏 Diffview
				                    															vim.keymap.set("n", "d", "<cmd>DiffviewOpen<CR>", { buffer = true, desc = "打开全屏 Diffview" })
				                    										
				                    															-- 注入常驻提示
				                    															vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
				                    															vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
				                    																" 💡 [回车:展开] [d:全屏Diff] [a:全存] [s:暂存] [u:取消] [c:提交] [q:退出]",
				                    																" ----------------------------------------------------------------------",
				                    															})				                    										vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
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
			keymaps = {
				file_panel = {
					{ "n", "c", "<cmd>ConventionalCommit<CR>", { desc = "启动规范化提交" } },
					{ "n", "s", "s", { desc = "暂存文件" } },
					{ "n", "u", "u", { desc = "取消暂存" } },
					-- 修改 q 为关闭后返回 Fugitive 面板
					{ "n", "q", function()
						vim.cmd("DiffviewClose")
						-- 延迟一瞬确保布局清理完成，然后模拟按 leader-gc
						vim.schedule(function()
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>gc", true, true, true), "m", true)
						end)
					end, { desc = "关闭并返回面板" } },
				},
				view = {
					{ "n", "c", "<cmd>ConventionalCommit<CR>", { desc = "启动规范化提交" } },
					-- 同步修改 view 中的 q
					{ "n", "q", function()
						vim.cmd("DiffviewClose")
						vim.schedule(function()
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>gc", true, true, true), "m", true)
						end)
					end, { desc = "关闭并返回面板" } },
				},
			},
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