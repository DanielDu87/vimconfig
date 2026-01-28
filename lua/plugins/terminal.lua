--==============================================================================
-- 终端插件配置：统一管理所有终端相关操作
--==============================================================================
return {
	-- ---------------------------------------------------------------------------
	-- ToggleTerm.nvim：终端管理器
	-- ---------------------------------------------------------------------------
	{
		"akinsho/toggleterm.nvim",
		-- version = "*",
		opts = {
			-- 终端基本配置
			size = function(term)
				if term.direction == "horizontal" then
					return 15
				elseif term.direction == "vertical" then
					return vim.o.columns * 0.4
				end
			end,
			open_mapping = [[<C-\>]], -- 启用默认切换快捷键
			hide_numbers = true, -- 隐藏行号
			shade_terminals = true,
			start_in_insert = true,
			insert_mappings = true, -- 在插入模式下也映射
			terminal_mappings = true, -- 在终端模式下映射
			persist_size = true,
			persist_mode = true,
			-- direction = "float", -- 不要设置默认方向，让每个终端独立指定
			close_on_exit = true, -- 退出时关闭
			shell = vim.o.shell, -- 使用默认 shell
			float_opts = {
				border = "rounded",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
		},
		keys = {
			-- 终端操作快捷键（统一到 <leader>t 菜单）
			{
				"<leader>tf",
				function()
					local Terminal = require("toggleterm.terminal").Terminal
					local float_term = Terminal:new({ direction = "float", count = 1 })
					float_term:toggle()
				end,
				desc = "浮窗终端",
			},
			{
				"<leader>th",
				function()
					local Terminal = require("toggleterm.terminal").Terminal
					local horizontal_term = Terminal:new({ direction = "horizontal", count = 2 })
					horizontal_term:toggle()
				end,
				desc = "竖直终端（上下）",
			},
			{
				"<leader>tv",
				function()
					local Terminal = require("toggleterm.terminal").Terminal
					local vertical_term = Terminal:new({ direction = "vertical", count = 3 })
					vertical_term:toggle()
				end,
				desc = "水平终端（左右）",
			},
			{
				"<leader>tt",
				function()
					local Terminal = require("toggleterm.terminal").Terminal
					local tab_term = Terminal:new({ direction = "tab", count = 4 })
					tab_term:toggle()
				end,
				desc = "标签页终端",
			},
		},
	},
}
