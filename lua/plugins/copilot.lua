--==============================================================================
-- GitHub Copilot 配置（内联虚文本模式）
--==============================================================================

return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					-- 启用内联虚文本补全（类似 VSCode）
					enabled = true,
					-- 自动触发补全
					auto_trigger = true,
					-- 在补全菜单显示时隐藏虚文本
					hide_during_completion = false,
					-- 快捷键设置
					keymap = {
						-- 接受建议（Tab 键）
						accept = "<Tab>",
						-- 下一个建议
						next = "<M-]>",
						-- 上一个建议
						prev = "<M-[>",
						-- 关闭建议
						dismiss = "<C-]>",
					},
				},
				panel = {
					-- 禁用面板模式
					enabled = false,
				},
				filetypes = {
					yaml = false,
					markdown = true,
					help = true,
					gitcommit = false,
					gitrebase = false,
					["."] = false,
				},
				copilot_node_command = "node", -- Node.js 版本需要 v22+
				server_opts_overrides = {},
			})
		end,
	},
}
