--==============================================================================
-- LSP 自动启动配置
--==============================================================================

return {
	--==========================================================================
	-- Linter 配置 (nvim-lint)
	--==========================================================================
	{
		"mfussenegger/nvim-lint",
		event = { "BufWritePre", "BufReadPost" },
		config = function()
			local lint = require("lint")

			-- 配置linters
			lint.linters_by_ft = lint.linters_by_ft or {}
			lint.linters_by_ft.html = { "markuplint" }

			-- 自动触发lint
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				pattern = { "*.html", "*.htm" },
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},

	--==========================================================================
	-- Vtsls 辅助插件 (提供版本切换等 UI 命令)
	--==========================================================================
	{
		"yioneko/nvim-vtsls",
		ft = { "typescript", "typescriptreact", "vue" },
		config = function()
			-- 该插件由 lspconfig 驱动，此处仅确保其加载
		end,
	},

	--==========================================================================
	-- TypeScript 增强插件 (完全还原您之前的 JS 配置)
	--==========================================================================
	{
		"jose-elias-alvarez/typescript.nvim",
		opts = {
			server = {
				filetypes = { "javascript", "javascriptreact" },
				settings = {
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
			servers = {
				-- 1. 还原之前的 ts_ls (tsserver) 设置，仅用于 JS
				ts_ls = {
					enabled = true,
					filetypes = { "javascript", "javascriptreact" },
					settings = {
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

				-- 2. 针对 TypeScript 环境切换到 vtsls
				vtsls = {
					enabled = true,
					filetypes = { "typescript", "typescriptreact", "vue" },
					keys = {
						{
							"<leader>co",
							function()
								require("vtsls").commands.organize_imports()
							end,
							desc = "整理导入",
						},
						{
							"<leader>cu",
							function()
								require("vtsls").commands.remove_unused_imports()
							end,
							desc = "删除未使用的导入",
						},
					},
					settings = {
						typescript = {
							inlayHints = {
								parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = false },
								parameterTypes = { enabled = true },
								variableTypes = { enabled = true },
								propertyDeclarationTypes = { enabled = true },
								functionLikeReturnTypes = { enabled = true },
								enumMemberValues = { enabled = true },
							},
						},
						vtsls = {
							autoUseWorkspaceTsdk = true,
						},
					},
				},

				-- 3. 其他 LSP 保持不变
				marksman = { enabled = true },
				emmet_ls = {
					enabled = true,
					flags = { debounce_text_changes = 150 },
					filetypes = {
						"html",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
						"vue",
					},
				},
				superhtml = { enabled = false },
				html = {
					enabled = true,
					settings = { html = { validate = { scripts = true, styles = true } } },
				},
				stylelint_lsp = {
					filetypes = { "css", "scss", "less", "sass" },
				},
				css_variables = { enabled = false },
			},
		},
	},
}
