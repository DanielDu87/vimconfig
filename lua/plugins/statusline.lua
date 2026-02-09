--==============================================================================
-- 状态栏配置：确保状态栏始终在窗口底部
--==============================================================================
return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			-- 确保 lualine 使用全局状态栏
			opts.globalstatus = true
			return opts
		end,
	},
}
