--==============================================================================
-- DAP 核心配置：调试适配器协议客户端与 UI
--==============================================================================

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"williamboman/mason.nvim",
			"jay-babu/mason-nvim-dap.nvim",
			"nvim-neotest/nvim-nio", -- dap-ui 必需
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- 配置 Mason-DAP 自动安装适配器
			require("mason-nvim-dap").setup({
				automatic_setup = true,
				ensure_installed = {
					"debugpy", -- Python
					"js-debug-adapter", -- JS/TS
				},
			})

			-- 初始化 UI 和 虚拟文本
			dapui.setup()
			require("nvim-dap-virtual-text").setup()

			-- 自动开关 UI 面板
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- 自定义断点图标
			vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "DapStopped", linehl = "Visual", numhl = "DapStopped" })
		end,
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "切换断点",
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
