return {
	--==========================================================================
	-- LSP 服务器统一配置 (nvim-lspconfig)
	--==========================================================================
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy",
		config = function()
			-- 阻止 lspconfig 自动为所有文件类型设置服务器
			vim.g.lsp_config_no_auto_setup = true

			local lspconfig = require("lspconfig")

			-- 通用 on_attach 函数，用于启用 inlay hints
			local on_attach = function(client, bufnr)
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end
			end

			-- 定义服务器列表
			local servers = {
				-- 1. JavaScript (ts_ls)
				ts_ls = {
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
				-- 2. TypeScript/Vue (vtsls)
				vtsls = {
					filetypes = { "typescript", "typescriptreact", "vue" },
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
						vtsls = { autoUseWorkspaceTsdk = true },
					},
				},
				-- 3. Python (pyright)
				pyright = {
					positionEncoding = "utf-8",
					settings = { python = { analysis = {} } },
				},
				-- 4. HTML
				html = {
					filetypes = { "html" }, -- 仅处理标准 HTML
				},
				-- 5. Django 模板 (djlsp)
				-- 专门处理 htmldjango，提供精准报错
				djlsp = {
					filetypes = { "htmldjango" },
				},
				-- 6. Docker
				dockerls = {
					root_dir = lspconfig.util.root_pattern("Dockerfile", "docker-compose.yml", "docker-compose.yaml", ".git"),
				},
				-- 7. 其他
				bashls = {},
				marksman = {},
				emmet_ls = {
					filetypes = { "html", "htmldjango", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "vue" },
				},
			}

			-- 循环调用 setup
			for name, config in pairs(servers) do
				if lspconfig[name] then
					config.on_attach = on_attach
					lspconfig[name].setup(config)
				end
			end
		end,
	},
}