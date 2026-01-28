--==============================================================================
-- Linter 配置 (nvim-lint)
--==============================================================================
-- 独立配置 nvim-lint，确保 ruff 等工具稳定运行

return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufWritePost", "BufReadPost", "InsertLeave" },
		config = function()
			local lint = require("lint")

			-- 配置 linters
			lint.linters_by_ft = {
				python = { "ruff" },
				markdown = { "markdownlint" },
				dockerfile = { "hadolint" },
				-- 可以根据需要添加更多
				-- javascript = { "eslint_d" },
				-- typescript = { "eslint_d" },
			}

			-- 自动触发 lint 的逻辑
			local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
