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
			notify_on_error = true, -- 格式化出错时显示通知
			default_format_opts = {
				lsp_format = "never", -- 禁用 LSP 格式化，避免覆盖 conform 结果
			},
			-- LazyVim 自动处理 format_on_save
			-- 按文件类型配置格式化器
			formatters_by_ft = {
				-- 前端
				javascript = { "eslint_d", "prettier" },
				javascriptreact = { "eslint_d", "prettier" },
				typescript = { "eslint_d", "prettier" },
				typescriptreact = { "eslint_d", "prettier" },
				vue = { "eslint_d", "prettier" },
				css = { "stylelint", "prettier" },
				scss = { "stylelint", "prettier" },
				less = { "stylelint", "prettier" },
				-- HTML 只使用 Prettier 进行排版（markuplint用于lint，不用于格式化）
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
			go = { "goimports", "gofumpt" },

			-- Rust
			rust = { "rustfmt" },

			-- Shell
			sh = { "shfmt" },
			bash = { "shfmt" },

			-- SQL
			sql = { "prettier" },

			-- Dockerfile: 使用 sed 强制将指令转换为大写
		dockerfile = { "docker_uppercase", "trim_whitespace" },

			-- 其他
			["_"] = { "trim_whitespace" }, -- 其他文件类型去除空白
			},
			-- 格式化器配置：统一使用 Tab，宽度 4
			formatters = {
				-- 自定义 Docker 格式化器 (使用 Perl 确保跨平台兼容性)
			docker_uppercase = {
				command = "perl",
				args = {
					"-pe",
					-- 1. 将指令转为大写 2. 将指令后的多个空格压缩为一个
					"s/^\\s*(from|run|cmd|label|maintainer|expose|env|add|copy|entrypoint|volume|user|workdir|arg|onbuild|stopsignal|healthcheck|shell)(\\s+)/\\U$1 /ig",
				},
				},
				-- Prettier 配置：使用 tab
				prettier = {
					prepend_args = {
						"--use-tabs",
						"--tab-width",
						"4",
						"--print-width",
						"120",
						"--bracket-same-line",
						"true",
						"--plugin",
						"prettier-plugin-tailwindcss",
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
				prepend_args = { "-i", "0", "-ci" },
			},
				-- SQL 格式化配置：使用 4 空格, 关键字大写
			sql_formatter = {
				prepend_args = {
					"--config",
					'{"indentation": "    ", "keywordCase": "upper"}',
				},
			},
				-- Stylelint 配置：使用系统全局版本，并开启自动修复
			stylelint = {
				command = "/opt/homebrew/bin/stylelint",
				args = { "--fix", "--stdin-filename", "$FILENAME" },
			},
			},
		},
		init = function()
			-- 如果安装了 vim-diffadd，则使用它进行格式化
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},
}