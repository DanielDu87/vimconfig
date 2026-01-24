--==============================================================================
-- DAP核心配置：调试适配器协议客户端与UI
--==============================================================================

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"mason-org/mason.nvim",
			"jay-babu/mason-nvim-dap.nvim",
			"nvim-neotest/nvim-nio", -- dap-ui必需
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- 配置Mason-DAP自动安装适配器
			require("mason-nvim-dap").setup({
				automatic_setup = true,
				ensure_installed = {
					"debugpy", -- Python
					"js-debug-adapter", -- JS/TS
				},
			})

			-- 布局文件路径
			local layout_file = vim.fn.stdpath("config") .. "/.dapui_layout"

			-- 标志位：是否正在恢复布局（防止恢复时触发保存）
			local is_restoring = false

			-- 读取布局数据
			local function load_layout_data()
				local f = io.open(layout_file, "r")
				if f then
					local content = f:read("*a")
					f:close()
					local ok, decoded = pcall(vim.json.decode, content)
					if ok and decoded then
						return decoded
					end
				end
				return nil
			end

			-- 计算初始布局尺寸
			local function get_initial_sizes()
				local data = load_layout_data() or {}
				local sidebar_width = 40 -- 默认值
				local bottom_height = 15 -- 默认值

				-- Sidebar: 尝试获取 dapui_scopes 的宽度
				if data.dapui_scopes and data.dapui_scopes.width then
					sidebar_width = data.dapui_scopes.width
				elseif data.dapui_stacks and data.dapui_stacks.width then
					sidebar_width = data.dapui_stacks.width
				end

				-- Bottom: 尝试获取 dapui_console + dapui_repl 的总高度
				-- 如果数据中只存在一个，则只用一个；如果都存在，则累加（假设为上下堆叠）
				local console_h = (data.dapui_console and data.dapui_console.height) or 0
				local repl_h = (data.dapui_repl and data.dapui_repl.height) or 0
				
				if console_h > 0 or repl_h > 0 then
					-- 在默认布局中，Repl 和 Console 通常是上下堆叠的，所以初始总高度应为两者之和
					-- 如果只显示了一个，则为该窗口高度
					bottom_height = console_h + repl_h
					-- 增加一点余量防止计算误差导致过小
					if bottom_height < 5 then bottom_height = 15 end
				end
				
				return sidebar_width, bottom_height
			end

			local init_sidebar_w, init_bottom_h = get_initial_sizes()

			-- 保存布局逻辑（防抖）
			local save_timer = nil
			local function save_layout_debounced()
				if is_restoring then return end

				if save_timer then
					save_timer:stop()
					save_timer:close()
				end
				save_timer = vim.loop.new_timer()
				save_timer:start(500, 0, vim.schedule_wrap(function()
					if is_restoring then return end

					local current_data = load_layout_data() or {}
					local windows = vim.api.nvim_list_wins()
					local found_dap = false

					for _, win in ipairs(windows) do
						local buf = vim.api.nvim_win_get_buf(win)
						local ft = vim.bo[buf].filetype or ""

						if ft:match("^dapui_") then
							found_dap = true
							local w = vim.api.nvim_win_get_width(win)
							local h = vim.api.nvim_win_get_height(win)
							
							-- 保存每个组件的宽高
							current_data[ft] = { width = w, height = h }
						end
					end

					if found_dap then
						local f_write = io.open(layout_file, "w")
						if f_write then
							f_write:write(vim.json.encode(current_data))
							f_write:close()
							-- 静默保存，不发送通知
						end
					end
				end))
			end

			-- 监听窗口大小变化
			vim.api.nvim_create_autocmd("WinResized", {
				pattern = "*",
				callback = function()
					if is_restoring then return end
					
					-- 只有当存在 DAP UI 窗口时才触发保存
					local has_dap_win = false
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						local ft = vim.bo[buf].filetype or ""
						if ft:match("^dapui_") then
							has_dap_win = true
							break
						end
					end
					
					if has_dap_win then
						save_layout_debounced()
					end
				end,
			})

			dapui.setup({
				layouts = {
					-- 1. 右侧面板 (变量、堆栈、断点)
					{
						elements = {
							{ id = "scopes", size = 0.5 }, 
							{ id = "stacks", size = 0.3 }, 
							{ id = "breakpoints", size = 0.2 },
						},
						size = init_sidebar_w, -- 使用计算出的初始宽度
						position = "right",
					},
					-- 2. 底部面板：REPL和Console
					{
						elements = {
							{ id = "repl", size = 0.3 }, 
							{ id = "console", size = 0.7 },
						},
						size = init_bottom_h, -- 使用计算出的初始高度
						position = "bottom",
					},
				},
				controls = {
					enabled = true,
					element = "repl",
				},
				floating = {
					border = "rounded",
					max_height = 0.9,
					max_width = 0.5,
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
			})
			require("nvim-dap-virtual-text").setup()

			-- 自动开关UI面板及布局恢复
			dap.listeners.after.event_initialized["dapui_config"] = function()
				is_restoring = true
				dapui.open()

				-- 立即尝试恢复（减少视觉跳变）
				local function apply_layout_now()
					local data = load_layout_data()
					if not data then return end
					local windows = vim.api.nvim_list_wins()
					for _, win in ipairs(windows) do
						local buf = vim.api.nvim_win_get_buf(win)
						local ft = vim.bo[buf].filetype or ""
						if data[ft] then
							pcall(vim.api.nvim_win_set_width, win, data[ft].width)
							pcall(vim.api.nvim_win_set_height, win, data[ft].height)
						end
					end
				end
				apply_layout_now() -- 同步执行一次

				local function restore_layout()
					local data = load_layout_data()
					if not data then return end

					local windows = vim.api.nvim_list_wins()
					
					-- 1. 先应用尺寸调整 (微调内部比例)
					for _, win in ipairs(windows) do
						local buf = vim.api.nvim_win_get_buf(win)
						local ft = vim.bo[buf].filetype or ""

						if data[ft] then
							-- 尝试恢复宽度和高度
							-- 注意：在 Split 布局中，设置宽度可能会影响同一列的其他窗口，
							-- 设置高度可能会影响同一行的其他窗口。
							-- 我们尽力而为。
							pcall(vim.api.nvim_win_set_width, win, data[ft].width)
							pcall(vim.api.nvim_win_set_height, win, data[ft].height)
						end
					end

					-- 2. 保护 Explorer 宽度 (如果存在)
					for _, win in ipairs(windows) do
						local buf = vim.api.nvim_win_get_buf(win)
						if vim.bo[buf].filetype == "snacks_explorer" then
							local width_file = vim.fn.stdpath("config") .. "/.explorer_width"
							local f = io.open(width_file, "r")
							local target_width = 30
							if f then
								target_width = tonumber(f:read("*a")) or 30
								f:close()
							end
							pcall(vim.api.nvim_win_set_width, win, target_width)
						end
					end
				end

				-- 延迟执行以确保 UI 渲染完成
				vim.defer_fn(restore_layout, 100)
				vim.defer_fn(restore_layout, 300)
				
				-- 恢复完成后，重置标志位 (延时稍长一点，避开初始震荡)
				vim.defer_fn(function()
					is_restoring = false
				end, 800)
			end

			-- 调试结束时保存布局
			dap.listeners.after.event_terminated["dapui_config"] = function()
				save_layout_debounced()
			end

			-- 自定义断点图标
			vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "DapStopped", linehl = "Visual", numhl = "DapStopped" })
		end,
		keys = {
			{
				"<leader>db",
				function()
					require("persistent-breakpoints.api").toggle_breakpoint()
				end,
				desc = "切换断点(持久化)",
			},
			{
				"<leader>dB",
				function()
					require("persistent-breakpoints.api").set_conditional_breakpoint()
				end,
				desc = "条件断点(持久化)",
			},
			{
				"<leader>dC",
				function()
					require("persistent-breakpoints.api").clear_all_breakpoints()
				end,
				desc = "清除所有断点(持久化)",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "开始/继续调试",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "步入 (Into)",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "步过 (Over)",
			},
			{
				"<leader>du",
				function()
					require("dap").step_out()
				end,
				desc = "步出 (Out)",
			},
			{
				"<leader>dt",
				function()
					require("dapui").toggle()
				end,
				desc = "切换调试面板",
			},
		},
	},
}