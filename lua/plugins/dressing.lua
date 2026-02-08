--==============================================================================
-- dressing.nvim 配置
--==============================================================================
-- 增强 vim.ui.input 和 vim.ui.select 的 UI
-- 让输入框显示为漂亮的浮动窗口

return {
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {
			input = {
				-- 启用相对光标的浮动窗口
				relative = "cursor",
				-- 浮动窗口位置
				prefer_width = 40,
				width = nil,
				-- 最小/最大宽度
				min_width = 20,
				max_width = 60,
				-- 边框样式
				border = "rounded",
				-- 自动调整窗口大小以适应内容
				anchor = "SW",
				-- 窗口选项
				win_options = {
					winblend = 10, -- 透明度
					winhighlight = "NormalFloat:DiagnosticInfo,FloatBorder:DiagnosticInfo",
				},
				-- 输入框选项
				buf_options = {},
				-- 是否启用插入模式
				start_in_insert = true,
				-- 使用 telescope 作为后端（可选）
				-- backend = "telescope",
			},
			select = {
				-- 使用 telescope 作为后端（如果有）
				backend = { "telescope", "builtin" },
				-- 浮动窗口选项
				builtin = {
					relative = "cursor",
					width = nil,
					max_width = 80,
					min_width = 40,
					border = "rounded",
					win_options = {
						winblend = 10,
						winhighlight = "NormalFloat:DiagnosticInfo,FloatBorder:DiagnosticInfo",
					},
				},
			},
		},
	},
}
