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
					-- 显式指定全局路径作为备选，解决 "Unable to find ESLint library" 错误
					nodePath = "/opt/homebrew/lib/node_modules",
					-- 显式设置工作目录，解决 "Could not find config file" 错误
					workingDirectories = { { mode = "auto" }, { directory = vim.fn.getcwd(), changeProcessCWD = true } },
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
