--==============================================================================
-- Mason 配置
--==============================================================================
-- Mason 是 LSP 服务器、DAP 调试器、Linter 和格式化工具的管理器
-- 注意：LazyVim extras 已自动配置大部分工具，此处只补充额外需要的

return {
	-- Mason 核心插件
	{
		"mason-org/mason.nvim",
		opts = {
			-- 只补充 LazyVim extras 未包含的工具
			ensure_installed = {
				-- 代码质量工具
				"typos",      -- 拼写检查
			},
		},
	},

	-- Mason 与 nvim-lspconfig 的集成（LazyVim 自动管理）
	{
		"mason-org/mason-lspconfig.nvim",
	},

	-- Mason 与 nvim-dap 的集成（调试器）
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		opts = {
			-- 自动安装调试器
			ensure_installed = {
				"python",  -- Python 调试器
			},
			-- 自动配置
			automatic_setup = true,
		},
	},
}
