--==============================================================================
-- 统一运行中心配置 (Runner)
--==============================================================================
-- 核心理念：后台静默运行 + 实时 Tail 直播出口
-- 特色：三阶段异步宽度校准 + 智能滚动 + 自定义语法高亮

local M = {}

-- 配置
local CONFIG = {
	port = 3000,
	browser_beta = "Google Chrome Beta",
	browser_stable = "Google Chrome",
	bs_path_brew = "/opt/homebrew/bin/browser-sync",
	-- 滚动行为配置
	--   "never"      - 从不自动滚动
	--   "auto"       - 接近底部时自动跟随滚动
	--   "on_complete" - 任务完成时滚动到底部
	scroll = {
		html = "never",
		python = "on_complete",
		default = "auto",
	},
}

M.active_jobs = {}
M.active_log_win = nil -- 记录日志窗口引用
local common_log_file = vim.fn.stdpath("cache") .. "/runner_common.log"

--- 写日志
function M.write_log(msg, raw)
	local f = io.open(common_log_file, "a")
	if f then
		if raw then
			f:write(msg .. "\n")
		else
			f:write(string.format("[%s] %s\n", os.date("%H:%M:%S"), msg))
		end
		f:close()
	end
end

--- 辅助函数：去除 ANSI 颜色代码
local function strip_ansi(str)
	return str:gsub("\27%[[0-9;]*m", "")
end

--- 通用输出处理
local function on_output(chan_id, data, name)
	for _, line in ipairs(data) do
		if line ~= "" then
			-- 某些工具可能会输出 ANSI 颜色，为了日志可读性，这里简单去除
			local clean_line = strip_ansi(line)
			M.write_log(clean_line, true)
		end
	end
end

--- 打印统一分界线
function M.write_separator()
	local separator = string.rep("=<>= ", 20):gsub(" ", "")
	M.write_log(separator, true)
end

--- 获取任务的滚动配置
local function get_scroll_mode(job_name)
	return CONFIG.scroll[job_name] or CONFIG.scroll.default
end

--- 滚动日志窗口到底部
function M.scroll_to_bottom()
	local target_win = M.active_log_win

	-- 如果记录的窗口无效，尝试查找日志窗口
	if not target_win or not vim.api.nvim_win_is_valid(target_win) then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			local buf_name = vim.api.nvim_buf_get_name(buf)
			if buf_name:match("runner_common%.log$") then
				target_win = win
				M.active_log_win = win
				break
			end
		end
	end

	-- 如果仍然找不到有效窗口，退出
	if not target_win or not vim.api.nvim_win_is_valid(target_win) then
		return
	end

	-- 刷新缓冲区并滚动
	local buf = vim.api.nvim_win_get_buf(target_win)
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("checktime")
	end)
	local count = vim.api.nvim_buf_line_count(buf)
	pcall(vim.api.nvim_win_set_cursor, target_win, { count, 0 })
end

--- 获取侧边栏状态
function M.get_sidebar()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "snacks_explorer" then
			return { win = win, width = vim.api.nvim_win_get_width(win) }
		end
	end
	return nil
end

--- 获取浏览器打开命令 (带回退机制)
function M.get_browser_cmd(url)
	-- 1. 尝试 Chrome Beta
	-- 2. 尝试 Chrome 正式版
	-- 3. 使用默认 open
	local cmd = string.format(
		'open -a "%s" "%s" 2>/dev/null || open -a "%s" "%s" 2>/dev/null || open "%s"',
		CONFIG.browser_beta,
		url,
		CONFIG.browser_stable,
		url,
		url
	)
	return cmd
end

--- 获取 browser-sync 命令
function M.get_bs_cmd()
	if vim.fn.executable("browser-sync") == 1 then
		return "browser-sync"
	elseif vim.fn.executable(CONFIG.bs_path_brew) == 1 then
		return CONFIG.bs_path_brew
	else
		return nil
	end
end

--- 清理所有进程
function M.stop_all_jobs()
	local state = M.get_sidebar()
	local old_ea = vim.o.equalalways
	vim.o.equalalways = false
	if state then
		vim.wo[state.win].winfixwidth = true
	end

	-- 1. 停止记录的 Job
	for name, job_info in pairs(M.active_jobs) do
		pcall(vim.fn.jobstop, job_info.id)
		M.active_jobs[name] = nil
	end

	-- 2. 强力杀死相关进程
	os.execute("pkill -9 -f browser-sync 2>/dev/null")
	os.execute("pkill -9 -f 'manage.py runserver' 2>/dev/null")
	os.execute("pkill -9 -f uvicorn 2>/dev/null")

	-- 3. 释放端口
	local kill_port_cmd = string.format("lsof -ti:%d | xargs kill -9 2>/dev/null", CONFIG.port)
	os.execute(kill_port_cmd)
	vim.fn.jobstart("sleep 0.1 && " .. kill_port_cmd, {
		detach = true,
		on_exit = function() end,
	})

	-- 4. 恢复窗口状态
	if state and vim.api.nvim_win_is_valid(state.win) then
		local function fix()
			if vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_set_width(state.win, state.width)
			end
		end
		vim.schedule(fix)
		vim.defer_fn(function()
			fix()
			if vim.api.nvim_win_is_valid(state.win) then
				vim.wo[state.win].winfixwidth = false
			end
			vim.o.equalalways = old_ea
		end, 400)
	else
		vim.o.equalalways = old_ea
	end
end

--- 启动 HTML 预览
function M.run_html_preview()
	if vim.bo.filetype ~= "html" then
		return vim.notify("非 HTML 文件", 3)
	end

	M.stop_all_jobs()
	local file_rel = vim.fn.expand("%:.")
	M.write_separator()
	M.write_log(string.format("启动 HTML 预览: %s", file_rel))

	local bs_cmd = M.get_bs_cmd()
	if not bs_cmd then
		return vim.notify("未找到 browser-sync，请先安装: npm i -g browser-sync", 4)
	end

	local cmd = {
		bs_cmd,
		"start",
		"--server",
		"--port",
		tostring(CONFIG.port),
		"--files",
		"**/*.html, **/*.css, **/*.js",
		"--startPath",
		file_rel,
		"--no-open", -- 禁止 browser-sync 自动打开，由我们手动控制
	}

	local job_id = vim.fn.jobstart(cmd, {
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = on_output,
		on_stderr = on_output,
		on_exit = function(_, code)
			if code ~= 0 and code ~= 143 then
				M.write_log(">>> 进程异常退出，状态码: " .. code)
			end
			M.active_jobs["html"] = nil
		end,
	})
	M.active_jobs["html"] = { id = job_id, scroll_mode = get_scroll_mode("html") }

	-- 智能等待
	vim.defer_fn(function()
		local check_cmd = string.format("lsof -ti:%d", CONFIG.port)
		local function try_open_browser(try_count)
			local result = vim.fn.system(check_cmd)
			if #result > 0 then
				local url = string.format("http://localhost:%d/%s", CONFIG.port, file_rel)
				local browser_cmd = M.get_browser_cmd(url)
				vim.fn.jobstart(browser_cmd, { detach = true })
				M.write_log(">>> 已尝试打开浏览器: " .. url)
				vim.notify("HTML 预览已启动", 2)
			elseif try_count < 10 then
				vim.defer_fn(function()
					try_open_browser(try_count + 1)
				end, 500)
			else
				M.write_log(">>> 等待超时，请手动打开 http://localhost:" .. CONFIG.port .. "/" .. file_rel)
				vim.notify("服务启动中，请稍后手动访问", 3)
			end
		end
		try_open_browser(0)
	end, 1000)
end

-- 启动时清空日志
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local f = io.open(common_log_file, "w")
		if f then
			f:close()
		end
	end,
})

return {
	{
		"snacks.nvim",
		keys = {
			{
				"<leader>rh",
				function()
					M.run_html_preview()
				end,
				desc = "启动 HTML 预览",
			},
			{
				"<leader>rp",
				function()
					if vim.bo.filetype ~= "python" then
						return vim.notify("非 Python 文件", 3)
					end
					M.stop_all_jobs()
					local file = vim.api.nvim_buf_get_name(0)
					local python_path = "python3"

					M.write_separator()
					local run_cmd = string.format("%s -u '%s'", python_path, file)
					M.write_log(">>> 运行指令: " .. run_cmd)

					local job_id = vim.fn.jobstart(run_cmd, {
						stdout_buffered = false,
						stderr_buffered = false,
						on_stdout = on_output,
						on_stderr = on_output,
						on_exit = function(_, code)
							M.write_log(">>> 执行结束 (状态码: " .. code .. ")\n")
							M.active_jobs["python"] = nil
							-- on_complete 模式：完成后滚动到底部（延迟确保日志窗口已打开）
							vim.defer_fn(function()
								M.scroll_to_bottom()
							end, 100)
						end,
					})
					M.active_jobs["python"] = { id = job_id, scroll_mode = get_scroll_mode("python") }
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>rl", true, true, true), "m", true)
				end,
				desc = "运行 Python 脚本",
			},
			{
				"<leader>rl",
				function()
					require("snacks").win({
						file = common_log_file,
						show = true,
						width = 0.7,
						height = 0.7,
						border = "rounded",
						title = " 📋 运行日志 (只读 | 自动刷新) ",
						wo = {
							wrap = true,
							cursorline = true,
						},
					on_buf = function(self)
							-- 记录日志窗口引用
							M.active_log_win = self.win

							vim.schedule(function()
								if not vim.api.nvim_buf_is_valid(self.buf) then
									return
							end
							vim.bo[self.buf].modifiable = false
							vim.bo[self.buf].readonly = true

							-- 注入语法高亮
							vim.api.nvim_buf_call(self.buf, function()
									vim.cmd([[
									syn match RunnerLogHeader /^>>>.*/
										syn match RunnerLogSeparator /^=<>=.*/
										syn match RunnerLogError /Error.*|Exception.*|Traceback.*|Failed.*|状态码: [1-9].*/
										syn match RunnerLogSuccess /Success.*|Completed.*|状态码: 0/
										syn match RunnerLogInfo /\[INFO\].*/
										syn match RunnerLogTime /^\[\d{2}:\d{2}:\d{2}\]/
										hi link RunnerLogHeader Function
										hi link RunnerLogSeparator Comment
										hi link RunnerLogError DiagnosticError
										hi link RunnerLogSuccess DiagnosticOk
										hi link RunnerLogInfo DiagnosticInfo
										hi link RunnerLogTime Comment
							]])
							end)

							-- 开启智能滚动
						local timer = vim.loop.new_timer()
						timer:start(
								500,
								500,
								vim.schedule_wrap(function()
											if not vim.api.nvim_buf_is_valid(self.buf) then
												timer:stop()
												M.active_log_win = nil
												return
										end
										vim.cmd("checktime")

										-- 检查是否有需要自动滚动的任务
										local should_scroll = false
										for _, job_info in pairs(M.active_jobs) do
											if job_info and job_info.scroll_mode == "auto" then
												should_scroll = true
												break
											end
										end

										-- auto 模式：接近底部时跟随滚动
										if should_scroll and self.win and vim.api.nvim_win_is_valid(self.win) then
											local curr_line = vim.api.nvim_win_get_cursor(self.win)[1]
											local total_lines = vim.api.nvim_buf_line_count(self.buf)
											if total_lines - curr_line <= 10 then
												pcall(vim.api.nvim_win_set_cursor, self.win, { total_lines, 0 })
											end
										end
								end)
							)
						end)
					end,
						keys = { q = "close" },
					})
				end,
				desc = "查看实时控制台",
			},
			{
				"<leader>rs",
				function()
					M.stop_all_jobs()
					M.write_separator()
					M.write_log("!!! 手动终止所有后台任务")
				vim.notify("任务已终止", 3)
			end,
			desc = "停止所有任务",
			},
		},
	},
}