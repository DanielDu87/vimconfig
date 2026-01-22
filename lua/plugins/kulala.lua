--==============================================================================
-- HTTP 客户端配置 (Kulala)
--==============================================================================
-- 作用：在 Neovim 中直接发送 HTTP 请求，完美替代 Postman
-- 快捷键：
--   <leader>R : 发送当前位置的请求
--   [ / ] : 在请求历史中跳转

return {
	{
		"mistweaverco/kulala.nvim",
		ft = { "http", "rest" },
		keys = {
			{ "<leader>R", "<cmd>lua require('kulala').run()<cr>", desc = "发送 HTTP 请求" },
			{ "<leader>Ri", "<cmd>lua require('kulala').inspect()<cr>", desc = "检查请求详情" },
			{ "<leader>Rp", "<cmd>lua require('kulala').scratchpad()<cr>", desc = "打开 HTTP 演练场" },
		},
		opts = {
			-- 响应窗口设置
			winblend = 10,
			formatters = {
				json = "jq", -- 如果系统有 jq，自动美化 JSON 响应
				html = "prettier",
			},
		},
	},
}
