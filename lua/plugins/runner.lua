--==============================================================================
-- 统一运行中心配置 (Runner)
--==============================================================================
-- 特色：后台静默运行 + 公共只读日志中心，彻底解决报错与拉伸

local M = {}

M.html_job_id = nil
-- 定义全局通用的日志路径
local common_log_file = vim.fn.stdpath("cache") .. "/runner_common.log"

--- 获取侧边栏状态
function M.get_sidebar()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.bo[buf].filetype
		if ft == "snacks_explorer" or ft == "snacks_picker_list" then
			return {
				win = win,
				width = vim.api.nvim_win_get_width(win),
			}
		end
	end
	return nil
end

--- 将信息写入公共日志
function M.write_log(msg)
	local f = io.open(common_log_file, "a")
	if f then
		f:write(string.format("[%s] %s\n", os.date("%H:%M:%S"), msg))
		f:close()
	end
end

-- 启动时自动清空日志
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local f = io.open(common_log_file, "w")
		if f then
			f:write(string.format("[%s] --- 新的会话开始 ---\n", os.date("%Y-%m-%d %H:%M:%S")))
			f:close()
		end
	end,
})

--- 停止并清理 HTML 预览
function M.stop_html_preview()
	local state = M.get_sidebar()
	local old_ea = vim.o.equalalways
	vim.o.equalalways = false
	if state then
		vim.wo[state.win].winfixwidth = true
	end

	-- 终止进程
	if M.html_job_id then
		vim.fn.jobstop(M.html_job_id)
		M.html_job_id = nil
	end
	os.execute("pkill -f browser-sync")
	M.write_log("HTML 预览服务已停止")

	-- 恢复布局
	if state and vim.api.nvim_win_is_valid(state.win) then
		local function fix() 
			if vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_set_width(state.win, state.width)
			end
		end
	vim.schedule(fix)
	vim.defer_fn(fix, 100)
	vim.defer_fn(function()
			fix()
			if vim.api.nvim_win_is_valid(state.win) then vim.wo[state.win].winfixwidth = false end
			vim.o.equalalways = old_ea
		end, 400)
	else
		vim.o.equalalways = old_ea
	end
end

return {
	{
		"snacks.nvim",
		keys = {
			-- 1. HTML 实时预览
			{
				"<leader>rh",
				function()
					M.stop_html_preview()
					M.write_log("正在启动 HTML 实时预览...")
					local cmd = string.format(
						"browser-sync start --server --files '**/*.html, **/*.css, **/*.js' --no-notify --browser '%s' >> %s 2>&1",
						vim.g.browser_path,
						common_log_file
					)
					M.html_job_id = vim.fn.jobstart(cmd, {
						on_exit = function() 
							M.html_job_id = nil 
							M.write_log("HTML 预览服务已退出")
						end,
					})
					vim.notify("HTML 预览已启动 (查看日志: <leader>rl)", vim.log.levels.INFO)
				end,
				desc = "启动 HTML 后台预览",
			},
			-- 2. 查看运行日志
			{
				"<leader>rl",
				function()
					require("snacks").win({
						file = common_log_file,
						show = true,
						width = 0.6,
						height = 0.6,
						border = "rounded",
						title = " 🚀 运行日志 (按 q 退出) ",
						wo = {
							wrap = true,
						},
						on_buf = function(self)
							-- 关键：必须在 buffer 加载后对其进行只读设置
							vim.bo[self.buf].modifiable = false
						end,
						keys = {
							q = "close",
						},
					})
				end,
				desc = "查看运行日志",
			},
			-- 3. 停止所有预览
			{
				"<leader>rs",
				function()
					M.stop_html_preview()
					vim.fn.jobstart({ "pkill", "-f", "manage.py runserver" })
				vim.fn.jobstart({ "pkill", "-f", "uvicorn" })
				M.write_log("所有后台任务已强制清理")
				vim.notify("预览服务已停止", vim.log.levels.WARN)
				end,
				desc = "停止所有预览",
			},
			-- 4. Python 脚本运行
			{
				"<leader>rp",
				function()
					local file = vim.api.nvim_buf_get_name(0)
					M.write_log("运行 Python 脚本: " .. file)
					require("snacks").terminal.get("python3 '" .. file .. "'", {
						win = { position = "float", title = " Python 执行中 " },
					})
				end,
				desc = "运行 Python 脚本",
			},
		},
	},
}