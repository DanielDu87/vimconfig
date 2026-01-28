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

			-- 定义服务器列表
			local servers = {
				-- 1. ts_ls（tsserver）仅用于 JS
				ts_ls = { filetypes = { "javascript", "javascriptreact" } },
				-- 2. vtsls 用于 TypeScript/Vue
				vtsls = { filetypes = { "typescript", "typescriptreact", "vue" } },
				-- 3. pyright 用于 Python
				pyright = {
					positionEncoding = "utf-8",
					settings = {
						python = {
							analysis = {},
						},
					},
				},
				-- 4. html
				html = {},
				-- 5. 其他
				dockerls = {},
				bashls = {},
				marksman = {},
				emmet_ls = {
					filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "vue" },
				},
			}

			-- 循环调用 setup
			for name, config in pairs(servers) do
				if lspconfig[name] then
					lspconfig[name].setup(config)
				end
			end
		end,
	},
}
