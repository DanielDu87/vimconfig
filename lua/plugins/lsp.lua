--==============================================================================
-- LSP 自动启动配置
--==============================================================================

-- TypeScript/JavaScript LSP 配置（使用 LazyVim 默认的 ts_ls，增强 inlay hints）
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.name == "ts_ls" then
			-- 启用 inlay hints
			if client.server_capabilities.inlayHintProvider then
				vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
			end
			-- 增强 inlay hints 显示（与之前 vtsls 配置一致）
			client.config.settings = vim.deepcopy(client.config.settings or {})
			client.config.settings.typescript = client.config.settings.typescript or {}
			client.config.settings.typescript.preferences = client.config.settings.typescript.preferences or {}
			client.config.settings.typescript.preferences.includeInlayParameterNameHints = "all"
			client.config.settings.typescript.preferences.includeInlayVariableTypeHints = true
			client.config.settings.javascript = client.config.settings.javascript or {}
			client.config.settings.javascript.preferences = client.config.settings.javascript.preferences or {}
			client.config.settings.javascript.preferences.includeInlayParameterNameHints = "all"
			-- 通知 LSP 更新设置
			client.notify("workspace/didChangeConfiguration", {
				settings = client.config.settings,
			})
		end
	end,
})

return {}
