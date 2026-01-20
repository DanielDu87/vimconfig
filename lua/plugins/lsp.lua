--==============================================================================
-- LSP 自动启动配置
--==============================================================================

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	callback = function(ev)
		vim.schedule(function()
			local bufnr = ev.buf
			local fname = vim.api.nvim_buf_get_name(bufnr)

			-- 检查是否已经启动 vtsls
			for _, client in ipairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
				if client.name == "vtsls" then
					return -- 已启动
				end
			end

			-- 获取 root 目录
			local root_dir = require("lspconfig.util").root_pattern("tsconfig.json", "package.json", "jsconfig.json")(fname)
				or require("lspconfig.util").find_git_ancestor(fname)
				or vim.fn.getcwd()

			-- 启动 vtsls（TypeScript/JavaScript LSP）
			pcall(vim.lsp.start, {
				name = "vtsls",
				cmd = { "vtsls", "--stdio" },
				root_dir = root_dir,
				bufnr = bufnr,
				settings = {
					typescript = {
						preferences = {
							includeInlayParameterNameHints = "all",
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
						},
						suggest = {
							completeFunctionCalls = true,
						},
					},
					vtsls = {
						enableMoveToFileCodeAction = true,
						autoUseWorkspaceTsdk = true,
					},
					javascript = {
						preferences = {
							includeInlayParameterNameHints = "all",
						},
					},
				},
			})
		end)
	end,
})

-- 使用 nvim-lint 运行 eslint（用于检查未使用变量等）
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	callback = function()
		-- 延迟执行，等待 LSP 启动
		vim.defer_fn(function()
			local lint = require("lint")
			-- 配置 eslint linter
			lint.linters_by_ft = lint.linters_by_ft or {}
			lint.linters_by_ft.javascript = { "eslint" }
			lint.linters_by_ft.typescript = { "eslint" }
			lint.linters_by_ft.javascriptreact = { "eslint" }
			lint.linters_by_ft.typescriptreact = { "eslint" }
			-- 运行 lint（不传参数，使用当前缓冲区）
			lint.try_lint()
		end, 1000)
	end,
})

return {}
