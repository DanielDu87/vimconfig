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

			-- 初始化UI和虚拟文本
			dapui.setup({
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.5 }, -- 变量查看
							{ id = "stacks", size = 0.3 }, -- 调用堆栈
							{ id = "breakpoints", size = 0.2 }, -- 断点列表
						},
						size = 40,
						position = "right", -- 移动到右侧
					},
					{
						elements = {
							{ id = "repl", size = 0.3 }, -- REPL相对大小
						},
						size = 5, -- REPL实际高度（5行）
						position = "bottom",
					},
					{
						elements = {
							{ id = "console", size = 0.7 }, -- Console相对大小
						},
						size = 10, -- Console实际高度（10行）
						position = "bottom",
					},
				},
				controls = {
					enabled = true,
					element = "repl", -- 调试控制按钮仍在 REPL 面板
				},
				floating = {
					border = "rounded",
					max_height = 0.9,
					max_width = 0.5,
					-- 移除浮动窗口的特定映射，因为现在它们是固定面板
					mappings = {},
					elements = {},
				},
			})
			require("nvim-dap-virtual-text").setup()

			-- 自动开关UI面板
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
				-- 保护目录树宽度：在 UI 弹出后，强制恢复一次目录树的原始宽度
				vim.schedule(function()
					local width_file = vim.fn.stdpath("config") .. "/.explorer_width"
					local f = io.open(width_file, "r")
					local target_width = 30
					if f then
						target_width = tonumber(f:read("*a")) or 30
						f:close()
					end

					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						if vim.bo[buf].filetype == "snacks_explorer" then
							vim.api.nvim_win_set_width(win, target_width)
						end
					end
				end)
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
