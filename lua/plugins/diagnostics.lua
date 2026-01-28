return {
	-- 1. 配置 tiny-inline-diagnostic 插件（多行换行显示）
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy", -- 改为 VeryLazy 确保稳定加载
		priority = 1000, -- 提高优先级
		config = function()
			-- 必须在这里强制禁用原生虚拟文字，防止冲突
			vim.diagnostic.config({ virtual_text = false })

			require("tiny-inline-diagnostic").setup({
				preset = "ghost",
				options = {
					show_source = false,
					throttle = 0,
					softwrap = 60,
					multilines = { enabled = true },
					overflow = { mode = "wrap" },
					-- 增加更多的监听事件，确保万无一失
					overwrite_events = { "LspAttach", "DiagnosticChanged", "BufEnter", "BufWritePost" },
					enable_on_insert = true,
				},
			})
		end,
	},

	-- 2. 配置 LSP 诊断选项和重构键位（nvim-lspconfig）
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy",
		config = function()
			-- -----------------------------------------------------------------------
			-- 全局诊断配置：这是确保 tiny-inline-diagnostic 正常工作的关键
			-- -----------------------------------------------------------------------
			vim.diagnostic.config({
				virtual_text = false, -- 禁用原生虚拟文字，由 tiny-inline 接管
				signs = true,
				underline = true,
				update_in_insert = true,
				severity_sort = true,
				float = {
					header = "",
					source = "if_many",
					border = "rounded",
					focusable = false,
					focus = false,
				},
			})

			-- 设置 Visual 模式的智能重构键位
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimKeymaps",
				callback = function()
					vim.keymap.set("x", "<leader>cr", function()
						require("util.refactor_smart").smart_visual_refactor()
					end, { desc = "智能重构操作", remap = false })
				end,
				once = true,
			})
		end,
	},

	-- 3. 配置光标悬停自动显示诊断浮窗
	{
		"neovim/nvim-lspconfig",
		event = "LspAttach",
		callback = function(args)
			-- 光标停留时自动显示诊断浮窗
			vim.api.nvim_create_autocmd("CursorHold", {
				buffer = args.buf,
				callback = function()
					local opts = {
						focus = false,
						close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
						border = "rounded",
						source = "if_many",
						header = "",
						wrap = true,
					}
					local diagnostics = vim.diagnostic.get(args.buf, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
					if #diagnostics > 0 then
						vim.diagnostic.open_float(nil, opts)
					end
				end,
			})
		end,
	},
}
