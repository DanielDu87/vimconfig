--==============================================================================
-- ESLint 配置
--==============================================================================

return {
	-- eslint-lsp 配置（与 LazyVim extras 保持一致）
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
				settings = {
					-- 帮助 eslint 在子文件夹中找到配置
					workingDirectories = { mode = "auto" },
					-- 确保显示所有严重级别
					quiet = false,
					-- 代码操作
					codeAction = {
						disableRuleComment = { enable = true, location = "separateLine" },
						showDocumentation = { enable = true },
					},
					codeActionOnSave = {
						enable = true,
						mode = "all",
					},
					-- 验证选项
					validate = "on", -- 总是验证
				},
				-- 确保在相关文件类型中启用
				filetypes = {
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
					"vue",
					"astro",
				},
			})
			return opts
		end,
	},
}
