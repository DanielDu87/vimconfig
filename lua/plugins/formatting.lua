--==============================================================================
-- 代码格式化配置 (conform.nvim)
--==============================================================================
-- LazyVim 默认使用 conform.nvim 进行代码格式化
-- https://github.com/stevearc/conform.nvim

return {
	--==========================================================================
	-- conform.nvim 配置
	--==========================================================================
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" }, -- 保存前加载
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("util.format").format()
				end,
				desc = "格式化",
			},
		},
		opts = {
			default_format_opts = {
				lsp_format = "never", -- 禁用 LSP 格式化，避免覆盖 conform 结果
			},
			-- LazyVim 自动处理 format_on_save
			-- 按文件类型配置格式化器
			formatters_by_ft = {
				-- 前端
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				vue = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },
				-- HTML 使用 Prettier（空行由 autocmd 清理）
				html = { "prettier" },
				htmldjango = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				["markdown.mdx"] = { "prettier" },
				graphql = { "prettier" },

				-- Python
				python = { "isort", "black" },

				-- Lua
				lua = { "stylua" },

				-- Go
				go = { "gofmt" },

				-- Rust
				rust = { "rustfmt" },

				-- Shell
				sh = { "shfmt" },
				bash = { "shfmt" },

				-- Dockerfile
				dockerfile = { "hadolint" },

				-- 其他
				["_"] = { "trim_whitespace" }, -- 其他文件类型去除空白
			},
			-- 格式化器配置：统一使用 Tab，宽度 4
			formatters = {
				-- Prettier 配置：使用 tab
				prettier = {
					prepend_args = {
						"--use-tabs",
						"--tab-width",
						"4",
						"--print-width",
						"100",
					},
				},
				-- Black 配置（Python 社区强制使用空格，无法配置 tab）
				black = {
					prepend_args = { "--fast" },
					-- 使用 brew 安装的 black（比 Mason 的更快）
					command = "/opt/homebrew/bin/black",
				},
				-- Isort 配置（Python 导入排序）
				isort = {
					prepend_args = {
						"--profile",
						"black", -- 兼容 Black 风格
					},
				},
				-- Stylua 配置：使用 tab
				stylua = {
					prepend_args = { "--indent-type", "Tabs", "--indent-width", "4" },
				},
				-- Shfmt 配置：使用 tab
				shfmt = {
					prepend_args = { "-i", "4", "-t" },
				},
			},
		},
		init = function()
			-- 如果安装了 vim-diffadd，则使用它进行格式化
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},
}
