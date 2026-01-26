--==============================================================================
-- 前端JS/TS/Vue调试配置
--==============================================================================

return {
	{
		"mfussenegger/nvim-dap",
		opts = function()
			local dap = require("dap")

			-- 获取Mason安装的js-debug-adapter路径
			local js_debug_path = vim.fn.stdpath("data")
				.. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

			local adapter_config = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = { js_debug_path, "${port}" },
				},
			}

			dap.adapters["pwa-node"] = adapter_config
			dap.adapters["pwa-chrome"] = adapter_config

			-- 为所有前端语言配置调试
			for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" }) do
				dap.configurations[lang] = {
					-- 1. 启动当前Node文件
					{
						type = "pwa-node",
						request = "launch",
						name = "Node: 启动当前文件",
						program = "${file}",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
					},
					-- 2. 附加到Node进程
					{
						type = "pwa-node",
						request = "attach",
						name = "Node: Attach进程",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
					-- 3. 调试Chrome（需要Chrome以--remote-debugging-port=9222启动）
					{
						type = "pwa-chrome",
						request = "attach",
						name = "Chrome: Attach（9222）",
						program = "${file}",
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						port = 9222,
						webRoot = "${workspaceFolder}",
					},
				}
			end
		end,
	},
}
