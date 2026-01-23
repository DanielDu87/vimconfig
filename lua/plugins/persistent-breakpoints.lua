--==============================================================================
-- DAP断点持久化配置
--==============================================================================

return {
	{
		"Weissle/persistent-breakpoints.nvim",
		event = "BufReadPost",
		dependencies = {
			"mfussenegger/nvim-dap", -- 确保 nvim-dap 已经安装
		},
		config = function()
			require("persistent-breakpoints").setup({
				load_breakpoints_event = { "BufReadPost" }, -- 打开文件时自动加载
				save_dir = vim.fn.stdpath("data") .. "/breakpoints", -- 断点保存位置
				perf_record = false, -- 性能记录
				always_reload = true, -- 重新加载文件时总是加载断点 (兼容会话管理)
			})
		end,
	},
}
