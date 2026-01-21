return {
	-- 1. 配置 tiny-inline-diagnostic 插件
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = { "LspAttach", "BufReadPre", "BufNewFile" },
		config = function()
			require("tiny-inline-diagnostic").setup({
				preset = "ghost",
				options = {
					show_source = false,
					throttle = 80, -- 降低更新频率，减少 redraw 压力
					softwrap = 60,
					multilines = true,
					overflow = {
						mode = "wrap",
					},
				},
			})
		end,
	},

	-- 2. 配置 LSP 诊断选项 (nvim-lspconfig)
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			-- 禁用默认的 virtual_text（因为使用了 tiny-inline-diagnostic）
			opts.diagnostics = opts.diagnostics or {}
			opts.diagnostics.virtual_text = false
			opts.diagnostics.signs = true -- 启用左侧指示图标
			
			-- 只对 Error 显示下划线（减少视觉干扰，保留关键定位提示）
			opts.diagnostics.underline = { severity = vim.diagnostic.severity.ERROR }
			opts.diagnostics.update_in_insert = false
			
			-- 浮窗配置：不抢焦点，支持换行
			opts.diagnostics.float = vim.tbl_deep_extend("force", opts.diagnostics.float or {}, {
				header = "",
				source = "if_many",
				border = "rounded",
				wrap = true,
				focusable = false,
				focus = false,
			})
			return opts
		end,
	},
}