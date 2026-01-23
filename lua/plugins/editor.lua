--==============================================================================
-- Editor 插件配置：覆盖 LazyVim 默认的编辑器行为
--==============================================================================
-- 本文件主要配置：
-- 1. 快捷键重新组织 (将窗口/Buffer操作归类)
-- 2. WhichKey 菜单定制与中文化
-- 3. Snacks.nvim 核心组件配置 (Picker, Explorer, Scratch)

--==============================================================================
-- 1. 快捷键深度定制
--==============================================================================
-- 我们在 LazyVim 加载完默认键位后，通过 autocmd 进行精准覆盖
vim.api.nvim_create_autocmd("User", {
	pattern = "LazyVimKeymaps",
	callback = function()
		-- ---------------------------------------------------------------------------
		-- 窗口管理：统一移到 <leader>w (Windows) 组
		-- ---------------------------------------------------------------------------
		vim.keymap.del("n", "<leader>-") -- 删除默认的横向分割
		vim.keymap.del("n", "<leader>|") -- 删除默认的纵向分割

		-- ---------------------------------------------------------------------------
		-- 临时Buffer：统一移到 <leader>S (Scratch) 组
		-- ---------------------------------------------------------------------------
		vim.keymap.del("n", "<leader>.")

		-- ---------------------------------------------------------------------------
		-- Buffer管理：清理默认的冗余键位
		-- ---------------------------------------------------------------------------
		vim.keymap.del("n", "<leader>`") -- 切换到上一个Buffer
		vim.keymap.del("n", "<leader>,") -- Buffer列表
		vim.keymap.del("n", "<leader>br") -- LazyVim 默认的向右关闭
		vim.keymap.del("n", "<leader>bl") -- LazyVim 默认的向左关闭

		-- 设置更直观的Buffer导航 (小写 h/l)
		vim.keymap.set("n", "<leader>bh", "<cmd>bprevious<cr>", { desc = "上一个Buffer" })
		vim.keymap.set("n", "<leader>bl", "<cmd>bnext<cr>", { desc = "下一个Buffer" })

		-- ---------------------------------------------------------------------------
		-- 辅助函数：批量关闭Buffer逻辑（跳过固定/PinnedBuffer）
		-- ---------------------------------------------------------------------------
		local function get_pinned_set()
			local pinned = {}
			local ok_groups, groups = pcall(require, "bufferline.groups")
			local ok_state, state = pcall(require, "bufferline.state")
			if ok_groups and ok_state and state.components then
				for _, element in ipairs(state.components) do
					if groups._is_pinned(element) then
						pinned[element.id] = true
					end
				end
			end
			return pinned
		end

		-- 关闭当前Buffer左侧所有非固定文件
		local function close_left_non_pinned()
			local current = vim.api.nvim_get_current_buf()
			local bufs = vim.api.nvim_list_bufs()
			local current_idx = 0
			for i, buf in ipairs(bufs) do
				if buf == current then
					current_idx = i
					break
				end
			end
			local pinned = get_pinned_set()
			local snacks = require("snacks")
			local closed = 0
			for i = 1, current_idx - 1 do
				local buf = bufs[i]
				if
					vim.api.nvim_buf_is_valid(buf)
					and vim.api.nvim_get_option_value("buflisted", { buf = buf })
					and vim.bo[buf].buftype == ""
					and not pinned[buf]
				then
					snacks.bufdelete(buf)
					closed = closed + 1
				end
			end
			vim.notify(string.format("已清理左侧%d个Buffer", closed), vim.log.levels.INFO)
		end

		-- 关闭当前Buffer右侧所有非固定文件
		local function close_right_non_pinned()
			local current = vim.api.nvim_get_current_buf()
			local bufs = vim.api.nvim_list_bufs()
			local current_idx = 0
			for i, buf in ipairs(bufs) do
				if buf == current then
					current_idx = i
					break
				end
			end
			local pinned = get_pinned_set()
			local snacks = require("snacks")
			local closed = 0
			for i = current_idx + 1, #bufs do
				local buf = bufs[i]
				if
					vim.api.nvim_buf_is_valid(buf)
					and vim.api.nvim_get_option_value("buflisted", { buf = buf })
					and vim.bo[buf].buftype == ""
					and not pinned[buf]
				then
					snacks.bufdelete(buf)
					closed = closed + 1
				end
			end
			vim.notify(string.format("已清理右侧%d个Buffer", closed), vim.log.levels.INFO)
		end

		-- 关闭除当前Buffer外所有非固定文件
		local function close_other_non_pinned()
			local current = vim.api.nvim_get_current_buf()
			local bufs = vim.api.nvim_list_bufs()
			local pinned = get_pinned_set()
			local snacks = require("snacks")
			local closed = 0
			for _, buf in ipairs(bufs) do
				if
					buf ~= current
					and vim.api.nvim_buf_is_valid(buf)
					and vim.api.nvim_get_option_value("buflisted", { buf = buf })
					and vim.bo[buf].buftype == ""
					and not pinned[buf]
				then
					snacks.bufdelete(buf)
					closed = closed + 1
				end
			end
			vim.notify("已关闭其他Buffer（跳过Pinned）", vim.log.levels.INFO)
		end

		-- 绑定批量关闭键位
		vim.keymap.set("n", "<leader>bH", close_left_non_pinned, { desc = "关闭左侧所有Buffer" })
		vim.keymap.set("n", "<leader>bL", close_right_non_pinned, { desc = "关闭右侧所有Buffer" })
		vim.keymap.set("n", "<leader>bo", close_other_non_pinned, { desc = "关闭其他Buffer" })
	end,
})

--==============================================================================
-- 2. 优化 <leader>bP：关闭非固定文件并锁定侧边栏布局
--==============================================================================
-- 此逻辑专门修复在关闭大量Buffer时，侧边栏（如目录树）被系统均分导致的闪烁和变形
vim.api.nvim_create_autocmd("User", {
	pattern = "LazyVimKeymaps",
	callback = function()
		local SIDE_FT = "snacks_picker_list" -- 目标侧边栏的文件类型

		-- 锁定宽度逻辑
		local function set_side_fixed_width(on)
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].filetype == SIDE_FT then
					vim.wo[win].winfixwidth = on
				end
			end
		end

		local function close_non_pinned_buffers_preserve_side_width()
			-- 1. 获取固定状态
			local pinned = {}
			local ok_groups, groups = pcall(require, "bufferline.groups")
			local ok_state, state = pcall(require, "bufferline.state")
			if ok_groups and ok_state and state.components then
				for _, element in ipairs(state.components) do
					if groups._is_pinned(element) then
						pinned[element.id] = true
					end
				end
			end

			-- 2. 锁定侧边栏，防止窗口抖动
			set_side_fixed_width(true)
			local old_ea = vim.o.equalalways
			vim.o.equalalways = false

			-- 3. 执行删除
			local snacks = require("snacks")
			local count = 0
			for _, b in ipairs(vim.api.nvim_list_bufs()) do
				if
					vim.api.nvim_buf_is_valid(b)
					and vim.api.nvim_get_option_value("buflisted", { buf = b })
					and vim.bo[b].buftype == ""
					and not pinned[b]
				then
					snacks.bufdelete(b)
					count = count + 1
				end
			end

			-- 4. 恢复系统设置
			vim.o.equalalways = old_ea
			vim.schedule(function()
				set_side_fixed_width(false)
			end)

			vim.notify("已关闭所有非Pinned Buffer", vim.log.levels.INFO)
		end

		vim.keymap.set("n", "<leader>bP", close_non_pinned_buffers_preserve_side_width, {
			desc = "清理所有非固定Buffer",
		})
	end,
})

--==============================================================================
-- 3. 辅助功能：当前文件行搜索 (无预览版)
--==============================================================================
local function snacks_lines()
	local ok, Snacks = pcall(require, "snacks")
	if not ok then
		return
	end
	Snacks.picker("lines", {
		layout = { preset = "select" }, -- 采用类似下拉选择的简约布局
		matcher = { fuzzy = false }, -- 禁用模糊匹配，采用精确字符串搜索
		format = function(item)
			return {
				{ tostring(item.idx) .. " ", "LineNr" }, -- 显示行号
				{ item.text }, -- 显示文本内容
			}
		end,
	})
end

return {
	-- ---------------------------------------------------------------------------
	-- Which-Key：快捷键浮窗菜单的美化与翻译
	-- ---------------------------------------------------------------------------
	{
		"folke/which-key.nvim",
		opts = {
			layout = { columns = 8, align = "center" },
			win = {
				width = 0.65,
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
					winhighlight = "Normal:WhichKeyNormal,FloatBorder:WhichKeyBorder",
				},
			},
			-- 分组定义与中文化 (严格还原原始版本)
			spec = {
				{ "<leader><tab>", group = "标签页", icon = "🏷️" },
				{ "<leader><space>", desc = "查找文件", icon = "🔍" },
				{ "<leader>/", desc = "文件内容查找", icon = "🔍" },
				{ "<leader>?", desc = "Buffer快捷键查询", icon = "⌨️" },
				-- 忽略 LazyVim 默认定义的项
				{ "<leader>-", desc = "which_key_ignore" },
				{ "<leader>|", desc = "which_key_ignore" },
				{ "<leader>.", desc = "which_key_ignore" },
				{ "<leader>E", desc = "which_key_ignore" },
				{ "<leader>`", desc = "which_key_ignore" },
				{ "<leader>,", desc = "which_key_ignore" },
				{ "<leader>br", desc = "which_key_ignore" },
				-- 按字母分组，大小写放在一起
				{ "<leader>b", group = "缓冲区", icon = "🗂️" },
				{ "<leader>r", group = "运行", icon = "" },
				{ "<leader>rr", desc = "运行当前文件", icon = "▶️" },
				{ "<leader>rl", desc = "查看日志", icon = "📋" },
				{ "<leader>rs", desc = "停止任务", icon = "🛑" },
				{ "<leader>rv", desc = "选择Python虚拟环境", icon = "🐍" },
				{ "<leader>rV", desc = "选择TS工作区版本", icon = "🏷️" },
				{ "<leader>bb", desc = "切换到其他Buffer", icon = "🔄" },
				{ "<leader>bd", desc = "关闭当前Buffer", icon = "❌" },
				{ "<leader>bD", desc = "关闭Buffer和窗口", icon = "❌" },
				{ "<leader>bf", desc = "Buffer列表", icon = "📋" },
				{ "<leader>bh", desc = "上一个Buffer", icon = "⬅️" },
				{ "<leader>bl", desc = "下一个Buffer", icon = "➡️" },
				{ "<leader>bo", desc = "关闭其他Buffer", icon = "🗑️" },
				{ "<leader>bp", desc = "切换固定", icon = "📌" },
				{ "<leader>bH", desc = "关闭左侧Buffer", icon = "🗑️" },
				{ "<leader>bL", desc = "关闭右侧Buffer", icon = "🗑️" },
				{ "<leader>c", group = "代码", icon = "🛠️" },
				{ "<leader>ca", desc = "代码操作", icon = "💡" },
				{ "<leader>cA", desc = "项目操作", icon = "⚛️" },
				{ "<leader>cc", desc = "运行代码透镜", icon = "💎" },
				{ "<leader>cC", desc = "刷新并显示代码透镜", icon = "🔄" },
				{ "<leader>cd", desc = "显示行诊断信息", icon = "🔍" },
				{ "<leader>cl", desc = "LSP信息", icon = "ℹ️" },
				{ "<leader>cm", desc = "Mason插件管理", icon = "📦" },
				{ "<leader>co", desc = "整理导入", icon = "📦" },
				{ "<leader>cu", desc = "删除未使用的导入", icon = "🗑️" },
				{ "<leader>ci", desc = "添加缺失导入", icon = "📥" },
				{ "<leader>cX", desc = "修复所有诊断", icon = "🛠️" },
				{ "<leader>cr", desc = "重命名", icon = "✏️" },
				{ "<leader>cs", desc = "显示符号结构", icon = "🔍" },
				{ "<leader>cS", desc = "查找引用/定义", icon = "🔍" },
				{ "<leader>cF", desc = "格式化注入语言", icon = "🛠️" },
				                { "<leader>d", group = "调试", icon = "🔧" },
				                { "<leader>dp", group = "性能分析", icon = "📊" },
				                { "<leader>dps", desc = "开始采样", icon = "▶️" },
				                { "<leader>dpx", desc = "停止采样", icon = "⏹️" },
				                				{ "<leader>x", group = "诊断/修复", icon = "⚠️" },
				                				{ "<leader>e", group = "文件浏览器", icon = "📂" },
				                				{ "<leader>f", group = "文件/查找", icon = "📁" },				{ "<leader>ff", desc = "查找文件", icon = "🔍" },
				{ "<leader>g", group = "Git", icon = "🧡" },
				{ "<leader>gh", group = "变更", icon = "🔄" },
				{ "<leader>h", group = "历史", icon = "📜" },
				{ "<leader>hn", desc = "通知历史", icon = "🔔" },
				{ "<leader>hc", desc = "命令历史", icon = "💬" },
				{ "<leader>hs", desc = "搜索历史", icon = "🔍" },
				{ "<leader>H", desc = "切换显示隐藏文件", icon = "👁️" },
				{ "<leader>k", desc = "查询DevDocs（关键词）", icon = "📚" },
				{ "<leader>K", desc = "搜索DevDocs（输入查询）", icon = "📚" },
				{ "<leader>l", desc = "插件管理器", icon = "🧩" },
				{ "<leader>L", desc = "Lazy更新历史", icon = "📜" },
				{ "<leader>q", group = "退出/会话", icon = "🚪" },
				{ "<leader>r", group = "运行/调试", icon = "🚀" },
				{ "<leader>s", group = "搜索", icon = "🔍" },
				{ "<leader>S", group = "临时Buffer", icon = "📝" },
				{ "<leader>Ss", desc = "打开默认临时Buffer" },
				{ "<leader>Sn", desc = "新建命名临时Buffer" },
				{ "<leader>S.", desc = "打开默认临时Buffer" },
				{ "<leader>SS", desc = "选择/管理临时Buffer" },
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
				{ "<leader>ww", desc = "切换到其他窗口", remap = true },
				{ "<leader>x", group = "诊断/修复", icon = "⚠️" },
				{ "<leader>xx", desc = "项目诊断面板", icon = "🚨" },
				{ "<leader>xX", desc = "当前文件诊断", icon = "🔍" },
				{ "[", group = "上一个", icon = "⬆️" },
				{ "]", group = "下一个", icon = "⬇️" },
				{ "g", group = "跳转", icon = "🔗" },
				{ "gs", group = "环绕", icon = "🔁" },
				{ "z", group = "折叠", icon = "📁" },
			},
			-- 批量描述替换 (严格还原原始版本翻译，并补全缺失项)
			replace = {
				desc = {
					{ "Keywordprg", "关键词查询" },
					{ "Explorer", "文件浏览器" },
					{ "Notification History", "通知历史" },
					{ "Buffers", "Buffer" },
					{ "Git Diff", "Git 差异" },
					{ "Git Status", "Git 状态" },
					{ "Git Stash", "Git 暂存" },
					{ "GitHub Issues", "GitHub 问题" },
					{ "GitHub Pull Requests", "GitHub 拉取请求" },
					{ "Recent", "最近文件" },
					{ "Projects", "项目列表" },
					{ "Command History", "命令历史" },
					{ "Buffer Lines", "Buffer行" },
					{ "Grep Open Buffers", "搜索已打开Buffer" },
					{ "Search for Plugin Spec", "搜索插件配置" },
					{ "Visual selection or word", "选区或单词" },
					{ "Registers", "寄存器" },
					{ "Search History", "搜索历史" },
					{ "Autocmds", "自动命令" },
					{ "Commands", "命令" },
					{ "Diagnostics", "诊断信息" },
					{ "Buffer Diagnostics", "Buffer诊断" },
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
					{ "Goto Declaration", "跳转到声明" },
					{ "Goto Implementation", "跳转到实现" },
					{ "Goto Type Definition", "跳转到类型定义" },
					{ "Keyword Index", "关键词索引" },
					{ "Select Scratch Buffer", "选择临时Buffer" },
					-- Buffer相关
					{ "Switch to Other Buffer", "切换到其他Buffer" },
					{ "Delete Buffer", "关闭当前Buffer" },
					{ "Delete Buffer and Window", "关闭Buffer和窗口" },
					{ "Delete Other Buffers", "关闭其他Buffer" },
					{ "Prev Buffer", "上一个Buffer" },
					{ "Next Buffer", "下一个Buffer" },
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
					{ "Delete Non-Pinned", "关闭未固定Buffer" },
					{ "Delete", "关闭" },
					{ "Non-Pinned", "非固定" },
					{ "Non", "非" },
					{ "Buffer列表", "Buffer列表" },
					{ "Pinned", "固定" },
					{ "Close", "关闭" },
					{ "Delete Non-Pinned Buffers", "关闭非固定Buffer" },
					{ "Ungrouped", "未分组" },
					{ "New File", "新建文件" },
					{ "Format", "格式化" },
					{ "Format Injected Langs", "格式化注入语言" },
					{ "Code Action", "代码操作" },
					{ "Source Action", "项目操作" },
					{ "Rename", "重命名" },
					{ "Rename File", "重命名文件" },
					{ "Lsp Info", "LSP信息" },
					{ "Lsp Log", "LSP日志" },
					{ "Mason", "Mason" },
					{ "Profiler Start", "开始采样" },
					{ "Profiler Stop", "停止采样" },
					{ "Profiler Scratch Buffer", "性能分析临时Buffer" },
					{ "Conform Info", "格式化信息" },
					{ "Call Hierarchy", "调用层次" },
					{ "Incoming Calls", "输入调用" },
					{ "Outgoing Calls", "输出调用" },
					{ "Fix all diagnostics", "修复所有诊断" },
					{ "Add missing imports", "添加缺失导入" },
					{ "Organize Imports", "整理导入" },
					{ "Remove unused imports", "删除未使用的导入" },
					{ "Code Lens", "代码透镜" },
					{ "Refresh & Display Codelens", "刷新并显示代码透镜" },
					{ "Refresh", "刷新" },
					{ "References", "引用" },
					{ "Definitions", "定义" },
					{ "Implementations", "实现" },
					{ "Type Definitions", "类型定义" },
					{ "Symbols (Trouble)", "符号（Trouble）" },
					{ "LSP references/definitions/... (Trouble)", "引用/定义/...（Trouble）" },
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
					{ "Find Files (cwd)", "查找文件 (当前目录)" },
					{ "Find Files (git-files)", "查找文件 (Git)" },
					{ "Recent Files", "最近文件" },
					{ "Recent (cwd)", "最近文件 (当前目录)" },
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
					-- GitHub 相关
					{ "GitHub Issues (all)", "GitHub 问题 (全部)" },
					{ "GitHub Issues (open)", "GitHub 问题 (打开)" },
					{ "GitHub Pull Requests (all)", "GitHub 拉取请求 (全部)" },
					{ "GitHub Pull Requests (open)", "GitHub 拉取请求 (打开)" },
					-- 缺失补全项 (采用原始风格)
					{ "picker_grep", "正则搜索" },
					{ "picker_files", "查找文件" },
					{ "Grep (Root Dir)", "查找文件 (根目录)" },
					{ "Grep (cwd)", "查找文件 (当前目录)" },
					{ "Word (Root Dir)", "搜索单词 (根目录)" },
					{ "Word (cwd)", "搜索单词 (当前目录)" },
				},
			},
		},
		config = function(_, opts)
			-- 设置 which-key 边框颜色 (与当前风格一致)
			vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#2b85b7", default = true })
			vim.api.nvim_set_hl(0, "WhichKeyNormal", { bg = "#1a1b26", default = true })
			-- 设置图标和分组颜色
			vim.api.nvim_set_hl(0, "WhichKeyIcon", { fg = "#9aa5ce", default = true })
			vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = "#9aa5ce", default = true })
			vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = "#565f89", default = true })

			require("which-key").setup(opts)
		end,
	},

	-- ---------------------------------------------------------------------------
	-- Trouble：更优雅的诊断/列表显示 (强制开启自动聚焦)
	-- ---------------------------------------------------------------------------
	{
		"folke/trouble.nvim",
		opts = {
			focus = true, -- 全局设置自动聚焦
		},
		keys = {
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=true<cr>",
				desc = "显示符号结构",
			},
			{
				"<leader>cS",
				"<cmd>Trouble lsp toggle focus=true<cr>",
				desc = "查找引用/定义",
			},
		},
	},

	-- ---------------------------------------------------------------------------
	-- Snacks.nvim：功能强大的现代化组件库
	-- ---------------------------------------------------------------------------
	{
		"snacks.nvim",
		keys = {
			-- 侧边栏：文件浏览器
			{
				"<leader>fe",
				function()
					require("snacks").explorer({ cwd = require("lazyvim.util").root() })
				end,
				desc = "文件浏览器 (根目录)",
			},
			{
				"<leader>fE",
				function()
					require("snacks").explorer()
				end,
				desc = "文件浏览器 (当前目录)",
			},
			{ "<leader>e", "<leader>fe", desc = "文件浏览器", remap = true },

			-- 临时Buffer操作
			{
				"<leader>Ss",
				function()
					require("snacks").scratch({ ft = "" })
				end,
				desc = "打开默认临时Buffer",
			},
			{
				"<leader>Sn",
				function()
					require("snacks").scratch({ name = vim.fn.input("名称: "), ft = "" })
				end,
				desc = "新建命名临时Buffer",
			},
			{
				"<leader>S.",
				function()
					require("snacks").scratch()
				end,
				desc = "切换临时Buffer",
			},
			{
				"<leader>SS",
				function()
					require("snacks").picker.scratch()
				end,
				desc = "选择/管理临时Buffer",
			},

			-- Buffer与窗口操作
			{ "<leader>bb", "<cmd>e #<cr>", desc = "切换到其他Buffer" },
			{
				"<leader>bf",
				function()
					require("snacks").picker.buffers()
				end,
				desc = "Buffer列表",
			},

			-- 窗口管理：原生操作符映射
			{ "<leader>w-", "<C-W>s", desc = "向下分割窗口", remap = true },
			{ "<leader>w|", "<C-W>v", desc = "向右分割窗口", remap = true },
			{ "<leader>wd", "<C-W>c", desc = "关闭当前窗口", remap = true },
			{ "<leader>wh", "<C-W>h", desc = "切换到左侧窗口", remap = true },
			{ "<leader>wj", "<C-W>j", desc = "切换到下方窗口", remap = true },
			{ "<leader>wk", "<C-W>k", desc = "切换到上方窗口", remap = true },
			{ "<leader>wl", "<C-W>l", desc = "切换到右侧窗口", remap = true },
			{ "<leader>wH", "<C-W>H", desc = "向左移动窗口", remap = true },
			{ "<leader>wJ", "<C-W>J", desc = "向下移动窗口", remap = true },
			{ "<leader>wK", "<C-W>K", desc = "向上移动窗口", remap = true },
			{ "<leader>wL", "<C-W>L", desc = "向右移动窗口", remap = true },
			{ "<leader>w=", "<C-W>=", desc = "均衡窗口大小", remap = true },
			{ "<leader>ww", "<C-W>w", desc = "切换到其他窗口", remap = true },
			{
				"<leader>wm",
				function()
					require("snacks").toggle.zoom()
				end,
				desc = "最大化/恢复窗口",
			},

			-- 快捷搜索：/ 和 ?
			{ "/", snacks_lines, desc = "当前文件搜索", mode = { "n", "v" } },
			{ "?", snacks_lines, desc = "当前文件搜索", mode = { "n", "v" } },
		},
		opts = function(_, opts)
			-- ... (rest of snacks opts)
			-- Picker 全局视觉美化
			opts.picker = opts.picker or {}
			opts.picker.prompt = "" -- 严格还原原始设置

			-- 添加清除选择的动作
			opts.picker.actions = opts.picker.actions or {}
			opts.picker.actions.list_clear_selected = function(picker)
				picker.list:set_selected({})
			end

			opts.picker.win = opts.picker.win or {}

			-- 输入框：居中并使用圆角
			opts.picker.win.input = {
				row = 0.3,
				height = 1,
				width = 0.6,
				col = 0.2,
				border = "rounded",
				wo = { statuscolumn = "", signcolumn = "no" },
			}

			-- 列表：禁用冗余列
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

			-- 源特定增强
			opts.picker.sources = opts.picker.sources or {}
			-- Buffer列表：显示固定状态图标
			opts.picker.sources.buffers = {
				format = function(item, picker)
					local formatted = require("snacks").picker.format.buffer(item, picker)
					-- 如果文件被固定 (Pinned)，则在前面显示图钉图标
					local ok_groups, groups = pcall(require, "bufferline.groups")
					local ok_state, state = pcall(require, "bufferline.state")
					if ok_groups and ok_state and state.components then
						for _, element in ipairs(state.components) do
							if element.id == item.buf and groups._is_pinned(element) then
								table.insert(formatted, 1, { "📌 ", "Special" })
								break
							end
						end
					end
					return formatted
				end,
			}

			-- 历史命令布局：基于 VSCode 风格但带完整边框
			opts.picker.sources.command_history = {
				layout = {
					preset = "custom",
					layout = {
						backdrop = false,
						row = 1,
						width = 0.4,
						min_width = 80,
						height = 0.4,
						border = "none",
						box = "vertical",
						{
							win = "input",
							height = 1,
							border = "rounded",
							title = "{title} {live} {flags}",
							title_pos = "center",
						},
						{ win = "list", border = "rounded" },
					},
				},
			}

			return opts
		end,
	},
}
