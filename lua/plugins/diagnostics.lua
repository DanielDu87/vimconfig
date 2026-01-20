return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			-- 禁用默认显示
			opts.diagnostics = opts.diagnostics or {}
			opts.diagnostics.virtual_text = false
			opts.diagnostics.signs = true -- 启用 signs
			-- 只对 Error 显示下划线（保留关键定位提示）
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
