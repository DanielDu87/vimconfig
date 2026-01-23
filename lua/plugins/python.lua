--==============================================================================
-- Python 开发增强配置 (Venv Selector)
--==============================================================================
-- 作用：自定义 Python 虚拟环境的搜索路径

return {
	{
		"linux-cultist/venv-selector.nvim",
        keys = {
            { "<leader>cv", false }, -- 禁用原快捷键
            { "<leader>rv", "<cmd>VenvSelect<cr>", desc = "选择虚拟环境 (Python)" },
        },
		opts = function(_, opts)
		        			-- 综合模式：既看本地，也看全局
		        			opts.search = {
		        				-- 1. 您的自定义全局仓库
		        				my_envs = {
		        					command = "fd 'bin/python$' /Users/dyx/Code/0.python-venv --full-path --color never",
				},
			}
			-- 禁用项目本地搜索
			opts.cache = {
				enable = false,
			}
			return opts
		end,
	},
}
