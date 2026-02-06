--==============================================================================
-- 终端插件配置：统一管理所有终端相关操作
--==============================================================================

-- 辅助函数：在任意窗口打开终端
local function toggle_term_with_direction(direction_override)
	local ToggleTerm_module = require("toggleterm") -- 获取 toggleterm 模块
	local Terminal_constructor = require("toggleterm.terminal").Terminal -- 获取 Terminal 构造函数
	
	local current_ft = vim.bo.filetype
	local is_explorer = current_ft == "snacks_explorer" or current_ft == "snacks_picker"

	local direction = direction_override
	local term_count = nil

	-- 逻辑优先级：
	-- 1. 如果在 Explorer 中，强制浮窗
	-- 2. 如果明确指定了方向，则使用指定方向的 count
	-- （Ctrl-\ 的情况现在由 toggle() 自动处理，这里不再判断）

	if is_explorer then
		direction = "float"
		term_count = 3 -- float 终端的 count
	elseif direction_override then
		-- 根据传入的 direction_override 确定 count
		if direction_override == "vertical" then term_count = 2
		elseif direction_override == "float" then term_count = 3
		elseif direction_override == "tab" then term_count = 4
		else term_count = 1 -- 默认 horizontal
		end
	else
		-- 如果没有传入 direction_override，这意味着是从 Ctrl-\ 调用的
		-- 但 Ctrl-\ 现在直接调用 toggle()，所以这个分支理论上不会被执行。
		-- 如果被执行，也回退到默认浮窗，防止意外。
		direction = "float"
		term_count = 3
	end
	
	-- 再次确保 direction 变量设置正确
	if not direction then 
		if term_count == 1 then direction = "horizontal"
		elseif term_count == 2 then direction = "vertical"
		elseif term_count == 3 then direction = "float"
		elseif term_count == 4 then direction = "tab"
		else direction = "float"
		end
	end

	-- 加载保存的尺寸
	local window_sizes = require("util.window_sizes")
	window_sizes.load_window_sizes()
	
	local saved = window_sizes.window_sizes[vim.fn.getcwd()]
	local target_size = nil
	
	if saved then
		if direction == "horizontal" then
			target_size = saved.terminal_height
		elseif direction == "vertical" then
			target_size = saved.terminal_width
		end
	end

	-- 兜底默认尺寸
	if not target_size or target_size <= 0 then
		if direction == "horizontal" then
			target_size = 15
		elseif direction == "vertical" then
			target_size = math.floor(vim.o.columns * 0.4)
		end
	end

	-- 确保在正确的窗口打开
	if not is_explorer and direction ~= "float" then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[buf].filetype
			if ft ~= "snacks_explorer" and ft ~= "snacks_picker" then
				vim.api.nvim_set_current_win(win)
				break
			end
		end
	end

	window_sizes.is_restoring = true

	local term = Terminal_constructor:new({
		direction = direction,
		count = term_count,
		size = target_size,
		on_open = function(t)
			vim.schedule(function()
				local win = t.window
				if win and vim.api.nvim_win_is_valid(win) then
					if direction == "horizontal" then
						pcall(vim.api.nvim_win_set_height, win, target_size)
					elseif direction == "vertical" then
						pcall(vim.api.nvim_win_set_width, win, target_size)
					end
				end
				window_sizes.is_restoring = false
			end)
		end,
		on_close = function()
			window_sizes.save_all_sizes()
		end
	})
	
	term:toggle()
	
	-- 兜底解锁
	vim.defer_fn(function()
		window_sizes.is_restoring = false
	end, 500)
end


return {
	{
		"akinsho/toggleterm.nvim",
		opts = {
			direction = "float", -- <--- 添加此行：设置全局默认终端方向
			open_mapping = nil, -- 移除 toggleterm 自身的 open_mapping
			hide_numbers = true,
			shade_terminals = true,
			start_in_insert = true,
			insert_mappings = true,
			terminal_mappings = true,
			persist_size = false, 
			close_on_exit = true,
			shell = vim.o.shell .. " -l",
			float_opts = { border = "rounded", winblend = 0 },
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)
			local augroup = vim.api.nvim_create_augroup("ToggleTermInsert", { clear = true })
			
			vim.api.nvim_create_autocmd("TermOpen", {
				group = augroup,
				callback = function()
					vim.cmd("startinsert")
					vim.opt_local.mouse = ""
				end,
			})
			
			vim.api.nvim_create_autocmd({"BufEnter", "WinEnter", "TermEnter"}, {
				group = augroup,
				callback = function()
					if vim.bo.buftype == "terminal" then vim.cmd("startinsert") end
				end,
			})
			
			-- 将 local function 挂载到全局变量，供外部调用
			vim.g.gemini_toggle_term = toggle_term_with_direction
		end,
		keys = {
			{ "<leader>tf", function() vim.g.gemini_toggle_term("float") end, desc = "浮窗终端" },
			{ "<leader>th", function() vim.g.gemini_toggle_term("horizontal") end, desc = "竖直终端（上下）" },
			{ "<leader>tv", function() vim.g.gemini_toggle_term("vertical") end, desc = "水平终端（左右）" },
			{ "<leader>tt", function() vim.g.gemini_toggle_term("tab") end, desc = "标签页终端" },
			{ "<leader>tn", function() require("util.templates").generate_file() end, desc = "根据模板新建文件" },
			-- 将 Ctrl-\ 映射放在这里
			{
				"<C-\\>",
				function()
					require("toggleterm").toggle() -- 切换上次使用的终端
				end,
				mode = { "n", "t" }, -- 在普通模式和终端模式都生效
				desc = "切换上次终端",
			},
		},
	},
}