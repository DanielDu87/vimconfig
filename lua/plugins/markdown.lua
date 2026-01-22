--==============================================================================
-- Markdown 渲染增强配置 (Render Markdown)
--==============================================================================
-- 作用：
-- 1. 将 ### 等标题渲染为精美的图标和带颜色的文字
-- 2. 将表格渲染为带网格线的可视化样式
-- 3. 将代码块、复选框等进行视觉美化

return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			-- 标题渲染设置
			heading = {
				enabled = true,
				sign = true,
				position = "inline",
				icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
				backgrounds = {
					"RenderMarkdownH1Bg",
					"RenderMarkdownH2Bg",
					"RenderMarkdownH3Bg",
					"RenderMarkdownH4Bg",
					"RenderMarkdownH5Bg",
					"RenderMarkdownH6Bg",
				},
				width = "full",
				left_pad = 1,
				right_pad = 1,
			},
			-- 表格渲染设置
			table = {
				enabled = true,
				preset = "heavy", -- 使用更清晰的重线条网格
			},
			-- 复选框
			checkbox = {
				enabled = true,
			},
			-- 禁用可能产生“幽灵提示”的组件
			link = {
				enabled = false, -- 禁用链接美化 (通常是它产生 1 link 提示)
			},
			sign = {
				enabled = false, -- 禁用侧边栏标志
			},
		},
		ft = { "markdown", "norg", "rmd", "org" },
		config = function(_, opts)
			require("render-markdown").setup(opts)
			-- 定义标题背景颜色 (柔和深色系)
			local colors = {
				"#2d3f76", -- H1: 深蓝
				"#33467c", -- H2
				"#394d82", -- H3
				"#3f5488", -- H4
				"#455b8e", -- H5
				"#4b6294", -- H6
			}
			for i, color in ipairs(colors) do
				vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i .. "Bg", { bg = color, bold = true })
			end
			-- 设置基本的高亮色
			vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#16161e" })
		end,
	},
}
