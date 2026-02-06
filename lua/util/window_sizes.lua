-- ============================================================================
-- 窗口大小保存系统 (针对目录保存)
-- ============================================================================

local M = {}

-- 窗口大小存储
M.window_sizes = {}

-- 配置
M.config = {
	save_file = vim.fn.expand("~/window_sizes.json"),
}

-- 标志位：是否正在恢复布局
M.is_restoring = false

-- 保存窗口大小到文件
function M.save_window_sizes()
	local f = io.open(M.config.save_file, "w")
	if f then
		f:write(vim.json.encode(M.window_sizes))
		f:close()
	end
end

-- 从文件加载窗口大小
function M.load_window_sizes()
	local f = io.open(M.config.save_file, "r")
	if not f then return end
	local content = f:read("*all")
	f:close()
	if content == "" then return end
	local ok, data = pcall(vim.json.decode, content)
	if ok then M.window_sizes = data end
end

-- 获取当前目录作为键
local function get_current_dir()
	return vim.fn.getcwd()
end

-- 检查窗口类型
local function get_win_type(win)
	if not vim.api.nvim_win_is_valid(win) then return "invalid" end
	local win_config = vim.api.nvim_win_get_config(win)
	if win_config.relative ~= "" then return "float" end
	
	local buf = vim.api.nvim_win_get_buf(win)
	local ft = vim.bo[buf].filetype
	local bt = vim.bo[buf].buftype
	
	if ft == "snacks_explorer" or ft == "snacks_picker" then
		return "explorer"
	end
	if bt == "terminal" then
		return "terminal"
	end
	if bt == "" then
		return "editor"
	end
	return "special"
end

-- 扫描并保存所有可见窗口的尺寸
function M.save_all_sizes()
	if M.is_restoring then return end
	
	local dir = get_current_dir()
	local data = M.window_sizes[dir] or {}
	local changed = false

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local type = get_win_type(win)
		local w = vim.api.nvim_win_get_width(win)
		local h = vim.api.nvim_win_get_height(win)

		if type == "terminal" then
			local is_horizontal = (w > h * 1.5) or (w > vim.o.columns * 0.8)
			
			if is_horizontal then
				if data.terminal_height ~= h and h > 2 then
					data.terminal_height = h
					changed = true
				end
			else
				if data.terminal_width ~= w and w > 5 then
					data.terminal_width = w
					changed = true
				end
			end
		elseif type == "editor" then
			if data.editor_width ~= w or data.editor_height ~= h then
				data.editor_width = w
				data.editor_height = h
				changed = true
			end
		end
	end

	if changed then
		M.window_sizes[dir] = data
		M.save_window_sizes()
		-- 保留唯一的通知
		vim.notify("窗口尺寸已保存", vim.log.levels.INFO, { title = "Window Sizes" })
	end
end

-- 恢复编辑器尺寸
function M.restore_current_size()
	local dir = get_current_dir()
	local saved = M.window_sizes[dir]
	if not saved then return end

	M.is_restoring = true
	vim.schedule(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local type = get_win_type(win)
			if type == "editor" then
				if saved.editor_width then pcall(vim.api.nvim_win_set_width, win, saved.editor_width) end
				if saved.editor_height then pcall(vim.api.nvim_win_set_height, win, saved.editor_height) end
			end
		end
		vim.defer_fn(function() M.is_restoring = false end, 300)
	end)
end

-- Setup
function M.setup()
	M.load_window_sizes()

	local save_timer = nil
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			if M.is_restoring then return end
			if save_timer then
				save_timer:stop()
				save_timer:close()
			end
			save_timer = vim.loop.new_timer()
			save_timer:start(200, 0, vim.schedule_wrap(function()
				M.save_all_sizes()
			end))
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", { callback = M.save_all_sizes })
	
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = M.restore_current_size,
	})
end

-- 兼容性别名
M.save_current_size = M.save_all_sizes

return M
