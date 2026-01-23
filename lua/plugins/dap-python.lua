--==============================================================================
-- Python/Django调试配置
--==============================================================================

return {
	{
		"mfussenegger/nvim-dap",
		opts = function()
			local dap = require("dap")

			-- 获取Mason安装的debugpy路径
			local mason_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"

			dap.adapters.python = {
				type = "executable",
				command = mason_path,
				args = { "-m", "debugpy.adapter" },
			}

			dap.configurations.python = {
				-- 1. 调试当前Python文件
				{
					type = "python",
					request = "launch",
					name = "Python: 当前文件",
					program = "${file}",
					console = "integratedTerminal",
					justMyCode = true,
				},
				-- 2. 调试Django (manage.py runserver)
				{
					type = "python",
					request = "launch",
					name = "Django: runserver",
					program = "${workspaceFolder}/manage.py",
					args = { "runserver", "0.0.0.0:8000" },
					django = true,
					console = "integratedTerminal",
					justMyCode = false,
					env = {
						DJANGO_SETTINGS_MODULE = "config.settings", -- 默认常用路径，可根据项目修改
					},
				},
				-- 3. 附加到运行中的调试进程
				{
					type = "python",
					request = "attach",
					name = "Python: Attach (5678)",
					connect = { host = "127.0.0.1", port = 5678 },
					justMyCode = false,
				},
			}
		end,
	},
}
