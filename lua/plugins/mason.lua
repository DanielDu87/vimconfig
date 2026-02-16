--==============================================================================
-- Mason 配置
--==============================================================================
-- Mason 统一管理所有 LSP 服务器、格式化工具、Lint 工具和调试器
-- 配合 LazyVim 默认的 conform.nvim 和 nvim-lint 使用

return {
	-- Mason 核心插件
	{
		"mason-org/mason.nvim",
		opts = {
			-- 确保所有工具都通过 Mason 安装
			ensure_installed = {
				-- 前端开发（LSP 服务器）
				"typescript-language-server",
				"vue-language-server",
				"tailwindcss-language-server",
				"css-lsp",
				"html-lsp",
				"eslint-lsp",
				"emmet-language-server",

				-- Docker
				"dockerfile-language-server",
				"hadolint",

				-- Python
				"debugpy",

				-- 通用
				"lua-language-server",
				"bash-language-server",
				"yaml-language-server",
				"yamlfmt",
				"json-lsp",
				"markdown-toc",
				"marksman",

				-- 格式化工具（conform.nvim 使用）
				"prettier",
				"prettierd",
				"black",
				"ruff",
				"shfmt",
				"stylua",
				"isort",

				-- Lint 工具（nvim-lint 使用）
				"eslint_d",
				"shellcheck",
				"typos",
				"actionlint",

				-- 其他工具
				"tree-sitter-cli",
			},
		},
	},

	-- Mason 与 nvim-lspconfig 的集成
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				-- 前端
				"ts_ls",
				"tailwindcss",
				"volar",
				"html",
				"cssls",
				"eslint",
				"emmet_language_server",

				-- Docker
				"dockerls",
				"docker_compose_language_service",

				-- Python
				"pyright",

				-- 通用
				"jsonls",
				"yamlls",
				"marksman",
				"lua_ls",
				"bashls",
			},
		},
	},

	-- Mason 与 nvim-dap 的集成（调试器）
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		opts = {
			ensure_installed = {
				"python",
			},
			automatic_setup = true,
		},
	},
}
