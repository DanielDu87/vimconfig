--==============================================================================
-- 终端插件配置：统一管理所有终端相关操作
--==============================================================================

-- 终端缓存：存储已创建的终端对象
local terminal_cache = {}
-- 记录上次使用的终端方向，默认为 horizontal (下方垂直)
local last_used_direction = "horizontal"

-- 辅助函数：在任意窗口打开终端
local function toggle_term_with_direction(direction_override)
	-- 有效的终端方向
	local valid_directions = { horizontal = true, vertical = true, float = true, tab = true }

	-- 安全检查：确保 toggleterm 已加载
	local ok_toggleterm, ToggleTerm_module = pcall(require, "toggleterm")
	if not ok_toggleterm then
		vim.notify("终端插件正在加载中，请稍后再试...", vim.log.levels.WARN)
		return
	end

	local ok_terminal, Terminal_module = pcall(require, "toggleterm.terminal")
	if not ok_terminal or not Terminal_module then
		vim.notify("终端模块正在加载中，请稍后再试...", vim.log.levels.WARN)
		return
	end

	local Terminal_constructor = Terminal_module.Terminal

	-- 验证 direction_override 是否为有效值
	if direction_override and type(direction_override) == "string" then
		direction_override = direction_override:lower()
		if not valid_directions[direction_override] then
			vim.notify("无效的终端方向: " .. tostring(direction_override), vim.log.levels.ERROR)
			return
		end
	end

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
		if direction_override == "vertical" then
			term_count = 2
		elseif direction_override == "float" then
			term_count = 3
		elseif direction_override == "tab" then
			term_count = 4
		else
			term_count = 1 -- 默认 horizontal
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
		if term_count == 1 then
			direction = "horizontal"
		elseif term_count == 2 then
			direction = "vertical"
		elseif term_count == 3 then
			direction = "float"
		elseif term_count == 4 then
			direction = "tab"
		else
			direction = "float"
		end
	end

	-- 更新上次使用的方向
	last_used_direction = direction

	-- 互斥逻辑：关闭其他类型的已打开终端（实现 Switch 行为）
	for id, t in pairs(terminal_cache) do
		if id ~= term_count and t:is_open() then
			t:close()
		end
	end

	-- 加载保存的尺寸（添加安全检查）
	local ok_sizes, window_sizes = pcall(require, "util.window_sizes")
	local saved = nil
	if ok_sizes and window_sizes then
		pcall(function() window_sizes.load_window_sizes() end)
		saved = window_sizes.window_sizes[vim.fn.getcwd()]
	end
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

	-- 设置恢复标志（如果 window_sizes 可用）
	if ok_sizes and window_sizes then
		window_sizes.is_restoring = true
	end

	-- 最终验证 direction 和 term_count
	if not direction or type(direction) ~= "string" or not valid_directions[direction] then
		vim.notify(string.format("终端方向异常: direction=%s, term_count=%s, 回退到 float",
			tostring(direction), tostring(term_count)), vim.log.levels.WARN)
		direction = "float"
		term_count = 3
	end

	-- 从缓存获取或创建终端（关键修复：使用本地缓存）
	local term = terminal_cache[term_count]

	if not term then
		-- 终端不存在，创建新的
		local ok, created_term = pcall(function()
			return Terminal_constructor:new({
				direction = direction,
				count = term_count,
				size = target_size,
				on_open = function(t)
					local win = t.window
					if win and vim.api.nvim_win_is_valid(win) then
						-- 完全禁用符号列、折叠列、行号，移除左边距
						vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
						vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
						vim.api.nvim_set_option_value("number", false, { win = win })
						vim.api.nvim_set_option_value("relativenumber", false, { win = win })
					end
					vim.schedule(function()
						local win = t.window
						if win and vim.api.nvim_win_is_valid(win) then
							if direction == "horizontal" then
								pcall(vim.api.nvim_win_set_height, win, target_size)
							elseif direction == "vertical" then
								pcall(vim.api.nvim_win_set_width, win, target_size)
							end
						end
						if ok_sizes and window_sizes then
							window_sizes.is_restoring = false
						end
					end)
				end,
				on_close = function()
					if ok_sizes and window_sizes then
						pcall(window_sizes.save_all_sizes, window_sizes)
					end
				end
			})
		end)

		-- 检查创建是否成功
		if not ok or not created_term then
			vim.notify("创建终端失败，尝试使用浮窗模式", vim.log.levels.WARN)
			-- 回退到浮窗终端
			term_count = 3
			ok, created_term = pcall(function()
				return Terminal_constructor:new({
					direction = "float",
					count = 3,
					size = target_size,
					on_open = function(t)
					local win = t.window
					if win and vim.api.nvim_win_is_valid(win) then
						-- 完全禁用符号列、折叠列、行号，移除左边距
						vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
						vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
						vim.api.nvim_set_option_value("number", false, { win = win })
						vim.api.nvim_set_option_value("relativenumber", false, { win = win })
					end
					vim.schedule(function()
						if ok_sizes and window_sizes then
							window_sizes.is_restoring = false
						end
					end)
				end,
					on_close = function()
						if ok_sizes and window_sizes then
							pcall(window_sizes.save_all_sizes, window_sizes)
						end
					end
				})
			end)

			-- 如果还是失败，直接报错并返回
			if not ok or not created_term then
				vim.notify("终端创建失败，请检查 toggleterm 插件状态", vim.log.levels.ERROR)
				if ok_sizes and window_sizes then
					window_sizes.is_restoring = false
				end
				return
			end

			term = created_term
		else
			term = created_term
		end

		-- 将创建的终端存入缓存
		terminal_cache[term_count] = term
	end

	-- 切换终端开关
	term:toggle()

	-- 兜底解锁（如果 window_sizes 可用）
	if ok_sizes and window_sizes then
		vim.defer_fn(function()
			window_sizes.is_restoring = false
		end, 500)
	end
end

-- 智能切换终端：切换上次使用的终端
local function smart_toggle()
	toggle_term_with_direction(last_used_direction)
end

-- 挂载到全局
vim.g.gemini_smart_toggle = smart_toggle


return {
	{
		"akinsho/toggleterm.nvim",
		opts = {
			direction = "horizontal", -- 首次打开默认下方的终端
			open_mapping = nil, -- 移除 toggleterm 自身的 open_mapping
			hide_numbers = true,
			shade_terminals = true,
			start_in_insert = true,
			insert_mappings = true,
			terminal_mappings = true,
			persist_size = false,
			close_on_exit = true,
			shell = vim.o.shell .. " -l",
			-- 浮窗配置
			float_opts = {
				border = "rounded",
				winblend = 0,
				height = math.floor(vim.o.lines * 0.55),
				width = math.floor(vim.o.columns * 0.8),
				col = math.floor((vim.o.columns - math.floor(vim.o.columns * 0.8)) / 2), -- 水平居中
			},
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)
			local augroup = vim.api.nvim_create_augroup("ToggleTermInsert", { clear = true })

			-- 设置终端窗口样式的辅助函数
			local function set_term_options(win)
				if win and vim.api.nvim_win_is_valid(win) then
					-- 完全禁用符号列、折叠列、行号，移除左边距
					vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
					vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
					vim.api.nvim_set_option_value("number", false, { win = win })
					vim.api.nvim_set_option_value("relativenumber", false, { win = win })
				end
			end

			vim.api.nvim_create_autocmd("TermOpen", {
				group = augroup,
				callback = function()
					vim.cmd("startinsert")
					vim.opt_local.mouse = ""
					local win = vim.api.nvim_get_current_win()
					set_term_options(win)
				end,
			})

			vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TermEnter" }, {
				group = augroup,
				callback = function()
					if vim.bo.buftype == "terminal" then
						vim.cmd("startinsert")
						local win = vim.api.nvim_get_current_win()
						set_term_options(win)
					end
				end,
			})

			-- 将 local function 挂载到全局变量，供外部调用
			vim.g.gemini_toggle_term = toggle_term_with_direction
		end,
		keys = {
			{
				"<leader>tf",
				function()
					if vim.g.gemini_toggle_term then
						vim.g.gemini_toggle_term("float")
					else
						vim.notify("终端功能正在初始化...", vim.log.levels.WARN)
					end
				end,
				desc = "浮窗终端"
			},
			{
				"<leader>th",
				function()
					if vim.g.gemini_toggle_term then
						vim.g.gemini_toggle_term("horizontal")
					else
						vim.notify("终端功能正在初始化...", vim.log.levels.WARN)
					end
				end,
				desc = "竖直终端（上下）"
			},
			{
				"<leader>tv",
				function()
					if vim.g.gemini_toggle_term then
						vim.g.gemini_toggle_term("vertical")
					else
						vim.notify("终端功能正在初始化...", vim.log.levels.WARN)
					end
				end,
				desc = "水平终端（左右）"
			},
			{
				"<leader>tt",
				function()
					if vim.g.gemini_toggle_term then
						vim.g.gemini_toggle_term("tab")
					else
						vim.notify("终端功能正在初始化...", vim.log.levels.WARN)
					end
				end,
				desc = "标签页终端"
			},
			{ "<leader>tn", function() require("util.templates").generate_file() end, desc = "根据模板新建文件" },
			-- 将 Ctrl-\ 映射放在这里
			{
				"<C-\\>",
				function()
					-- 使用智能切换
					if vim.g.gemini_smart_toggle then
						vim.g.gemini_smart_toggle()
					else
						-- 降级方案
						vim.notify("终端功能正在初始化...", vim.log.levels.WARN)
					end
				end,
				mode = { "n", "t" }, -- 在普通模式和终端模式都生效
				desc = "切换终端 (智能)",
			},
		},
	},
}
