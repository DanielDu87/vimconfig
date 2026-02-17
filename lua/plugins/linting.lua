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

			-- 强力配置 djlint：匹配真实输出格式 CODE LINE:COL MESSAGE
			lint.linters.djlint = {
				cmd = vim.fn.stdpath("data") .. "/mason/bin/djlint",
				args = {
					"--lint",
					"--profile=django",
					"--quiet",
					"-",
				},
				stdin = true,
				stream = "stdout",
				ignore_exitcode = true,
				parser = function(output, bufnr)
					local diagnostics = {}
					-- 匹配格式：T003 4:37 Endblock should have name...
					for line in output:gmatch("[^\r\n]+") do
						local code, row, col, msg = line:match("([%w-]+)%s+(%d+):(%d+)%s+(.*)")
						if row and msg then
							table.insert(diagnostics, {
								source = "djlint",
								lnum = tonumber(row) - 1,
								col = tonumber(col),
								severity = vim.diagnostic.severity.ERROR,
								message = "[" .. code .. "] " .. msg,
							})
						end
					end
					return diagnostics
				end,
			}

			-- 配置 markdownlint-cli2 可执行文件路径和解析器
			lint.linters.markdownlint_cli2 = {
				cmd = vim.fn.stdpath("data") .. "/mason/bin/markdownlint-cli2",
				args = {},
				stdin = true,
				stream = "stdout",
				ignore_exitcode = true,
				parser = function(output, bufnr)
					local diagnostics = {}
					-- markdownlint-cli2 输出格式: filename:line:col: rule message [rule-id]
					for line in output:gmatch("[^\r\n]+") do
						local file, row, col, message, rule = line:match("^(.+):(%d+):(%d+): (.+) %[(.+)%]$")
						if row and message then
							table.insert(diagnostics, {
								lnum = tonumber(row) - 1,
								col = tonumber(col) - 1,
								end_lnum = tonumber(row) - 1,
								end_col = tonumber(col),
								severity = vim.diagnostic.severity.WARN,
								message = message,
								source = "markdownlint",
								code = rule,
							})
						end
					end
					return diagnostics
				end,
			}

			-- 配置 linters
			lint.linters_by_ft = {
				python = { "ruff" },
				markdown = { "markdownlint_cli2" },
				dockerfile = { "hadolint" },
				htmldjango = { "djlint" },
				html = { "htmlhint" },
			}

			-- 实时触发 lint 的逻辑 (增强版)
			local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave", "TextChanged" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
