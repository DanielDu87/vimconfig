return {
	--==========================================================================
	-- LSP 服务器统一配置 (nvim-lspconfig)
	--==========================================================================
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "yioneko/nvim-vtsls" },
		},
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
					-- 恢复为标准支持，包括 htmldjango
					filetypes = { "html", "htmldjango" },
					settings = {
						html = {
							validate = { scripts = true, styles = true },
						},
					},
				},
				-- 5. Django 模板 (djlsp)
				-- 此服务器在 htmldjango 上与 html 共存
				djlsp = {
					filetypes = { "htmldjango" },
				},
				-- 6. JSON
				jsonls = {
					settings = { json = { validate = { enable = true } } },
				},
				-- 7. Docker
				dockerls = {
					root_dir = lspconfig.util.root_pattern("Dockerfile", "docker-compose.yml", "docker-compose.yaml", ".git"),
				},
				-- 8. 其他
				bashls = {},
				marksman = {},
				emmet_ls = {
					-- Emmet 应该作为一个辅助，支持尽可能多的 Web 文件
					filetypes = { "html", "htmldjango", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "vue" },
				},
			}

			-- 循环调用 setup
			for name, config in pairs(servers) do
				if lspconfig[name] then
					config.on_attach = on_attach
					lspconfig[name].setup(config)

					-- 如果是 vtsls，且 nvim-vtsls 插件已加载，则进行额外的 setup
					if name == "vtsls" then
						local ok, nvim_vtsls = pcall(require, "nvim-vtsls")
						if ok then
							nvim_vtsls.setup({
								on_attach = config.on_attach, -- 传递 lspconfig 的 on_attach
								-- 这里可以添加 nvim-vtsls 的其他配置
							})
						end
					end
				end
			end
		end,
	},
}