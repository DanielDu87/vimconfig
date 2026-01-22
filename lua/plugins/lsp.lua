--==============================================================================
-- LSP 自动启动配置
--==============================================================================

return {
	--==========================================================================
	-- Linter 配置 (nvim-lint)
	--==========================================================================
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				html = { "markuplint" },
			},
		},
	},

	--==========================================================================
	-- TypeScript 增强插件
	--==========================================================================
	{
		"jose-elias-alvarez/typescript.nvim",
		opts = {
			server = {
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

				-- 3. 配置 marksman (Markdown 支持)
				marksman = {
					enabled = true,
				},

				-- 4. 配置 emmet_ls (HTML/JSX 极速展开)
				emmet_ls = {
					enabled = true,
					flags = {
						debounce_text_changes = 150,
					},
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

				-- 5. 禁用有 Bug 的 superhtml (它会产生错误的 self-close 报错)
				superhtml = { enabled = false },

												-- 6. 确保标准 html-lsp 开启 (VSCode 同款，稳定无误报)

												html = {

													enabled = true,

													settings = {

														html = {

															validate = { scripts = true, styles = true },

														},

													},

												},

								

				

								-- 7. 限制 stylelint_lsp 的范围，防止它扫描 HTML 导致 CssSyntaxError

								stylelint_lsp = {

									filetypes = { "css", "scss", "less", "sass" },

								},

							},

						},

					},

				}

				