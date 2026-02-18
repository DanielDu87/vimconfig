--==============================================================================
-- GitHub Copilot 配置（内联虚文本模式 + 面板自动刷新）
--==============================================================================

return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		dependencies = {
			"copilotlsp-nvim/copilot-lsp", -- NES 功能所需
		},
		config = function()
			require("copilot").setup({
				suggestion = {
					-- 启用内联虚文本补全（类似 VSCode）
					enabled = true,
					-- 自动触发补全
					auto_trigger = true,
					-- 在补全菜单显示时隐藏虚文本
					hide_during_completion = false,
					-- 禁用条件：预览窗口中不显示 ghost text
					is_disabled = function()
						-- 检查当前窗口是否是预览窗口
						local current_win = vim.api.nvim_get_current_win()
						if vim.w[current_win].is_snacks_preview then
							return true
						end
						-- 检查当前 buffer 是否是预览 buffer
						local current_buf = vim.api.nvim_get_current_buf()
						if vim.b[current_buf].snacks_preview then
							return true
						end
						return false
					end,
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
					-- 启用面板模式
					enabled = true,
					-- 自动刷新建议
					auto_refresh = true,
					-- 快捷键设置
					keymap = {
						jump_prev = "[[",
						jump_next = "]]",
						accept = "<CR>",
						refresh = "gr",
						open = "<M-CR>",
					},
					-- 窗口布局
					layout = {
						position = "bottom", -- 位置: bottom | top | left | right
						ratio = 0.4,
					},
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
