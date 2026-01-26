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

			-- 计算初始布局总尺寸（用于 setup）
			local function get_initial_sizes()
				local data = load_layout_data() or {}
				local sidebar_width = 40
				local bottom_height = 15

				if data.dapui_scopes and data.dapui_scopes.width then
					sidebar_width = data.dapui_scopes.width
				end

				local console_h = (data.dapui_console and data.dapui_console.height) or 0
				local repl_h = (data.dapui_repl and data.dapui_repl.height) or 0
				if console_h > 0 or repl_h > 0 then
					bottom_height = console_h + repl_h
					if bottom_height < 5 then bottom_height = 15 end
				end
				
				return sidebar_width, bottom_height
			end

			local init_sidebar_w, init_bottom_h = get_initial_sizes()

			-- 应用保存的尺寸到当前窗口
			local function apply_saved_sizes()
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
					
					-- 保护 Explorer 宽度
					if ft == "snacks_explorer" then
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
							current_data[ft] = {
								width = vim.api.nvim_win_get_width(win),
								height = vim.api.nvim_win_get_height(win)
							}
						end
					end

					if found_dap then
						local f_write = io.open(layout_file, "w")
						if f_write then
							f_write:write(vim.json.encode(current_data))
							f_write:close()
						end
					end
				end))
			end

			-- 监听窗口大小变化
			vim.api.nvim_create_autocmd("WinResized", {
				pattern = "*",
				callback = function()
					if is_restoring then return end
					local has_dap_win = false
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						if (vim.bo[buf].filetype or ""):match("^dapui_") then
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
					{
						elements = {
							{ id = "scopes", size = 0.5 },
							{ id = "stacks", size = 0.3 },
							{ id = "breakpoints", size = 0.2 },
						},
						size = init_sidebar_w,
						position = "right",
					},
					{
						elements = {
							{ id = "repl", size = 0.3 },
							{ id = "console", size = 0.7 },
						},
						size = init_bottom_h,
						position = "bottom",
					},
				},
				controls = { enabled = true, element = "repl" },
				floating = {
					border = "rounded",
					max_height = 0.9,
					max_width = 0.5,
					mappings = { close = { "q", "<Esc>" } },
				},
			})

			-- 配置DAP UI窗口的分割线颜色
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dapui_*",
				callback = function()
					-- 设置DAP窗口的分割线颜色（青蓝色，显眼但不刺眼）
					vim.api.nvim_set_hl(0, "WinSeparator", {
						fg = "#2b85b7", -- 青蓝色
						bg = "NONE",
					})
				end,
			})

			require("nvim-dap-virtual-text").setup()

			-- 自动开关UI面板及布局恢复
			dap.listeners.after.event_initialized["dapui_config"] = function()
				is_restoring = true
				dapui.open()

				-- 1. 立即同步应用尺寸（消除跳变）
				apply_saved_sizes()

				-- 2. 延迟异步应用（确保 UI 渲染稳定后的微调）
				vim.defer_fn(apply_saved_sizes, 100)
				vim.defer_fn(apply_saved_sizes, 300)
				
				-- 3. 恢复完成后重置状态
				vim.defer_fn(function()
					is_restoring = false
				end, 800)
			end

			dap.listeners.after.event_terminated["dapui_config"] = function()
				save_layout_debounced()
			end

			-- 自定义断点图标
			vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DapBreakpoint" })
			vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "DapStopped", linehl = "Visual" })
		end,
		keys = {
			{ "<leader>db", function() require("persistent-breakpoints.api").toggle_breakpoint() end, desc = "切换断点（持久化）" },
			{ "<leader>dB", function() require("persistent-breakpoints.api").set_conditional_breakpoint() end, desc = "条件断点（持久化）" },
			{ "<leader>dC", function() require("persistent-breakpoints.api").clear_all_breakpoints() end, desc = "清除所有断点（持久化）" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "开始/继续调试" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "步入（Into）" },
			{ "<leader>do", function() require("dap").step_over() end, desc = "步过（Over）" },
			{ "<leader>du", function() require("dap").step_out() end, desc = "步出（Out）" },
			{ "<leader>dt", function() require("dapui").toggle() end, desc = "切换调试面板" },
		},
	},
}
