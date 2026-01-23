--==============================================================================
-- 补全引擎配置 (blink.cmp)
--==============================================================================

return {
	{
		"saghen/blink.cmp",
		opts = {
			completion = {
				-- 文档提示窗口设置
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = {
						min_width = 15,
						max_width = 80,
						max_height = 20,
						border = "rounded",
						winblend = 0,
						scrollbar = false,
					},
				},
				-- 补全菜单设置
				menu = {
					min_width = 30,
					max_height = 10,
					border = "rounded",
					winblend = 0,
					scrollbar = false,
					-- 确保绘制顺序和方式不会覆盖透明背景
					draw = {
						columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
					},
				},
			},
			-- 函数参数签名提示 (Signature Help)
			signature = {
				enabled = true,
				window = {
					min_width = 30,
					max_width = 80,
					border = "rounded",
					winblend = 0,
					scrollbar = false,
				},
			},
		},
	},
}