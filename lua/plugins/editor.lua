--==============================================================================
-- Editor 插件配置
--==============================================================================
-- 覆盖 LazyVim 默认编辑器插件设置

--==============================================================================
-- 覆盖 LazyVim 默认快捷键（重新组织）
--==============================================================================
vim.api.nvim_create_autocmd("User", {
	pattern = "LazyVimKeymaps",
	callback = function()
		-- 窗口分割快捷键移到 <leader>w 组
		vim.keymap.del("n", "<leader>-")
		vim.keymap.del("n", "<leader>|")
		-- Toggle Scratch Buffer 移到 <leader>S 组
		vim.keymap.del("n", "<leader>.")
		-- 缓冲区快捷键重新组织
		vim.keymap.del("n", "<leader>`")
		vim.keymap.del("n", "<leader>,")
	end,
})

--==============================================================================
-- 覆盖 <leader>bP：关闭非 pinned 缓冲区，保持 snacks_picker_list 宽度
--==============================================================================
vim.api.nvim_create_autocmd("User", {
	pattern = "LazyVimKeymaps",
	callback = function()
		local SIDE_FT = "snacks_picker_list"

		local function find_side_wins()
			local wins = {}
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].filetype == SIDE_FT then
					wins[#wins + 1] = win
				end
			end
			return wins
		end

		local function snapshot_side_width()
			local wins = find_side_wins()
			if #wins == 0 then
				return nil
			end
			return vim.api.nvim_win_get_width(wins[1])
		end

		local function set_side_fixed_width(on)
			for _, win in ipairs(find_side_wins()) do
				vim.wo[win].winfixwidth = on
			end
		end

		local function restore_side_width(width)
			if not width then
				return
			end
			for _, win in ipairs(find_side_wins()) do
				pcall(vim.api.nvim_win_set_width, win, width)
			end
		end

		local function get_pinned_buffers()
			local pinned = {}

			local ok_groups, groups = pcall(require, "bufferline.groups")
			local ok_state, state = pcall(require, "bufferline.state")

			if not ok_groups or not ok_state or not state.components then
				return pinned
			end

			-- 使用 bufferline groups 模块的 _is_pinned 方法
			for _, element in ipairs(state.components) do
				if groups._is_pinned(element) then
					pinned[element.id] = true
				end
			end

			return pinned
		end

		local function close_non_pinned_buffers_preserve_side_width()
			local side_width = snapshot_side_width()

			-- 获取 pinned buffers
			local pinned = get_pinned_buffers()
			local pinned_count = 0
			for _ in pairs(pinned) do
				pinned_count = pinned_count + 1
			end

			-- 锁住左侧宽度 + 避免均分
			set_side_fixed_width(true)
			local ea = vim.o.equalalways
			vim.o.equalalways = false

			-- 关闭所有非 pinned buffers（包括当前缓冲区）
			local keep = pinned

			local snacks = require("snacks")
			for _, b in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(b)
					and vim.api.nvim_get_option_value("buflisted", { buf = b })
					and vim.bo[b].buftype == ""
					and not keep[b]
				then
					snacks.bufdelete(b)
				end
			end

			vim.o.equalalways = ea

			-- 多次回写宽度
			vim.schedule(function()
				restore_side_width(side_width)
				vim.defer_fn(function() restore_side_width(side_width) end, 50)
				vim.defer_fn(function() restore_side_width(side_width) end, 150)
				vim.defer_fn(function()
					restore_side_width(side_width)
					set_side_fixed_width(false)
				end, 300)
			end)

			vim.notify(string.format("已关闭，保留了 %d 个固定缓冲区", pinned_count), vim.log.levels.INFO)
		end

		-- 覆盖 <leader>bP
		vim.keymap.set("n", "<leader>bP", close_non_pinned_buffers_preserve_side_width, {
			desc = "关闭非 pinned 缓冲区（保持侧边栏宽度）",
		})
	end,
})

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
			layout = {
				columns = 8,
			},
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
				{ "<leader><tab>", group = "标签页", icon = "🏷️" },
				{ "<leader><space>", desc = "查找文件", icon = "🔍" },
				{ "<leader>/", desc = "文件内容查找", icon = "🔍" },
				{ "<leader>?", desc = "Buffer快捷键查询", icon = "⌨️" },
				-- 隐藏默认的窗口分割快捷键（已移到 <leader>w 组中）
				{ "<leader>-", desc = "which_key_ignore" },
				{ "<leader>|", desc = "which_key_ignore" },
				-- 隐藏 Toggle Scratch Buffer（已移到 <leader>S 组中）
				{ "<leader>.", desc = "which_key_ignore" },
				-- 隐藏 Switch to Other Buffer（移到 <leader>b 组中）
				{ "<leader>`", desc = "which_key_ignore" },
				-- 隐藏 Buffers（移到 <leader>bf 中）
				{ "<leader>,", desc = "which_key_ignore" },
				-- 按字母分组，大小写放在一起
				{ "<leader>b", group = "缓冲区", icon = "🗂️" },
				{ "<leader>bb", desc = "切换到其他缓冲区", icon = "🔄" },
				{ "<leader>bd", desc = "关闭当前缓冲区", icon = "❌" },
				{ "<leader>bD", desc = "关闭缓冲区和窗口", icon = "❌" },
				{ "<leader>bf", desc = "缓冲区列表", icon = "📋" },
				{ "<leader>bh", desc = "上一个缓冲区", icon = "⬅️" },
				{ "<leader>bl", desc = "下一个缓冲区", icon = "➡️" },
				{ "<leader>bo", desc = "关闭其他缓冲区", icon = "🗑️" },
				{ "<leader>bp", desc = "切换固定", icon = "📌" },
				{ "<leader>c", group = "代码", icon = "🛠️" },
				{ "<leader>d", group = "调试", icon = "🔧" },
				{ "<leader>dp", group = "性能分析", icon = "📊" },
				{ "<leader>e", group = "文件浏览器", icon = "📂" },
				{ "<leader>f", group = "文件/查找", icon = "📁" },
				{ "<leader>ff", desc = "查找文件", icon = "🔍" },
				{ "<leader>g", group = "Git", icon = "🧡" },
				{ "<leader>gh", group = "变更", icon = "🔄" },
				{ "<leader>h", group = "历史", icon = "📜" },
				{ "<leader>hn", desc = "通知历史", icon = "🔔" },
				{ "<leader>hc", desc = "命令历史", icon = "💬" },
				{ "<leader>hs", desc = "搜索历史", icon = "🔍" },
				{ "<leader>H", desc = "切换显示隐藏文件", icon = "👁️" },
				{ "<leader>k", desc = "查询DevDocs（当前关键词）", icon = "📚" },
				{ "<leader>K", desc = "搜索DevDocs (输入查询)", icon = "📚" },
				{ "<leader>l", desc = "插件管理器", icon = "🧩" },
				{ "<leader>L", desc = "Lazy更新历史", icon = "📜" },
				{ "<leader>q", group = "退出/会话", icon = "🚪" },
				{ "<leader>s", group = "搜索", icon = "🔍" },
				{ "<leader>S", group = "临时缓冲区", icon = "📝" },
				{ "<leader>Ss", desc = "打开默认临时缓冲区" },
				{ "<leader>Sn", desc = "新建命名临时缓冲区" },
				{ "<leader>S.", desc = "打开默认临时缓冲区" },
				{ "<leader>SS", desc = "选择/管理临时缓冲区" },
				{ "<leader>u", group = "界面", icon = "🎨" },
				{ "<leader>w", group = "窗口", icon = "🖼️" },
				{ "<leader>w-", desc = "向下分割窗口" },
				{ "<leader>w|", desc = "向右分割窗口" },
				{ "<leader>wd", desc = "关闭当前窗口" },
				{ "<leader>wh", desc = "切换到左侧窗口" },
				{ "<leader>wj", desc = "切换到下方窗口" },
				{ "<leader>wk", desc = "切换到上方窗口" },
				{ "<leader>wl", desc = "切换到右侧窗口" },
				{ "<leader>wH", desc = "向左移动窗口" },
				{ "<leader>wJ", desc = "向下移动窗口" },
				{ "<leader>wK", desc = "向上移动窗口" },
				{ "<leader>wL", desc = "向右移动窗口" },
				{ "<leader>w=", desc = "均衡窗口大小" },
				{ "<leader>wm", desc = "最大化/恢复窗口" },
				{ "<leader>ww", desc = "切换到其他窗口" },
				{ "<leader>x", group = "诊断/修复", icon = "⚠️" },
				{ "[", group = "上一个", icon = "⬆️" },
				{ "]", group = "下一个", icon = "⬇️" },
				{ "g", group = "跳转", icon = "🔗" },
				{ "gs", group = "环绕", icon = "🔁" },
				{ "z", group = "折叠", icon = "📁" },
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
					{ "Buffer Keymaps (which-key)", "Buffer快捷键查询" },
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
					-- 缓冲区相关
					{ "Switch to Other Buffer", "切换到其他缓冲区" },
					{ "Delete Buffer", "关闭当前缓冲区" },
					{ "Delete Buffer and Window", "关闭缓冲区和窗口" },
					{ "Delete Other Buffers", "关闭其他缓冲区" },
					{ "Prev Buffer", "上一个缓冲区" },
					{ "Next Buffer", "下一个缓冲区" },
					-- 窗口相关
					{ "Split Window Below", "向下分割窗口" },
					{ "Split Window Right", "向右分割窗口" },
					{ "Delete Window", "关闭当前窗口" },
					{ "Go to Left Window", "切换到左侧窗口" },
					{ "Go to Lower Window", "切换到下方窗口" },
					{ "Go to Upper Window", "切换到上方窗口" },
					{ "Go to Right Window", "切换到右侧窗口" },
					{ "Increase Window Height", "增加窗口高度" },
					{ "Decrease Window Height", "减少窗口高度" },
					{ "Decrease Window Width", "减少窗口宽度" },
					{ "Increase Window Width", "增加窗口宽度" },
					-- 其他
					{ "Save File", "保存文件" },
					{ "Quit All", "全部退出" },
					{ "Lazy", "插件管理器" },
					{ "Lazy Log", "Lazy更新历史" },
					{ "Open lazygit log", "打开 Lazygit 日志" },
					{ "Vim Changelog", "更新历史" },
					{ "Toggle Pin", "切换固定" },
					{ "Delete Non-Pinned", "关闭未固定缓冲区" },
					{ "Delete", "关闭" },
					{ "Non-Pinned", "非固定" },
					{ "Non", "非" },
					{ "to the Right", "右侧" },
					{ "to the Left", "左侧" },
					{ "Delete Buffers", "关闭缓冲区" },
					{ "Delete Buffers to the Right", "关闭右侧缓冲区" },
					{ "Delete Buffers to the Left", "关闭左侧缓冲区" },
					{ "缓冲区列表", "缓冲区列表" },
					{ "Pinned", "固定" },
					{ "Close", "关闭" },
					{ "Buffers", "缓冲区" },
					{ "Delete Non-Pinned Buffers", "关闭非固定缓冲区" },
					{ "Ungrouped", "未分组" },
					{ "New File", "新建文件" },
					{ "Format", "格式化" },
					{ "Line Diagnostics", "行诊断" },
					{ "Next Diagnostic", "下一个诊断" },
					{ "Prev Diagnostic", "上一个诊断" },
					{ "Next Error", "下一个错误" },
					{ "Prev Error", "上一个错误" },
					{ "Next Warning", "下一个警告" },
					{ "Prev Warning", "上一个警告" },
					{ "Previous Quickfix", "上一个快速修复" },
					{ "Next Quickfix", "下一个快速修复" },
					{ "Next Search Result", "下一个搜索结果" },
					{ "Prev Search Result", "上一个搜索结果" },
					{ "Down", "向下移动" },
					{ "Up", "向上移动" },
					{ "Escape and Clear hlsearch", "取消并清除搜索高亮" },
					{ "Add Comment Below", "在下方添加注释" },
					{ "Add Comment Above", "在上方添加注释" },
					{ "Run Lua", "运行 Lua" },
					-- 文件/查找相关
					{ "Find Files", "查找文件" },
					{ "Find Files (Root Dir)", "查找文件 (根目录)" },
					{ "Recent Files", "最近文件" },
					{ "Current File Search", "当前文件搜索" },
					{ "File Browser", "文件浏览器" },
					{ "File Browser (Root Dir)", "文件浏览器 (根目录)" },
					{ "File Browser (Cwd)", "文件浏览器 (当前目录)" },
					-- 通知相关
					{ "Notifications", "通知" },
					{ "Noice", "通知" },
					{ "Notification History", "通知历史" },
					{ "Dismiss", "清除" },
					{ "Dismiss All", "全部清除" },
					{ "Forward", "转发" },
					{ "Last", "最后一条" },
					{ "Picker (Telescope)", "选择器" },
					{ "All", "全部" },
					{ "Config", "配置" },
					{ "Explorer", "文件浏览器" },
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
				"<leader>S.",
				function()
					Snacks.scratch()
				end,
				desc = "切换临时缓冲区",
			},
			{
				"<leader>SS",
				function()
					Snacks.picker.scratch()
				end,
				desc = "选择/管理临时缓冲区",
			},

			--======================================================================
			-- 缓冲区操作快捷键
			--======================================================================
			{
				"<leader>bb",
				"<cmd>e #<cr>",
				desc = "切换到其他缓冲区",
			},
			{
				"<leader>bh",
				"<cmd>bprevious<cr>",
				desc = "上一个缓冲区",
			},
			{
				"<leader>bl",
				"<cmd>bnext<cr>",
				desc = "下一个缓冲区",
			},
			{
				"<leader>bf",
				function()
					Snacks.picker.buffers()
				end,
				desc = "缓冲区列表",
			},
			-- bd, bD, bo 使用 LazyVim 默认配置

			--======================================================================
			-- 窗口操作快捷键
			--======================================================================
			{
				"<leader>w-",
				"<C-W>s",
				desc = "向下分割窗口",
				remap = true,
			},
			{
				"<leader>w|",
				"<C-W>v",
				desc = "向右分割窗口",
				remap = true,
			},
			{
				"<leader>wd",
				"<C-W>c",
				desc = "关闭当前窗口",
				remap = true,
			},
			{
				"<leader>wh",
				"<C-W>h",
				desc = "切换到左侧窗口",
				remap = true,
			},
			{
				"<leader>wj",
				"<C-W>j",
				desc = "切换到下方窗口",
				remap = true,
			},
			{
				"<leader>wk",
				"<C-W>k",
				desc = "切换到上方窗口",
				remap = true,
			},
			{
				"<leader>wl",
				"<C-W>l",
				desc = "切换到右侧窗口",
				remap = true,
			},
			{
				"<leader>wH",
				"<C-W>H",
				desc = "向左移动窗口",
				remap = true,
			},
			{
				"<leader>wJ",
				"<C-W>J",
				desc = "向下移动窗口",
				remap = true,
			},
			{
				"<leader>wK",
				"<C-W>K",
				desc = "向上移动窗口",
				remap = true,
			},
			{
				"<leader>wL",
				"<C-W>L",
				desc = "向右移动窗口",
				remap = true,
			},
			{
				"<leader>w=",
				"<C-W>=",
				desc = "均衡窗口大小",
				remap = true,
			},
			{
				"<leader>ww",
				"<C-W>w",
				desc = "切换到其他窗口",
				remap = true,
			},
			{
				"<leader>wm",
				function()
					Snacks.toggle.zoom()
				end,
				desc = "最大化/恢复窗口",
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
