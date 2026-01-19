--==============================================================================
-- Editor 插件配置
--==============================================================================
-- 覆盖 LazyVim 默认编辑器插件设置

--==============================================================================
-- Helper 函数：打开 Snacks 行搜索（无预览，纯列表，普通字符串搜索）
--==============================================================================
local function snacks_lines()
	local ok, Snacks = pcall(require, "snacks")
	if not ok or not Snacks then
		vim.notify("snacks not available", vim.log.levels.ERROR)
		return
	end

	-- 普通字符串搜索（无模糊匹配，无正则）
	Snacks.picker("lines", {
		layout = {
			preset = "select",
		},
		matcher = {
			fuzzy = false, -- 禁用模糊匹配
		},
		-- 自定义格式：显示行号和文本
		format = function(item)
			return {
				{ tostring(item.idx) .. " ", "LineNr" },
				{ item.text },
			}
		end,
	})
end

return {
	--==============================================================================
	-- which-key.nvim 配置 - 自定义样式 + 中文化
	--==============================================================================
	{
		"folke/which-key.nvim",
		---@diagnostic disable-next-line: missing-fields
		opts = {
			win = {
				width = 0.75,
				height = { min = 4, max = math.huge },
				col = 0.5,
				row = 0.8,
				border = "rounded",
				title = "  ◈ 操作菜单 ◈  ",
				title_pos = "center",
				padding = { 1, 2 },
				no_overlap = false,
				wo = {
					conceallevel = 0,
				},
			},
			spec = {
				{ "<leader><tab>", group = "标签页" },
				{ "<leader>/", desc = "文件内容查找" },
				{ "<leader>c", group = "代码" },
				{ "<leader>d", group = "调试" },
				{ "<leader>dp", group = "性能分析" },
				{ "<leader>f", group = "文件/查找" },
				{ "<leader>g", group = "Git" },
				{ "<leader>gh", group = "变更" },
				{ "<leader>q", group = "退出/会话" },
				{ "<leader>s", group = "搜索" },
				{ "<leader>S", group = "临时缓冲区" },
				{ "<leader>Ss", desc = "打开默认临时缓冲区" },
				{ "<leader>Sn", desc = "新建命名临时缓冲区" },
				{ "<leader>SS", desc = "选择/管理临时缓冲区" },
				{ "<leader>u", group = "界面" },
				{ "<leader>x", group = "诊断/修复" },
				{ "[", group = "上一个" },
				{ "]", group = "下一个" },
				{ "g", group = "跳转" },
				{ "gs", group = "环绕" },
				{ "z", group = "折叠" },
				{ "<leader>b", group = "缓冲区" },
				{ "<leader>w", group = "窗口" },
			},
			replace = {
				desc = {
					{ "Keywordprg", "关键词查询" },
					{ "Explorer", "文件浏览器" },
					{ "Notification History", "通知历史" },
					{ "Buffers", "缓冲区列表" },
					{ "Git Diff", "Git 差异" },
					{ "Git Status", "Git 状态" },
					{ "Git Stash", "Git 暂存" },
					{ "GitHub Issues", "GitHub 问题" },
					{ "GitHub Pull Requests", "GitHub 拉取请求" },
					{ "Recent", "最近文件" },
					{ "Projects", "项目列表" },
					{ "Command History", "命令历史" },
					{ "Buffer Lines", "缓冲区行" },
					{ "Grep Open Buffers", "搜索已打开缓冲区" },
					{ "Search for Plugin Spec", "搜索插件配置" },
					{ "Visual selection or word", "选区或单词" },
					{ "Registers", "寄存器" },
					{ "Search History", "搜索历史" },
					{ "Autocmds", "自动命令" },
					{ "Commands", "命令" },
					{ "Diagnostics", "诊断信息" },
					{ "Buffer Diagnostics", "缓冲区诊断" },
					{ "Help Pages", "帮助文档" },
					{ "Highlights", "高亮组" },
					{ "Icons", "图标" },
					{ "Jumps", "跳转列表" },
					{ "Keymaps", "快捷键映射" },
					{ "Location List", "位置列表" },
					{ "Man Pages", "手册页" },
					{ "Marks", "标记" },
					{ "Resume", "恢复上一次" },
					{ "Quickfix List", "快速修复列表" },
					{ "Undotree", "撤销树" },
					{ "Colorschemes", "配色方案" },
					{ "Todo", "待办事项" },
					{ "LSP Symbols", "LSP 符号" },
					{ "LSP Workspace Symbols", "LSP 工作区符号" },
					{ "Goto Definition", "跳转到定义" },
					{ "Goto Implementation", "跳转到实现" },
					{ "Select Scratch Buffer", "选择临时缓冲区" },
				},
			},
		},
	},

	--==============================================================================
	-- Snacks.nvim 统一配置
	--==============================================================================
	{
		"snacks.nvim",
		---@diagnostic disable-next-line: missing-fields
		keys = {
			--======================================================================
			-- Explorer 键位
			--======================================================================
			{
				"<leader>fe",
				function()
					Snacks.explorer({ cwd = LazyVim.root() })
				end,
				desc = "文件浏览器 (根目录)",
			},
			{
				"<leader>fE",
				function()
					Snacks.explorer()
				end,
				desc = "文件浏览器 (当前目录)",
			},
			{
				"<leader>e",
				"<leader>fe",
				desc = "文件浏览器",
				remap = true,
			},
			{
				"<leader>E",
				false,
			},

			--======================================================================
			-- 临时缓冲区 (Scratch) 操作
			--======================================================================
			{
				"<leader>Ss",
				function()
					Snacks.scratch({ ft = "" })
				end,
				desc = "打开默认临时缓冲区",
			},
			{
				"<leader>Sn",
				function()
					Snacks.scratch({ name = vim.fn.input("名称: "), ft = "" })
				end,
				desc = "新建命名临时缓冲区",
			},
			{
				"<leader>SS",
				function()
					Snacks.picker.scratch()
				end,
				desc = "选择/管理临时缓冲区",
			},

			--======================================================================
			-- 当前文件搜索 - / 和 ? 键
			--======================================================================
			{
				"/",
				snacks_lines,
				desc = "当前文件搜索",
				mode = { "n", "v" },
			},
			{
				"?",
				snacks_lines,
				desc = "当前文件搜索",
				mode = { "n", "v" },
			},
		},

		--==========================================================================
		-- Snacks.nvim opts 配置
		--==========================================================================
		opts = function(_, opts)
			--======================================================================
			-- Scratch 全局配置：默认不设置 filetype
			--======================================================================
			opts.scratch = { ft = "" }

			--======================================================================
			-- Picker 全局配置
			--======================================================================
			opts.picker = opts.picker or {}

			-- 清空提示符
			opts.picker.prompt = ""

			-- 添加清除选择的动作
			opts.picker.actions = opts.picker.actions or {}
			opts.picker.actions.list_clear_selected = function(picker)
				picker.list:set_selected({})
			end

			opts.picker.win = opts.picker.win or {}

			-- 输入框配置（居中显示）
			opts.picker.win.input = {
				row = 0.3,
				height = 1,
				width = 0.6,
				col = 0.2,
				border = "rounded",
				wo = {
					statuscolumn = "",
					signcolumn = "no",
				},
			}

			-- 列表窗口配置 - 禁用左侧列防止内容被遮挡
			opts.picker.win.list = {
				border = "rounded",
				wo = {
					statuscolumn = "",
					signcolumn = "no",
					number = false,
					foldcolumn = "0",
					conceallevel = 0,
				},
				keys = {
					-- Esc 清除多选，不关闭 picker
					["<Esc>"] = { "list_clear_selected", mode = "n" },
				},
			}

			-- 预览窗口配置
			opts.picker.win.preview = {
				border = "rounded",
			}

			--======================================================================
			-- 源特定配置 - Command History 边框修复 + Scratch 删除快捷键
			--======================================================================
			opts.picker.sources = opts.picker.sources or {}

			-- Scratch picker 配置：确保删除快捷键生效 + 显示提示
			opts.picker.sources.scratch = {
				title = "Scratch [<C-x>删除 <C-n>新建]",
				win = {
					input = {
						keys = {
							["<c-x>"] = { "scratch_delete", mode = { "n", "i" } },
							["<c-n>"] = { "scratch_new", mode = { "n", "i" } },
						},
					},
				},
			}

			-- 覆盖 command_history 布局，使用 custom 布局预设添加完整边框
			opts.picker.sources.command_history = {
				layout = {
					preset = "custom",
					-- 自定义布局：基于 vscode，但使用完整边框
					layout = {
						backdrop = false,
						row = 1,
						width = 0.4,
						min_width = 80,
						height = 0.4,
						border = "none",
						box = "vertical",
						{ win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
						{ win = "list", border = "rounded" },
					},
				},
			}

			return opts
		end,
	},
}
