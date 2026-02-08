--==============================================================================
-- 统一运行中心配置 (Runner)
--==============================================================================
-- 核心理念：后台静默运行 + 实时 Tail 直播出口
-- 特色：三阶段异步宽度校准 + 智能滚动 + 自定义语法高亮

local M = {}

-- 配置
local CONFIG = {
	port = 3000,
	python_executable = "python3",
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
		javascript = "auto",
		project = "never",  -- 项目运行不自动滚动
		default = "auto",
	},
}

M.active_jobs = {}
M.active_log_win = nil -- 记录日志窗口引用
local common_log_file = vim.fn.stdpath("cache") .. "/runner_common.log"
local runner_config = require("util.runner_config")

---
-- 写日志
--
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

---
-- 辅助函数：去除 ANSI 颜色代码和回车符
--
local function strip_ansi(str)
	-- 使用括号强制只返回第一个值（字符串），丢弃 gsub 返回的第二个值（替换次数）
	return (str:gsub("\27%[[0-9;]*m", ""):gsub("\r", ""))
end

---
-- 通用输出处理 (流式写入)
--
local function on_output(chan_id, data, name)
	if not data then return end
	local f = io.open(common_log_file, "a")
	if f then
		for i, line in ipairs(data) do
			f:write(strip_ansi(line))
			if i < #data then
				f:write("\n")
			end
		end
		f:close()
	end
end

---
-- 打印统一分界线
--
function M.write_separator()
	local win_id = nil
	-- 尝试获取当前活动窗口的ID，并检查是否是runnerlog类型
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.api.nvim_buf_get_option(buf, "filetype") == "runnerlog" then
			win_id = win
			break
		end
	end

	local win_width = 80 -- 默认宽度
	if win_id and vim.api.nvim_win_is_valid(win_id) then
		win_width = vim.api.nvim_win_get_width(win_id)
	elseif M.active_log_win and vim.api.nvim_win_is_valid(M.active_log_win) then
		-- 如果当前没有活动窗口，但记录了日志窗口，则使用记录的窗口
		win_width = vim.api.nvim_win_get_width(M.active_log_win)
	end

	win_width = math.max(win_width, 10) -- 确保最小宽度

	local pattern_core = "=<>= " -- 核心模式，包含一个空格
	local pattern_fill = "=<>"   -- 用于计算和填充的模式 (不含尾部空格)
	local pattern_fill_len = #pattern_fill

	local separator = ""
	local current_visual_len = 0

	-- 尝试用 pattern_fill 填满，避免末尾是空格
	while current_visual_len + pattern_fill_len <= win_width do
		separator = separator .. pattern_fill
		current_visual_len = current_visual_len + pattern_fill_len
	end

	-- 如果还没满，且可以再加一个空格
	if current_visual_len + 1 <= win_width then
		separator = separator .. "="
		current_visual_len = current_visual_len + 1
	end

	-- 用 = 补齐剩余空间
	local remaining_chars = win_width - current_visual_len
	if remaining_chars > 0 then
		separator = separator .. string.rep("=", remaining_chars)
	end
	
	M.write_log(separator, true)
end

---
-- 刷新日志窗口内容
--
function M.refresh_log_window()
	if M.active_log_win and vim.api.nvim_win_is_valid(M.active_log_win) then
		local buf = vim.api.nvim_win_get_buf(M.active_log_win)
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("checktime")
			end)
		end
	end
end

---
-- 打开运行日志窗口
--
function M.open_runner_log_window(initial_message)
	local win = require("snacks").win({
		file = common_log_file,
		show = true,
		width = 0.7,
		height = 0.7,
		border = "rounded",
		title = " 📋 运行日志（只读 | 自动刷新） ",
		wo = {
			wrap = true,
			cursorline = true,
		},
		on_buf = function(self)
			-- 记录日志窗口引用
			M.active_log_win = self.win

			-- 设置快捷键映射的函数
			local function setup_keys()
				if not vim.api.nvim_buf_is_valid(self.buf) then
					return
				end
				-- 清除旧的映射（如果存在）
				pcall(vim.api.nvim_buf_del_keymap, self.buf, "n", "q")
				pcall(vim.api.nvim_buf_del_keymap, self.buf, "n", "<Esc>")
				-- 设置新的映射
				vim.api.nvim_buf_set_keymap(self.buf, "n", "q", "<Cmd>lua vim.api.nvim_win_close(0, true)<CR>", {
					nowait = true,
					silent = true,
				})
				vim.api.nvim_buf_set_keymap(self.buf, "n", "<Esc>", "<Cmd>lua vim.api.nvim_win_close(0, true)<CR>", {
					nowait = true,
					silent = true,
				})
			end

			-- 立即设置一次
			setup_keys()

			-- 创建自动命令组，确保每次进入缓冲区时重新设置键映射
			local augroup = vim.api.nvim_create_augroup("RunnerLogKeys", { clear = false })
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = self.buf })
			vim.api.nvim_create_autocmd("BufEnter", {
				group = augroup,
				buffer = self.buf,
				callback = setup_keys,
			})

			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(self.buf) then
					return
				end
				vim.bo[self.buf].modifiable = false
				vim.bo[self.buf].readonly = true

				-- 设置文件类型，语法高亮由 autocmds.lua 处理
				vim.bo[self.buf].filetype = 'runnerlog'

				-- 每次打开窗口时，清空文件并写入分隔符
				local f = io.open(common_log_file, "w")
				if f then f:close() end -- 清空文件

				M.write_separator() -- 写入分隔符

				-- 写入初始消息
				if initial_message then
					M.write_log(initial_message)
				end

				-- 开启智能滚动
				local timer = vim.uv.new_timer()
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

						-- checktime 后重新设置键映射
						setup_keys()

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
	})
end

---
-- 获取任务的滚动配置
--
local function get_scroll_mode(job_name)
	return CONFIG.scroll[job_name] or CONFIG.scroll.default
end

---
-- 滚动日志窗口到底部
--
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

---
-- 获取侧边栏状态
--
function M.get_sidebar()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "snacks_explorer" then
			return { win = win, width = vim.api.nvim_win_get_width(win) }
		end
	end
	return nil
end

---
-- 获取浏览器打开命令 (带回退机制)
--
function M.get_browser_cmd(url)
	-- 使用全局变量定义的浏览器路径
	local browser = vim.g.browser_path or "/Applications/Arc.app"
	local cmd = string.format('open -a "%s" "%s"', browser, url)
	return cmd
end

---
-- 获取 browser-sync 命令
--
function M.get_bs_cmd()
	if vim.fn.executable("browser-sync") == 1 then
		return "browser-sync"
	elseif vim.fn.executable(CONFIG.bs_path_brew) == 1 then
		return CONFIG.bs_path_brew
	else
		return nil
	end
end

---
-- 清理所有进程
--
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

---
-- 启动 HTML 预览
--
function M.run_html_preview()
	if vim.bo.filetype ~= "html" then
		return vim.notify("非 HTML 文件", 3)
	end

	M.stop_all_jobs()
	local file_rel = vim.fn.expand("%:.")
	local initial_msg = string.format("启动 HTML 预览: %s", file_rel)
	M.open_runner_log_window(initial_msg) -- 传递初始消息

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
			-- 信号退出码 (>=128) 视为正常退出
			if code ~= 0 and code < 128 then
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
	M.open_runner_log_window() -- 替换 vim.api.nvim_feedkeys
end

---
-- 打开浏览器URL
--
local function open_browser(url)
	if not url or url == "" then
		return vim.notify("URL 为空", 3)
	end

	-- 自动添加 http:// 前缀（如果没有协议）
	if not url:match("^[hH][tT][tT][pP][sS]?://") then
		url = "http://" .. url
	end

	local browser_cmd = M.get_browser_cmd(url)
	vim.fn.jobstart(browser_cmd, { detach = true })
	vim.notify("已在浏览器打开: " .. url, 2)
end

---
-- 获取当前环境的 Python 解释器路径
-- 优先级: LSP配置 > VIRTUAL_ENV环境变量 > 配置默认值 > python3
--
local function get_python_path()
	-- 1. 尝试从 LSP 客户端配置中获取 (pyright / basedpyright)
	-- 注意：vim.lsp.get_active_clients 已在 0.10+ 废弃，应使用 vim.lsp.get_clients
	local clients = vim.lsp.get_clients({ bufnr = 0, name = "pyright" })
	if #clients == 0 then
		clients = vim.lsp.get_clients({ bufnr = 0, name = "basedpyright" })
	end
	
	if #clients > 0 then
		local client = clients[1]
		if client.config and client.config.settings and client.config.settings.python and client.config.settings.python.pythonPath then
			local lsp_path = client.config.settings.python.pythonPath
			-- 确保路径不是默认的 "python" 且不为空
			if lsp_path and lsp_path ~= "python" and lsp_path ~= "" then
				return lsp_path
			end
		end
	end

	-- 2. 尝试从 VIRTUAL_ENV 环境变量获取
	if vim.env.VIRTUAL_ENV then
		return vim.env.VIRTUAL_ENV .. "/bin/python"
	end

	-- 3. 回退到配置的默认值 或 系统 python3
	return CONFIG.python_executable or "python3"
end

---
-- 运行当前项目（完整命令）
--
function M.run_project()
	local project_cmd = runner_config.get_current_project_runner()
	if not project_cmd then
		return vim.notify("未配置项目运行命令，请按 <leader>rC 配置", 3)
	end

	M.stop_all_jobs()
	local initial_msg = ">>> 运行项目: " .. project_cmd
	M.open_runner_log_window(initial_msg) -- 传递初始消息

	local job_id = vim.fn.jobstart(project_cmd, {
		stdout_buffered = false,
		stderr_buffered = false,
		pty = true,
		on_stdout = on_output,
		on_stderr = on_output,
		on_exit = function(_, code)
			-- 信号退出码 (>=128) 视为正常退出
			if code == 0 or code >= 128 then
				M.write_log(">>> 项目运行结束（状态码: " .. code .. "）\n")
			else
				M.write_log(">>> 进程异常退出，状态码: " .. code .. "\n")
			end
			M.active_jobs["project"] = nil
		end,
	})
	M.active_jobs["project"] = { id = job_id, scroll_mode = get_scroll_mode("project") }

	-- 智能等待并尝试打开浏览器
	vim.defer_fn(function()
		-- 尝试从项目配置中获取浏览器URL
		local project_url = runner_config.get_current_project_browser()
		if project_url and project_url ~= "" then
			-- 自动添加 http:// 前缀（如果没有协议）
			if not project_url:match("^[hH][tT][tT][pP][sS]?://") then
				project_url = "http://" .. project_url
			end
			-- 等待 1 秒后打开浏览器
			vim.defer_fn(function()
				open_browser(project_url)
				M.write_log(">>> 已在浏览器打开: " .. project_url)
			end, 1000)
		end
	end, 500)
end

---
-- 运行当前文件（自动识别类型）
--
function M.run_current_file()
	local ft = vim.bo.filetype
	local file = vim.api.nvim_buf_get_name(0)

	-- 检查文件级别的自定义运行命令
	local custom_cmd_prefix = runner_config.get_file_runner(file)
	if custom_cmd_prefix then
		M.stop_all_jobs()
		local final_run_cmd = string.format("%s %s", custom_cmd_prefix, file)
		M.open_runner_log_window(">>> 运行命令: " .. final_run_cmd) -- 传递初始消息

		local job_id = vim.fn.jobstart(final_run_cmd, {
			stdout_buffered = false,
			stderr_buffered = false,
			pty = true,
			on_stdout = on_output,
			on_stderr = on_output,
			on_exit = function(_, code)
				-- 信号退出码 (>=128) 视为正常退出
				if code == 0 or code >= 128 then
					M.write_log(">>> 运行结束（状态码: " .. code .. "）\n")
				else
					M.write_log(">>> 进程异常退出，状态码: " .. code .. "\n")
				end
				M.active_jobs["custom_file_runner"] = nil -- 使用一个通用的键名
			end,
		})
		-- 假设自定义命令通常不需要特殊的滚动模式，使用默认的 auto
		M.active_jobs["custom_file_runner"] = { id = job_id, scroll_mode = get_scroll_mode("default") }
		return -- 如果有自定义命令，则直接返回
	end

	-- HTML 文件
	if ft == "html" then
		M.run_html_preview()
		return
	end

	-- JavaScript 文件
	if ft == "javascript" or ft == "javascriptreact" then
		M.stop_all_jobs()
		-- local file = vim.api.nvim_buf_get_name(0) -- 已经移到顶部
		local node_path = "node"

		local run_cmd = string.format("%s %s", node_path, file)
		M.open_runner_log_window(">>> 运行指令: " .. run_cmd) -- 传递初始消息

		local job_id = vim.fn.jobstart(run_cmd, {
			stdout_buffered = false,
			stderr_buffered = false,
			pty = true,
			on_stdout = on_output,
			on_stderr = on_output,
			on_exit = function(_, code)
				-- 信号退出码 (>=128) 视为正常退出
				if code == 0 or code >= 128 then
					M.write_log(">>> 执行结束（状态码: " .. code .. "）\n")
				else
					M.write_log(">>> 进程异常退出，状态码: " .. code .. "\n")
				end
				M.active_jobs["javascript"] = nil
			end,
		})
		M.active_jobs["javascript"] = { id = job_id, scroll_mode = get_scroll_mode("javascript") }
		return
	end

	-- Python 文件
	if ft == "python" then
		M.stop_all_jobs()
		-- local file = vim.api.nvim_buf_get_name(0) -- 已经移到顶部
		local python_path = get_python_path()

		local run_cmd = string.format("%s -u %s", python_path, file)
		M.open_runner_log_window(">>> 运行指令: " .. run_cmd) -- 传递初始消息

		local job_id = vim.fn.jobstart(run_cmd, {
			stdout_buffered = false,
			stderr_buffered = false,
			pty = true,
			on_stdout = on_output,
			on_stderr = on_output,
			on_exit = function(_, code)
				-- 信号退出码 (>=128) 视为正常退出
				if code == 0 or code >= 128 then
					M.write_log(">>> 执行结束（状态码: " .. code .. "）\n")
				else
					M.write_log(">>> 进程异常退出，状态码: " .. code .. "\n")
				end
				M.active_jobs["python"] = nil
				-- on_complete 模式：完成后滚动到底部
				vim.defer_fn(function()
					M.scroll_to_bottom()
				end, 100)
			end,
		})
		M.active_jobs["python"] = { id = job_id, scroll_mode = get_scroll_mode("python") }
		return
	end

	-- C 文件
	if ft == "c" then
		M.stop_all_jobs()
		-- 获取输出文件名（去掉 .c 扩展名）
		local output_file = vim.fn.expand("%:r")
		local compile_cmd = string.format("gcc %s -o %s", file, output_file)
		local run_cmd = string.format("%s/%s", vim.fn.expand("%:p:h"), output_file)

		M.open_runner_log_window(">>> 编译命令: " .. compile_cmd .. "\n>>> 运行命令: " .. run_cmd)

		-- 先编译
		local compile_job = vim.fn.jobstart(compile_cmd, {
			stdout_buffered = false,
			stderr_buffered = false,
			pty = true,
			on_stdout = on_output,
			on_stderr = on_output,
			on_exit = function(_, code)
				if code ~= 0 then
					M.write_log(">>> 编译失败（状态码: " .. code .. "）\n")
					M.active_jobs["c"] = nil
					return
				end
				M.write_log(">>> 编译成功，开始运行...\n")
				-- 编译成功后运行
				local run_job = vim.fn.jobstart(run_cmd, {
					stdout_buffered = false,
					stderr_buffered = false,
					pty = true,
					on_stdout = on_output,
					on_stderr = on_output,
					on_exit = function(_, run_code)
						if run_code == 0 or run_code >= 128 then
							M.write_log(">>> 运行结束（状态码: " .. run_code .. "）\n")
						else
							M.write_log(">>> 进程异常退出，状态码: " .. run_code .. "\n")
						end
						M.active_jobs["c"] = nil
						vim.defer_fn(function()
							M.scroll_to_bottom()
						end, 100)
					end,
				})
				M.active_jobs["c"] = { id = run_job, scroll_mode = get_scroll_mode("default") }
			end,
		})
		M.active_jobs["c"] = { id = compile_job, scroll_mode = get_scroll_mode("default") }
		return
	end

	-- 不支持的文件类型
	vim.notify("不支持的文件类型: " .. ft .. "\n支持的类型: c, html, javascript, python\n或按 <leader>rc 配置自定义运行命令", 3)
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
				"<leader>rr",
				function()
					M.run_current_file()
				end,
				desc = "运行当前文件",
			},
			{
				"<leader>rp",
				function()
					M.run_project()
				end,
				desc = "运行项目",
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
						title = " 📋 运行日志（只读 | 自动刷新） ",
						wo = {
							wrap = true,
							cursorline = true,
						},
					on_buf = function(self)
							-- 记录日志窗口引用
							M.active_log_win = self.win

							-- 设置快捷键映射 - 使用 Lua API 直接关闭窗口
							vim.api.nvim_buf_set_keymap(self.buf, "n", "q", "<Cmd>lua vim.api.nvim_win_close(0, true)<CR>", {
								nowait = true,
								silent = true,
							})
							vim.api.nvim_buf_set_keymap(self.buf, "n", "<Esc>", "<Cmd>lua vim.api.nvim_win_close(0, true)<CR>", {
								nowait = true,
								silent = true,
							})

							vim.schedule(function()
								if not vim.api.nvim_buf_is_valid(self.buf) then
									return
							end
							vim.bo[self.buf].modifiable = false
							vim.bo[self.buf].readonly = true

							-- 设置文件类型，语法高亮由 autocmds.lua 处理
							vim.bo[self.buf].filetype = 'runnerlog'

							-- 在日志窗口打开并设置filetype后，再写入分隔符
							M.write_separator()

							-- 开启智能滚动
							local timer = vim.uv.new_timer()
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
					})
				end,
				desc = "日志",
			},
			{
				"<leader>rs",
				function()
					M.stop_all_jobs()
					M.write_separator()
					M.write_log("!!! 手动终止所有后台任务")
					vim.notify("任务已终止", 3)
				end,
				desc = "停止",
			},
			{
				"<leader>rc",
				function()
					local file = vim.api.nvim_buf_get_name(0)
					if not file or file == "" then
						vim.notify("未保存的文件无法配置运行路径", 3)
						return
				end

				vim.ui.input({
					prompt = "配置运行命令前缀（会自动追加当前文件名）：",
					default = runner_config.get_file_runner(file) or ""
				}, function(command)
					if command ~= nil then -- 用户没有取消
						if command == "" then
							runner_config.clear_file_runner(file)
							vim.notify("已清除当前文件的自定义运行命令", 2)
						else
							runner_config.set_file_runner(file, command)
							vim.notify("已为当前文件设置运行命令: " .. command, 2)
						end
					end
				end)
				end,
				desc = "配置当前文件运行命令",
			},
			{
				"<leader>rC",
				function()
					local root = runner_config.get_project_root()
					if not root then
						vim.notify("无法确定项目根目录", 3)
						return
					end

					vim.ui.input({
						prompt = "配置项目运行命令（完整命令）：",
						default = runner_config.get_project_runner(root) or ""
					}, function(command)
						if command ~= nil then -- 用户没有取消
							if command == "" then
								runner_config.clear_project_runner(root)
								vim.notify("已清除项目运行命令", 2)
							else
								runner_config.set_project_runner(root, command)
								vim.notify("已设置项目运行命令", 2)
							end
						end
					end)
				end,
				desc = "配置项目运行命令",
			},
			{
				"<leader>rb",
				function()
					local file = vim.api.nvim_buf_get_name(0)
					if not file or file == "" then
						vim.notify("未保存的文件无法配置浏览器URL", 3)
						return
					end

					vim.ui.input({
						prompt = "配置文件浏览器URL:",
						default = runner_config.get_file_browser(file) or ""
					}, function(url)
						if url ~= nil then
							if url == "" then
								runner_config.clear_file_browser(file)
							else
								runner_config.set_file_browser(file, url)
								vim.notify("已设置文件浏览器URL: " .. url, 2)
							end
						end
					end)
				end,
				desc = "配置文件浏览器URL",
			},
			{
				"<leader>rB",
				function()
					local root = runner_config.get_project_root()
					if not root then
						vim.notify("无法确定项目根目录", 3)
						return
					end

					vim.ui.input({
						prompt = "配置项目浏览器URL:",
						default = runner_config.get_project_browser(root) or ""
					}, function(url)
						if url ~= nil then
							if url == "" then
								runner_config.clear_project_browser(root)
							else
								runner_config.set_project_browser(root, url)
								vim.notify("已设置项目浏览器URL: " .. url, 2)
							end
						end
					end)
				end,
				desc = "配置项目浏览器URL",
			},
			{
				"<leader>ro",
				function()
					-- 优先使用文件级配置
					local file = vim.api.nvim_buf_get_name(0)
					if file and file ~= "" then
						local file_url = runner_config.get_file_browser(file)
						if file_url and file_url ~= "" then
							open_browser(file_url)
							return
						end
					end

					-- 回退到项目级配置
					local project_url = runner_config.get_current_project_browser()
					if project_url and project_url ~= "" then
						open_browser(project_url)
						return
					end
				end,
				desc = "打开浏览器",
			},
		},
	},
}
