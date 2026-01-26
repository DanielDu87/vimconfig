--==============================================================================
-- 终端插件配置：统一管理所有终端相关操作
--==============================================================================
return {
	-- ---------------------------------------------------------------------------
	-- ToggleTerm.nvim：终端管理器
	-- ---------------------------------------------------------------------------
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		opts = {
			-- 终端基本配置
			size = function(term)
				if term.direction == "horizontal" then
					return 15
				elseif term.direction == "vertical" then
					return vim.o.columns * 0.4
				end
			end,
			hide_numbers = true, -- 隐藏行号
			shade_terminals = true,
			start_in_insert = true,
			insert_mappings = true, -- 在插入模式下也映射
			terminal_mappings = true, -- 在终端模式下映射
			persist_size = true,
			persist_mode = true,
			direction = "float", -- 默认浮动窗口
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
					local toggleterm = require("toggleterm")
					toggleterm.toggle(1, vim.fn.expand("%:p:h"), "float")
				end,
				desc = "浮动终端",
			},
			{
				"<leader>th",
				function()
					local toggleterm = require("toggleterm")
					toggleterm.toggle(2, 15, "horizontal")
				end,
				desc = "水平终端",
			},
			{
				"<leader>tv",
				function()
					local toggleterm = require("toggleterm")
					toggleterm.toggle(3, vim.o.columns * 0.4, "vertical")
				end,
				desc = "垂直终端",
			},
			{
				"<leader>tt",
				function()
					local toggleterm = require("toggleterm")
					toggleterm.toggle(4, 100, "tab")
				end,
				desc = "标签页终端",
			},
			-- 切换终端（LazyVim 默认的 Toggle Terminal）
			{
				"<leader>ts",
				function()
					local toggleterm = require("toggleterm")
					toggleterm.toggle(5, 15, "horizontal")
				end,
				desc = "切换终端",
			},
			-- 当前目录终端
			{
				"<leader>tc",
				function()
					LazyVim.terminal()
				end,
				desc = "当前目录终端",
			},
			-- LazyVim 的默认终端快捷键（保留作为别名）
			{
				"<leader>tl",
				function()
					LazyVim.terminal()
				end,
				desc = "Lazy终端",
			},
		},
	},
}
