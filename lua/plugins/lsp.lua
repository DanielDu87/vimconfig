--==============================================================================
-- LSP 自动启动配置
--==============================================================================

return {
	--==========================================================================
	-- TypeScript 增强插件
	--==========================================================================
	{
		"jose-elias-alvarez/typescript.nvim",
		opts = {
			server = {
				settings = {
					-- 在这里可以放针对 tsserver 的特定设置
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayVariableTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
						},
					},
				},
			},
		},
	},

	--==========================================================================
	-- LSP 服务详细配置
	--==========================================================================
	{
		"neovim/nvim-lspconfig",
		opts = {
			-- 确保启用自动安装
			servers = {
				-- 1. 禁用 vtsls (防止它抢占 typescript 的控制权)
				vtsls = { enabled = false },

				-- 2. 配置 ts_ls (原 tsserver)
				ts_ls = {
					enabled = true,
					settings = {
						typescript = {
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
						javascript = {
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
					},
				},
				-- 3. 配置 marksman
				marksman = {
					enabled = true,
				},
			},
		},
	},
}
