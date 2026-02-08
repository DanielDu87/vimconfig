--==============================================================================
-- Noice.nvim 布局优化：通过自定义 View 分离 Hover 和 Signature
--==============================================================================

return {
	"folke/noice.nvim",
	opts = function(_, opts)
		opts = opts or {}
		opts.views = opts.views or {}

		-- hover：强制显示在光标上方，避免遮挡下方的补全菜单
		opts.views.hover_up = {
			backend = "popup",
			relative = "cursor",
			position = { row = -3, col = 0 }, -- 向上偏离 3 行，留出空间
			size = { width = 60, height = "auto", max_width = 60 },
			border = { style = "rounded" },
			win_options = { winhighlight = { Normal = "NoicePopup", FloatBorder = "NoicePopupBorder" } },
		}

		-- signature：强制显示在光标下方
		opts.views.signature_down = {
			backend = "popup",
			relative = "cursor",
			position = { row = 2, col = 0 }, -- 向下偏离 2 行
			size = { width = 60, height = "auto", max_width = 60 },
			border = { style = "rounded" },
			win_options = { winhighlight = { Normal = "NoicePopup", FloatBorder = "NoicePopupBorder" } },
		}

		opts.lsp = opts.lsp or {}
		-- 关联 LSP Hover 到上方视图
		opts.lsp.hover = vim.tbl_deep_extend("force", opts.lsp.hover or {}, {
			enabled = true,
			view = "hover_up",
		})
		-- 关联 LSP Signature 到下方视图
		opts.lsp.signature = vim.tbl_deep_extend("force", opts.lsp.signature or {}, {
			enabled = true,
			view = "signature_down",
		})

		return opts
	end,
}
