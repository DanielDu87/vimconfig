--==============================================================================
-- 语法高亮和视觉增强插件
--==============================================================================
-- 本文件配置所有与语法高亮、颜色显示相关的插件

return {

	-------------------------------------------------------------------------
	-- Treesitter（核心语法高亮引擎）
	-------------------------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			-- 启用所有核心功能
			highlight = {
				enable = true, -- 启用语法高亮
				additional_vim_regex_highlighting = false,
			},

			-- 增量选择
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<CR>",
					node_incremental = "<CR>",
					scope_incremental = "<TAB>",
					node_decremental = "<S-TAB>",
				},
			},

			-- 缩进
			indent = {
				enable = true,
			},

			-- 确保安装前端和 Python 相关的 parser
			ensure_installed = {
				-- 前端
				"html",
				"css",
				"javascript",
				"typescript",
				"tsx",
				"json",
				"jsonc",
				"yaml",

				-- Python
				"python",

				-- 基础
				"lua",
				"vim",
				"vimdoc",
				"query",
				"regex",

				-- 常用
				"bash",
				"markdown",
				"markdown_inline",
				"dockerfile",
			},
		},
	},

	-------------------------------------------------------------------------
	-- Treesitter 文本对象（更好的文本操作）
	-------------------------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
				},
				swap = {
					enable = true,
				},
				move = {
					enable = true,
				},
			},
		},
	},

	-------------------------------------------------------------------------
	-- 上下文显示（显示当前函数/类名）
	-------------------------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {
			enable = true,
			max_lines = 3, -- 最多显示 3 行上下文
		},
	},

	-------------------------------------------------------------------------
	-- 自动闭合标签（HTML/JSX/Vue 等）
	-------------------------------------------------------------------------
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = {},
	},

	-------------------------------------------------------------------------
	-- 彩虹括号（不同层级的括号不同颜色）
	-------------------------------------------------------------------------
	{
		"hiphish/rainbow-delimiters.nvim",
		event = "BufRead",
		config = function()
			local rainbow_delimiters = require("rainbow-delimiters")

			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rainbow_delimiters.strategy["global"],
					vim = rainbow_delimiters.strategy["local"],
				},
				query = {
					[""] = "rainbow-delimiters",
					lua = "rainbow-blocks",
				},
			}
		end,
	},

	-------------------------------------------------------------------------
	-- 颜色代码高亮（显示 #ffffff 等颜色）
	-------------------------------------------------------------------------
	{
		"brenoprata10/nvim-highlight-colors",
		event = "BufReadPost",
		opts = {
			render = "background", -- 或 'foreground' 或 'virtual'
			enable_named_colors = true,
			enable_tailwind = true,
			exclude_buftypes = { "nofile", "prompt" }, -- 禁用补全菜单的高亮，解决“文字带背景”问题
		},
	},

	-------------------------------------------------------------------------
	-- 缩进参考线（LazyVim 已内置，这里自定义配置）
	-------------------------------------------------------------------------
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = "BufRead",
		opts = {
			indent = {
				char = "│",
				tab_char = "│",
			},
			scope = {
				enabled = true,
				show_start = true,
				show_end = true,
			},
			exclude = {
				filetypes = {
					"help",
					"alpha",
					"dashboard",
					"snacks_explorer",
					"Trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
				},
			},
		},
	},

	-------------------------------------------------------------------------
	-- 高亮 Yank（复制时高亮选中的文本）
	-------------------------------------------------------------------------
	-- LazyVim 已经内置此功能，无需额外配置
	-- 可以在 lua/config/autocmds.lua 中启用

	-------------------------------------------------------------------------
	-- 匹配的括号高亮
	-------------------------------------------------------------------------
	-- LazyVim 已经内置此功能，无需额外配置
}

--==============================================================================
-- 功能说明
--==============================================================================
--
-- 🎨 本配置提供的所有高亮相关功能：
--
-- 1. Treesitter 核心功能
--    - 高级语法高亮（比传统 regex 更准确）
--    - 支持增量选择（智能选择代码块）
--    - 自动缩进
--    - 语法文本对象（选择函数、类、参数等）
--
-- 2. 前端高亮
--    - HTML 标签和属性
--    - CSS 选择器和属性
--    - JavaScript/TypeScript 语法
--    - JSX/TSX 支持
--    - 自动闭合标签
--
-- 3. Python 高亮
--    - 关键字、字符串、注释
--    - 函数和类定义
--    - 装饰器
--    - 类型注解
--
-- 4. Docker 高亮
--    - Dockerfile 语法
--    - docker-compose 语法
--
-- 5. 视觉增强
--    - 彩虹括号（不同层级不同颜色）
--    - 颜色代码预览（#fff, rgb() 等）
--    - Tailwind CSS 类名颜色预览
--    - 缩进参考线
--    - 当前代码上下文显示
--
-- 📦 已确保安装的 Treesitter parsers:
--   前端: html, css, javascript, typescript, tsx, json, yaml
--   后端: python, lua
--   其他: bash, markdown, vim, regex, dockerfile
