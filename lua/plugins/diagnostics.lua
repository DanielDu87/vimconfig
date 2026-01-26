return {
	-- 1. 配置 tiny-inline-diagnostic 插件（多行换行显示）
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = { "LspAttach", "BufReadPre", "BufNewFile" },
		config = function()
			require("tiny-inline-diagnostic").setup({
				preset = "ghost",
				options = {
					show_source = false,
					throttle = 0, -- 插入模式下建议设为 0，避免延迟
					softwrap = 60,
					multilines = {
						enabled = true,
					},
					overflow = {
						mode = "wrap",
					},
					-- 监听诊断变化事件（包括nvim-lint产生的诊断）
					overwrite_events = { "LspAttach", "DiagnosticChanged", "BufEnter" },
					-- 插入模式下也显示诊断
					enable_on_insert = true,
				},
			})
		end,
	},

	-- 2. 配置 LSP 诊断选项和重构键位（nvim-lspconfig）
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy",
		opts = function(_, opts)
			-- 禁用默认显示
			opts.diagnostics = opts.diagnostics or {}
			opts.diagnostics.virtual_text = false
			opts.diagnostics.signs = true -- 启用 signs

			-- 对所有级别显示下划线
			opts.diagnostics.underline = true
			opts.diagnostics.update_in_insert = true -- 允许插入模式更新诊断
			opts.diagnostics.severity_sort = true

			-- 浮窗配置：不抢焦点，支持换行
			opts.diagnostics.float = vim.tbl_deep_extend("force", opts.diagnostics.float or {}, {
				header = "",
				source = "if_many",
				border = "rounded",
				wrap = true,
				focusable = false,
				focus = false,
			})

			-- LSP 服务器配置
			opts.servers = opts.servers or {}

			-- 1. ts_ls（tsserver）仅用于 JS
			opts.servers.ts_ls = {
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
			}

			-- 2. vtsls 用于 TypeScript
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

			-- 3. 其他 LSP
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
			opts.servers.css_variables = { enabled = false }

			return opts
		end,
		config = function()
			-- 设置 Visual 模式的智能重构键位
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimKeymaps",
				callback = function()
					vim.keymap.set("x", "<leader>cr", function()
						require("util.refactor_smart").smart_visual_refactor()
					end, { desc = "智能重构操作", remap = false })
				end,
				once = true,
			})
		end,
	},

	-- 3. 配置光标悬停自动显示诊断浮窗
	{
		"neovim/nvim-lspconfig",
		event = "LspAttach",
		callback = function(args)
			-- 光标停留时自动显示诊断浮窗
			vim.api.nvim_create_autocmd("CursorHold", {
				buffer = args.buf,
				callback = function()
					local opts = {
						focus = false,
						close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
						border = "rounded",
						source = "if_many",
						header = "",
						wrap = true,
					}
					local diagnostics = vim.diagnostic.get(args.buf, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
					if #diagnostics > 0 then
						vim.diagnostic.open_float(nil, opts)
					end
				end,
			})
		end,
	},
}
