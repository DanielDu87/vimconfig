--==============================================================================
-- 统一运行中心配置 (Runner)
--==============================================================================
-- 快捷键：<leader>r 组
-- 特色：支持自动清理残留进程，保证系统性能

local M = {}

-- 用于存储当前正在运行的预览进程对象
M.html_preview_job = nil

--- 停止并清理之前的 HTML 预览进程
local function stop_html_preview()
	-- 1. 记录当前目录树的宽度
	local sidebar_win = nil
	local sidebar_width = 30 -- 默认回退值
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "snacks_explorer" then
			sidebar_win = win
			sidebar_width = vim.api.nvim_win_get_width(win)
			break
		end
	end

	-- 2. 保护性锁定
	local old_ea = vim.o.equalalways
	vim.o.equalalways = false
	if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
		vim.wo[sidebar_win].winfixwidth = true
	end

	-- 3. 彻底清理进程
	vim.fn.jobstart({ "pkill", "-f", "browser-sync" })
	if M.html_preview_job then
		pcall(function()
			M.html_preview_job:close()
		end)
		M.html_preview_job = nil
	end

	-- 4. 关键：分阶段强制恢复宽度（解决 Neovim 异步布局重排问题）
	if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
		local function force_fix()
			if vim.api.nvim_win_is_valid(sidebar_win) then
				vim.api.nvim_win_set_width(sidebar_win, sidebar_width)
			end
		end

		vim.schedule(force_fix)
		vim.defer_fn(force_fix, 50)
		vim.defer_fn(force_fix, 150)
		vim.defer_fn(function()
			force_fix()
			if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
				vim.wo[sidebar_win].winfixwidth = false -- 释放锁定
			end
			vim.o.equalalways = old_ea -- 最后恢复均衡设置
		end, 300)
	else
		vim.o.equalalways = old_ea
	end
end

-- 注册退出清理自动命令
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = vim.api.nvim_create_augroup("RunnerCleanup", { clear = true }),
	callback = function()
		stop_html_preview()
		os.execute("pkill -f 'manage.py runserver'")
		os.execute("pkill -f uvicorn")
	end,
})

return {
	{
		"snacks.nvim",
		keys = {
			-- HTML 实时预览
			{
				"<leader>rh",
				function()
					stop_html_preview()
					-- 监听当前目录及子目录下所有的 html, css, js 文件
					vim.defer_fn(function()
						M.html_preview_job = require("snacks").terminal.get(
							"browser-sync start --server --files '**/*.html, **/*.css, **/*.js'",
							{
								win = {
									position = "float",
									border = "rounded",
									title = " HTML 实时预览 ",
									width = 0.5, -- 占据屏幕宽度的 50%
									height = 0.5, -- 占据屏幕高度的 50%
									keys = {
										q = function()
											stop_html_preview()
											vim.cmd("close")
										end,
									},
								},
								on_exit = function()
									M.html_preview_job = nil
								end,
							}
						)
					end, 200)
					vim.notify("HTML 预览服务器已重置", vim.log.levels.INFO)
				end,
				desc = "HTML 实时预览",
			},
			-- 停止所有运行任务
			{
				"<leader>rs",
				function()
					stop_html_preview()
					vim.fn.jobstart({ "pkill", "-f", "manage.py runserver" })
					vim.fn.jobstart({ "pkill", "-f", "uvicorn" })
					vim.notify("所有运行任务已停止并清理", vim.log.levels.WARN)
				end,
				desc = "停止所有任务",
			},
			-- Python 一键运行
			{
				"<leader>rp",
				function()
					local file = vim.api.nvim_buf_get_name(0)
					require("snacks").terminal.get("python3 '" .. file .. "'", {
						win = { position = "float", border = "rounded" },
					})
				end,
				desc = "运行 Python 脚本",
			},
			-- Django 服务启动
			{
				"<leader>rd",
				function()
					require("snacks").terminal.get("python3 manage.py runserver", {
						win = { position = "float", border = "rounded" },
					})
				end,
				desc = "启动 Django 服务",
			},
			-- FastAPI 服务启动
			{
				"<leader>rf",
				function()
					require("snacks").terminal.get("uvicorn main:app --reload", {
						win = { position = "float", border = "rounded" },
					})
				end,
				desc = "启动 FastAPI 服务",
			},
		},
	},
}
