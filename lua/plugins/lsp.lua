--==============================================================================
-- LSP 自动启动配置
--==============================================================================

-- 公共 inlayHints 配置（用于 ts_ls 和 vtsls）
local ts_inlay_hints = {
	includeInlayParameterNameHints = "all",
	includeInlayParameterNameHintsWhenArgumentMatchesName = false,
	includeInlayFunctionParameterTypeHints = true,
	includeInlayVariableTypeHints = true,
	includeInlayPropertyDeclarationTypeHints = true,
	includeInlayFunctionLikeReturnTypeHints = true,
	includeInlayEnumMemberValueHints = true,
}

return {
	--==========================================================================
	-- Linter 配置 (nvim-lint)
	--==========================================================================
	{
		"mfussenegger/nvim-lint",
		event = { "BufWritePre", "BufReadPost" },
		config = function()
			local lint = require("lint")

			-- 配置 linters
			lint.linters_by_ft = lint.linters_by_ft or {}

			-- 1. HTML / CSS
			lint.linters_by_ft.html = { "markuplint" }
			lint.linters_by_ft.css = { "stylelint" }
			lint.linters_by_ft.scss = { "stylelint" }
			lint.linters_by_ft.less = { "stylelint" }

			-- 2. JavaScript / TypeScript
			lint.linters_by_ft.javascript = { "eslint" }
			lint.linters_by_ft.javascriptreact = { "eslint" }
			lint.linters_by_ft.typescript = { "eslint" }
			lint.linters_by_ft.typescriptreact = { "eslint" }
			lint.linters_by_ft.vue = { "eslint" }

			-- 3. Python
			lint.linters_by_ft.python = { "ruff" }

			-- 4. Docker
			lint.linters_by_ft.dockerfile = { "hadolint" }

			-- 防抖定时器，避免过于频繁触发
			local lint_debounce_timer = nil
			local debounce_ms = 500 -- 500ms 防抖，平衡性能和实时性

			local function trigger_lint()
				-- 清除之前的定时器
				if lint_debounce_timer then
					vim.fn.timer_stop(lint_debounce_timer)
					lint_debounce_timer = nil
				end

				-- 设置新的定时器
				lint_debounce_timer = vim.fn.timer_start(debounce_ms, function()
					local ft = vim.bo.filetype
					local supported_fts = {
						html = true,
						htm = true,
						css = true,
						scss = true,
						less = true,
						javascript = true,
						javascriptreact = true,
						typescript = true,
						typescriptreact = true,
						vue = true,
						python = true,
						dockerfile = true,
					}
					if supported_fts[ft] then
						-- 显示调试信息（可选，注释掉以关闭）
						-- vim.notify("触发 lint: " .. ft, vim.log.levels.DEBUG)
						lint.try_lint()
					end
				end)
			end

			-- 实时触发 lint：编辑时、插入时、保存时
			vim.api.nvim_create_autocmd({
				"BufWritePost",     -- 保存时
				"BufReadPost",      -- 读取时
				"TextChanged",      -- 普通模式下文本改变
				"TextChangedI",     -- 插入模式下文本改变
				"InsertLeave",      -- 退出插入模式
			}, {
				group = vim.api.nvim_create_augroup("nvim-lint-auto", { clear = true }),
				callback = trigger_lint,
			})
		end,
	},

	--==========================================================================
	-- Vtsls 辅助插件 (提供版本切换等 UI 命令)
	--==========================================================================
	{
		"yioneko/nvim-vtsls",
		ft = { "typescript", "typescriptreact", "vue" },
		config = function()
			-- 该插件由 lspconfig 驱动，此处仅确保其加载
		end,
	},

	--==========================================================================
	-- TypeScript 增强插件 (完全还原您之前的 JS 配置)
	--==========================================================================
	{
		"jose-elias-alvarez/typescript.nvim",
		opts = {
			server = {
				filetypes = { "javascript", "javascriptreact" },
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayVariableTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
						},
					},
				},
			},
		},
	},
}
