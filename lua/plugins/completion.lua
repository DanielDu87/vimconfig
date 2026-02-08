--==============================================================================
-- 补全引擎配置 (blink.cmp)
--==============================================================================

return {
	-- 禁用 LazyVim 默认的 nvim-cmp，防止冲突
	{ "hrsh7th/nvim-cmp", enabled = false },
	{ "iguanacucumber/magazine.nvim", enabled = false, name = "nvim-cmp" }, -- 某些 LazyVim 版本可能使用此 fork

	{
		"saghen/blink.cmp",
		dependencies = {
			{ "L3MON4D3/LuaSnip", version = "v2.*", build = "make install_jsregexp" },
		},
		opts = function(_, opts)
			-- 显式指定使用 LuaSnip 作为片段引擎
			opts.snippets = { preset = "luasnip" }

			-- 键盘映射配置
			opts.keymap = {
				preset = "enter",
				["<Tab>"] = { "show", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "fallback" },
				-- 确保 Enter 在有补全项时优先选择，无补全项时才换行
				["<CR>"] = { "accept", "fallback" },
			}

			-- 合并补全源配置，确保优先级并保留现有源（如 Copilot）
			opts.sources = vim.tbl_deep_extend("force", opts.sources or {}, {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					snippets = {
						score_offset = -20, -- 降低优先级，确保 LSP 建议排在最前
					},
				},
			})

			-- 补全菜单设置
			opts.completion = {
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = {
						min_width = 15,
						max_width = 80,
						max_height = 20,
						border = "rounded",
						winblend = 0,
						scrollbar = false,
					},
				},
				menu = {
					min_width = 30,
					max_height = 10,
					border = "rounded",
					winblend = 0,
					scrollbar = false,
					-- 确保绘制顺序：文字在左，图标（颜色）和类型在右
					draw = {
						columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
						components = {
							kind_icon = {
								text = function(ctx)
									local item = ctx.item
									local doc = item.documentation
									if type(doc) == "table" then
										doc = doc.value
									end
									-- 尝试从文档或标签中提取颜色
									local ok, hl = pcall(require, "nvim-highlight-colors")
									if ok then
										local color_item = hl.format(doc or item.label, { kind = "Color" })
										if color_item and color_item.abbr and color_item.abbr ~= "" and color_item.abbr ~= "Color" then
											return color_item.abbr .. " "
										end
									end
									return ctx.kind_icon
								end,
								highlight = function(ctx)
									local item = ctx.item
									local doc = item.documentation
									if type(doc) == "table" then
										doc = doc.value
									end
									local ok, hl = pcall(require, "nvim-highlight-colors")
									if ok then
										local color_item = hl.format(doc or item.label, { kind = "Color" })
										if color_item and color_item.abbr_hl_group then
											return color_item.abbr_hl_group
										end
									end
									return ctx.kind_icon_hl
								end,
							},
						},
					},
				},
			}

			-- 函数参数签名提示 (Signature Help)
			opts.signature = {
				enabled = true,
				window = {
					min_width = 30,
					max_width = 80,
					border = "rounded",
					winblend = 0,
					scrollbar = false,
				},
			}

			return opts
		end,
	},
}
