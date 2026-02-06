--==============================================================================
-- 终端插件配置：统一管理所有终端相关操作
--==============================================================================

-- 辅助函数：在任意窗口打开终端（包括 Explorer 聚焦时）
local function toggle_term_with_direction(direction, size)
	local current_ft = vim.bo.filetype
	local is_explorer = current_ft == "snacks_explorer" or current_ft == "snacks_picker" or current_ft == "snacks_input"

	-- 如果在 Explorer 中，使用浮窗终端（不需要 split 窗口）
	if is_explorer then
		direction = "float"
	end

	-- 如果不是 Explorer 且需要 split，先切换到非 Explorer 窗口
	if not is_explorer then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[buf].filetype
			if ft ~= "snacks_explorer" and ft ~= "snacks_picker" and ft ~= "snacks_input" then
				if vim.api.nvim_get_current_win() ~= win then
					vim.api.nvim_set_current_win(win)
				end
				break
			end
		end
	end

	-- 使用 ToggleTerm Lua API
	local Terminal = require("toggleterm.terminal").Terminal
	local term = Terminal:new({
		direction = direction,
		count = 1,
		size = size,
	})
	term:toggle()
end

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
			persist_mode = false, -- 不保存模式状态，始终以插入模式打开
			-- direction = "float", -- 不要设置默认方向，让每个终端独立指定
			close_on_exit = true, -- 退出时关闭
			-- 使用登录 shell，自动加载 ~/.zprofile、~/.zshrc、~/.shrc 等配置
			shell = vim.o.shell .. " -l",
			float_opts = {
				border = "rounded",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)

			-- 确保终端始终处于插入模式
			local augroup = vim.api.nvim_create_augroup("ToggleTermInsert", { clear = true })

			-- 终端打开时的初始化
			vim.api.nvim_create_autocmd("TermOpen", {
				group = augroup,
				callback = function()
					vim.cmd("startinsert")
					-- 禁用终端的 Neovim 鼠标处理，让终端程序直接处理鼠标
					vim.opt_local.mouse = ""
					vim.opt_local.modifiable = false
				end,
			})

			-- 进入终端缓冲区时自动进入插入模式
			vim.api.nvim_create_autocmd("BufEnter", {
				group = augroup,
				callback = function()
					if vim.bo.buftype == "terminal" then
						vim.cmd("startinsert")
					end
				end,
			})

			-- 切换到终端窗口时自动进入插入模式
			vim.api.nvim_create_autocmd("WinEnter", {
				group = augroup,
				callback = function()
					if vim.bo.buftype == "terminal" then
						vim.cmd("startinsert")
					end
				end,
			})

			-- 终端获得焦点时（鼠标点击或其他方式）自动进入插入模式
			vim.api.nvim_create_autocmd("TermEnter", {
				group = augroup,
				callback = function()
					vim.cmd("startinsert")
				end,
			})

			-- 在终端内检测模式变化，强制切回插入模式
			vim.api.nvim_create_autocmd("ModeChanged", {
				group = augroup,
				pattern = "*:n", -- 从任何模式切换到普通模式时
				callback = function()
					if vim.bo.buftype == "terminal" then
						vim.cmd("startinsert")
					end
				end,
			})
		end,
		keys = {
			-- 终端操作快捷键（统一到 <leader>t 菜单）
			-- 所有终端共享同一个实例，打开新的会关闭旧的
			{
				"<leader>tf",
				function()
					toggle_term_with_direction("float")
				end,
				desc = "浮窗终端",
			},
			{
				"<leader>th",
				function()
					toggle_term_with_direction("horizontal", 15)
				end,
				desc = "竖直终端（上下）",
			},
			{
				"<leader>tv",
				function()
					toggle_term_with_direction("vertical", math.floor(vim.o.columns * 0.4))
				end,
				desc = "水平终端（左右）",
			},
			{
				"<leader>tt",
				function()
					toggle_term_with_direction("tab")
				end,
				desc = "标签页终端",
			},
		},
	},
}
