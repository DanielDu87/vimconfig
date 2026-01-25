--==============================================================================
-- LSP 自动启动配置
--==============================================================================

-- 公共 inlayHints 配置（用于 ts_ls 和 vtsls）
local ts_inlay_hints = {
	includeInlayParameterNameHints = "all",
	includeInlayParameterNameHintsWhenArgumentMatchesName = false,
	includeInlayFunctionParameterTypeHints = true,
	includeInlayVariableTypeHints = true,
	includeInlayPropertyDeclarationTypeHints = true,
	includeInlayFunctionLikeReturnTypeHints = true,
	includeInlayEnumMemberValueHints = true,
}

return {
	--==========================================================================
	-- 删除 LazyVim 默认的 LSP 重命名键位（被智能重构接管）
	--==========================================================================
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy",
		config = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimKeymaps",
				callback = function()
					-- 设置 Visual 模式的智能重构键位
					vim.keymap.set("x", "<leader>cr", function()
						require("util.refactor_smart").smart_visual_refactor()
					end, { desc = "智能重构操作", remap = false })
				end,
				once = true,
			})
		end,
	},

	--==========================================================================
	-- Linter 配置 (nvim-lint)
	--==========================================================================
	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			opts.linters_by_ft = opts.linters_by_ft or {}
			-- HTML 使用 markuplint，Python 使用 ruff（需在系统中安装 ruff）
			opts.linters_by_ft.html = { "markuplint" }
			opts.linters_by_ft.python = { "ruff" }
		end,
	},

	--==========================================================================
	-- Vtsls 辅助插件 (提供版本切换等 UI 命令)
	--==========================================================================
	{
		"yioneko/nvim-vtsls",
		lazy = true,
		config = false, -- 禁用默认的 setup 调用，该插件由 lspconfig 驱动
	},

	--==========================================================================
	-- LSP 服务详细配置
	--==========================================================================
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			-- 服务器配置
			opts.servers = opts.servers or {}

			-- =========================================================================
			-- TypeScript/JavaScript LSP 配置
			-- =========================================================================

			-- 1. ts_ls (tsserver) - 用于 JavaScript
			opts.servers.ts_ls = {
				enabled = true,
				filetypes = { "javascript", "javascriptreact" },
				settings = {
					javascript = {
						inlayHints = ts_inlay_hints,
					},
				},
			}

			-- 2. vtsls - 用于 TypeScript 和 Vue（支持工作区版本切换）
			opts.servers.vtsls = {
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
			}

			-- =========================================================================
			-- 其他 LSP 配置
			-- =========================================================================
			opts.servers.marksman = { enabled = true }
			opts.servers.emmet_ls = {
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
			}
			opts.servers.superhtml = { enabled = false }
			opts.servers.html = {
				enabled = true,
				settings = { html = { validate = { scripts = true, styles = true } } },
			}
			opts.servers.stylelint_lsp = {
				filetypes = { "css", "scss", "less", "sass" },
			}

			return opts
		end,
	},
}