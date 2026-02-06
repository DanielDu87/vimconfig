--==============================================================================
-- 补全引擎配置 (blink.cmp)
--==============================================================================

return {
	-- 禁用 LazyVim 默认的 nvim-cmp，防止冲突
	{ "hrsh7th/nvim-cmp", enabled = false },
	{ "iguanacucumber/magazine.nvim", enabled = false, name = "nvim-cmp" }, -- 某些 LazyVim 版本可能使用此 fork

	{
		"saghen/blink.cmp",
		opts = {
			-- 显式配置补全源，确保 LSP 被启用
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				-- 可选：针对特定文件类型的覆盖
				-- per_filetype = {
				-- 	codecompanion = { "codecompanion" },
				-- },
			},
			completion = {
				-- 文档提示窗口设置
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
				-- 补全菜单设置
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
									local color_item = require("nvim-highlight-colors").format(doc or item.label, { kind = "Color" })
									if color_item and color_item.abbr and color_item.abbr ~= "" and color_item.abbr ~= "Color" then
										return color_item.abbr .. " "
									end
									return ctx.kind_icon
								end,
								highlight = function(ctx)
									local item = ctx.item
									local doc = item.documentation
									if type(doc) == "table" then
										doc = doc.value
									end
									local color_item = require("nvim-highlight-colors").format(doc or item.label, { kind = "Color" })
									if color_item and color_item.abbr_hl_group then
										return color_item.abbr_hl_group
									end
									return ctx.kind_icon_hl
								end,
							},
						},
					},
				},
			},
			-- 函数参数签名提示 (Signature Help)
			signature = {
				enabled = true,
				window = {
					min_width = 30,
					max_width = 80,
					border = "rounded",
					winblend = 0,
					scrollbar = false,
				},
			},
		},
	},
}