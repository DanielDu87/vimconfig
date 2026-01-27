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
		-- 删除可能存在的 <leader>P 子项键位
		-- ---------------------------------------------------------------------------
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			once = true,
			callback = function()
				local wk = require("which-key")
				-- 删除 which-key 中注册的 <leader>P 组
				pcall(function()
					wk.remove({ "<leader>", "P" })
				end)
			end,
		})

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

		-- ---------------------------------------------------------------------------
		-- 删除 LSP 默认的重命名键位（被智能重构接管）
		-- ---------------------------------------------------------------------------
		pcall(vim.keymap.del, "n", "<leader>cr") -- 删除 LazyVim 默认的 LSP 重命名映射（如果存在）

		-- ---------------------------------------------------------------------------
		-- 删除查找菜单中的终端操作（移到 <leader>t 菜单）
		-- ---------------------------------------------------------------------------
		pcall(vim.keymap.del, "n", "<leader>ft") -- 删除 Toggle Terminal
		pcall(vim.keymap.del, "n", "<leader>fT") -- 删除 Terminal (cwd)

		-- ---------------------------------------------------------------------------
		-- 性能分析快捷键（放在 <leader>dp 子菜单）
		-- ---------------------------------------------------------------------------
		vim.keymap.set("n", "<leader>dpp", function()
			require("snacks").toggle.profiler()
		end, { desc = "切换性能分析器" })
		vim.keymap.set("n", "<leader>dph", function()
			require("snacks").toggle.profiler_highlights()
		end, { desc = "性能分析高亮" })

		-- ---------------------------------------------------------------------------
		-- 删除 LazyVim Python extras 的默认调试键位（从 dP 子菜单移出）
		-- ---------------------------------------------------------------------------
		pcall(vim.keymap.del, "n", "<leader>dPt") -- 删除 Debug Method（三键）
		pcall(vim.keymap.del, "n", "<leader>dPc") -- 删除 Debug Class（三键）

		-- 删除可能存在的 <leader>P 菜单
		pcall(vim.keymap.del, "n", "<leader>P")

		-- 重新定义 Python 调试快捷键（直接放在 <leader>d 下）
		vim.keymap.set("n", "<leader>dm", function()
			require("dap-python").test_method()
		end, { desc = "调试方法（Method）" })
		vim.keymap.set("n", "<leader>dC", function()
			require("dap-python").test_class()
		end, { desc = "调试类（Class）" })

		-- 重新映射清除断点到 dX (因为 dC 被调试类占用)
		pcall(vim.keymap.del, "n", "<leader>dC") -- 删除旧的清除断点（如果存在）
		vim.keymap.set("n", "<leader>dX", function()
			require("persistent-breakpoints.api").clear_all_breakpoints()
		end, { desc = "清除所有断点（持久化）" })

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
-- 4. 优化 <leader>bP：关闭非固定文件并锁定侧边栏布局
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
				{ "<leader>P", group = which_key_ignore },
				{ "<leader>P", desc = "which_key_ignore" },
				{ "<leader>`", desc = "which_key_ignore" },
				{ "<leader>,", desc = "which_key_ignore" },
				{ "<leader>br", desc = "which_key_ignore" },
				-- 按字母分组，大小写放在一起
				{ "<leader>b", group = "缓冲区", icon = "🗂️" },
				{ "<leader>r", group = "运行/调试", icon = "🚀" },
				{ "<leader>rr", desc = "运行当前文件", icon = "▶️" },
				{ "<leader>rp", desc = "运行项目", icon = "🏗️" },
				{ "<leader>ro", desc = "打开浏览器", icon = "🌍" },
				{ "<leader>rl", desc = "查看日志", icon = "📋" },
				{ "<leader>rs", desc = "停止任务", icon = "🛑" },
				{ "<leader>rc", desc = "配置文件运行命令", icon = "🛠️" },
				{ "<leader>rC", desc = "配置项目运行命令", icon = "⚙️" },
				{ "<leader>rb", desc = "配置文件浏览器URL", icon = "🔗" },
				{ "<leader>rB", desc = "配置项目浏览器URL", icon = "🌐" },
				{ "<leader>rv", desc = "选择Python虚拟环境", icon = "🐍" },
				{ "<leader>rV", desc = "选择TS工作区版本", icon = "🏷️" },
				{ "<leader>bb", desc = "切换到其他Buffer", icon = "🔄" },
				{ "<leader>bd", desc = "关闭当前Buffer", icon = "❌" },
				{ "<leader>bD", desc = "关闭Buffer和窗口", icon = "❌" },
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
				{ "<leader>cF", desc = "格式化注入语言", icon = "🛠️" },
				{ "<leader>cs", desc = "显示符号结构", icon = "🔍" },
				{ "<leader>cr", desc = "智能重构", icon = "🔨" },
				{ "<leader>rv", desc = "选择Python虚拟环境", icon = "🐍" },
				{ "<leader>d", group = "调试", icon = "🔧" },
				{ "<leader>db", desc = "切换断点（持久化）", icon = "🔴" },
				{ "<leader>dB", desc = "条件断点（持久化）", icon = "⭕" },
				{ "<leader>dC", desc = "调试类（Class）", icon = "🐍" },
				{ "<leader>dX", desc = "清除所有断点（持久化）", icon = "🗑️" },
				{ "<leader>dc", desc = "开始/继续调试", icon = "▶️" },
				{ "<leader>di", desc = "步入（Into）", icon = "⬇️" },
				{ "<leader>do", desc = "步过（Over）", icon = "➡️" },
				{ "<leader>du", desc = "步出（Out）", icon = "⬆️" },
				{ "<leader>dt", desc = "切换调试面板", icon = "🖥️" },
				{ "<leader>dm", desc = "调试方法（Method）", icon = "🐍" },
				{ "<leader>dp", group = "性能分析", icon = "📊" },
				{ "<leader>dpp", desc = "切换性能分析器", icon = "📊" },
				{ "<leader>dph", desc = "性能分析高亮", icon = "✨" },
				{ "<leader>x", group = "诊断/修复", icon = "⚠️" },
				{ "<leader>e", group = "文件浏览器", icon = "📂" },
				{ "<leader>f", group = "文件/查找", icon = "📁" },
				{ "<leader>ff", desc = "查找文件（根目录）", icon = "🔍" },
				{ "<leader>fb", desc = "查找Buffer", icon = "📑" },
				{ "<leader>fF", desc = "查找文件（当前目录）", icon = "📂" },
				{ "<leader>fg", desc = "查找Git文件", icon = "🧡" },
				{ "<leader>fn", desc = "新建文件", icon = "📄" },
				{ "<leader>fp", desc = "项目列表", icon = "🚀" },
				{ "<leader>fB", desc = "查找Buffer（所有）", icon = "🗃️" },
				{ "<leader>fr", desc = "最近文件（根目录）", icon = "🕒" },
				{ "<leader>fR", desc = "最近文件（当前目录）", icon = "⏱️" },
				{ "<leader>fc", desc = "查找配置文件", icon = "⚙️" },
				{ "<leader>fe", desc = "文件浏览器（根目录）", icon = "📂" },
				{ "<leader>fE", desc = "文件浏览器（当前目录）", icon = "📁" },
				{ "<leader>g", group = "Git", icon = "🧡" },
				{ "<leader>gi", desc = "Github Issues", icon = "🎫" },
				{ "<leader>gI", desc = "Github Pull Request", icon = "📬" },
				{ "<leader>gB", desc = "which_key_ignore" },
				{ "<leader>gY", desc = "which_key_ignore" },
				{ "<leader>ga", desc = "Git暂存", icon = "📥" },
				{ "<leader>gb", desc = "Git Blame", icon = "🕵️" },
				{ "<leader>gc", desc = "Git切换分支", icon = "🔀" },
				{ "<leader>gC", desc = "which_key_ignore" },
				{ "<leader>gF", desc = "which_key_ignore" },
				{ "<leader>gd", desc = "Git差异", icon = "🌓" },
				{ "<leader>gD", desc = "Git差异（远程）", icon = "📡" },
				{ "<leader>gf", desc = "Git面板", icon = "🖥️" },
				{ "<leader>gg", desc = "Git提交图", icon = "📊" },
				{ "<leader>gG", desc = "which_key_ignore" },
				{ "<leader>gl", desc = "Git日志（简洁）", icon = "📋" },
				{ "<leader>gL", desc = "Git日志（详细）", icon = "📜" },
				{ "<leader>gp", desc = "Git推送", icon = "⬆️" },
				{ "<leader>gP", desc = "Git拉取", icon = "⬇️" },
				{ "<leader>gr", group = "Git远程仓库", icon = "🔗" },
				{ "<leader>gro", desc = "浏览器打开", icon = "🌍" },
				{ "<leader>gry", desc = "复制链接", icon = "🔗" },
				{ "<leader>gs", desc = "Git Stash", icon = "📦" },
				{ "<leader>gS", desc = "which_key_ignore" },
				{ "<leader>gh", group = "Git变更", icon = "🔄" },
				{ "<leader>ghb", desc = "恢复代码块", icon = "🔙" },
				{ "<leader>ghp", desc = "预览代码块", icon = "🔍" },
				{ "<leader>ghr", desc = "重置代码块", icon = "🧹" },
				{ "<leader>ghs", desc = "暂存代码块", icon = "➕" },
				{ "<leader>ghu", desc = "撤销暂存代码块", icon = "↩️" },
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
				{ "<leader>qs", desc = "恢复会话", icon = "🔄" },
				{ "<leader>qS", desc = "选择会话", icon = "🗂️" },
				{ "<leader>ql", desc = "恢复最近会话", icon = "🕒" },
				{ "<leader>qd", desc = "不保存退出", icon = "❌" },
				{ "<leader>qq", desc = "退出所有", icon = "🚪" },
				{ "<leader>s", group = "搜索", icon = "🔍" },
				{ "<leader>sa", desc = "自动命令", icon = "⚡" },
				{ "<leader>sb", desc = "当前Buffer行", icon = "📑" },
				{ "<leader>sc", desc = "命令历史", icon = "💬" },
				{ "<leader>sC", desc = "所有命令", icon = "💻" },
				{ "<leader>sd", desc = "文档诊断", icon = "🔍" },
				{ "<leader>sD", desc = "项目诊断", icon = "🚨" },
				{ "<leader>sg", desc = "全局搜索（根目录）", icon = "🔍" },
				{ "<leader>sG", desc = "全局搜索（当前目录）", icon = "📂" },
				{ "<leader>sh", desc = "帮助文档", icon = "❓" },
				{ "<leader>sH", desc = "高亮组", icon = "🎨" },
				{ "<leader>si", desc = "图标插件", icon = "🎭" },
				{ "<leader>sj", desc = "跳转记录", icon = "👣" },
				{ "<leader>sk", desc = "快捷键查看", icon = "⌨️" },
				{ "<leader>sl", desc = "位置列表", icon = "📍" },
				{ "<leader>sm", desc = "标记管理", icon = "🔖" },
				{ "<leader>sq", desc = "快速修复列表", icon = "🛠️" },
				{ "<leader>sR", desc = "恢复上次搜索", icon = "↩️" },
				{ "<leader>su", desc = "撤销历史", icon = "📜" },
				{ "<leader>sw", desc = "搜索单词（项目）", icon = "🔎" },
				{ "<leader>sW", desc = "搜索单词（目录）", icon = "📂" },
				{ "<leader>S", group = "临时Buffer", icon = "📝" },
				{ "<leader>t", group = "终端", icon = "💻" },
				{ "<leader>tf", desc = "浮窗终端", icon = "💎" },
				{ "<leader>th", desc = "竖直终端（上下）", icon = "↕️" },
				{ "<leader>tv", desc = "水平终端（左右）", icon = "↔️" },
				{ "<leader>tt", desc = "标签页终端", icon = "📑" },
				{ "<leader>Ss", desc = "打开默认临时Buffer", icon = "📝" },
				{ "<leader>Sn", desc = "新建命名临时Buffer", icon = "🆕" },
				{ "<leader>S.", desc = "打开默认临时Buffer", icon = "📝" },
				{ "<leader>SS", desc = "选择/管理临时Buffer", icon = "🗂️" },
				{ "<leader>u", group = "界面", icon = "🎨" },
				{ "<leader>w", group = "窗口", icon = "🖼️" },
				{ "<leader>w-", desc = "向下分割窗口", icon = "➖" },
				{ "<leader>w|", desc = "向右分割窗口", icon = "➕" },
				{ "<leader>wd", desc = "关闭当前窗口", icon = "❌" },
				{ "<leader>wh", desc = "切换到左侧窗口", icon = "⬅️" },
				{ "<leader>wj", desc = "切换到下方窗口", icon = "⬇️" },
				{ "<leader>wk", desc = "切换到上方窗口", icon = "⬆️" },
				{ "<leader>wl", desc = "切换到右侧窗口", icon = "➡️" },
				{ "<leader>wH", desc = "向左移动窗口", icon = "⏪" },
				{ "<leader>wJ", desc = "向下移动窗口", icon = "⏬" },
				{ "<leader>wK", desc = "向上移动窗口", icon = "⏫" },
				{ "<leader>wL", desc = "向右移动窗口", icon = "⏩" },
				{ "<leader>w=", desc = "均衡窗口大小", icon = "⚖️" },
				{ "<leader>wm", desc = "最大化/恢复窗口", icon = "🔎" },
				{ "<leader>ww", desc = "切换到其他窗口", icon = "🔄", remap = true },
				{ "<leader>x", group = "诊断/修复", icon = "⚠️" },
				{ "<leader>xx", desc = "项目诊断面板", icon = "🚨" },
				{ "<leader>xX", desc = "当前文件诊断", icon = "🔍" },
				{ "<leader>xl", desc = "位置列表", icon = "📍" },
				{ "<leader>xq", desc = "快速修复列表", icon = "🛠️" },
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
					{ "Buffers", "查找Buffer" },
					{ "Buffers (all)", "查找Buffer（所有）" },
					{ "Git Diff", "Git差异" },
					{ "Git Status", "Git状态" },
					{ "Git Stash", "Git Stash" },
					{ "Git Blame", "Git行追溯" },
					{ "Git Branches", "Git切换分支" },
					{ "Git Commit", "Git提交记录" },
					{ "Git Checkout", "Git检出" },
					{ "Git Files", "Git文件" },
					{ "Git Browse", "浏览器打开" },
					{ "Git Browse (open)", "浏览器打开" },
					{ "Git Log", "Git日志" },
					{ "Git Pull", "Git拉取" },
					{ "Git Push", "Git推送" },
					{ "Git Switch", "Git切换" },
					{ "GitHub Issues", "GitHub问题" },
					{ "GitHub Pull Requests", "GitHub拉取请求" },
					{ "Recent", "最近文件" },
					{ "Projects", "项目列表" },
					{ "Command History", "命令历史" },
					{ "Buffer Lines", "查找Buffer行" },
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
					                    { "Buffer Keymaps (which-key)", "Buffer快捷键查询（which-key）" },					{ "Location List", "位置列表" },
					{ "Man Pages", "手册页" },
					{ "Marks", "标记" },
					{ "Resume", "恢复上一次" },
					{ "Quickfix List", "快速修复列表" },
					{ "Undotree", "撤销树" },
					{ "Colorschemes", "配色方案" },
					{ "Todo", "待办事项" },
					{ "LSP Symbols", "LSP符号" },
					{ "LSP Workspace Symbols", "LSP工作区符号" },
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
					{ "Profiler Start", "切换性能分析器" },
					{ "Profiler Stop", "停止采样" },
					{ "Profiler Scratch Buffer", "性能分析临时Buffer" },
					{ "Toggle Profiler", "切换性能分析器" },
					{ "Profiler", "性能分析器" },
					{ "Conform Info", "格式化信息" },
					{ "Call Hierarchy", "调用层次" },
					{ "Debug Class", "调试类（Class）" },
					{ "Debug Method", "调试方法（Method）" },
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
					{ "Find Config File", "查找配置文件" },
					{ "Find", "查找" },
					{ "Find Files", "查找文件（根目录）" },
					{ "Find Files (Root Dir)", "查找文件（根目录）" },
					{ "Find Files (cwd)", "查找文件（当前目录）" },
					{ "Find Files (git-files)", "查找Git文件" },
					{ "Find Files (unrestricted)", "查找所有文件" },
					{ "Recent Files", "最近文件（根目录）" },
					{ "Recent (cwd)", "最近文件（当前目录）" },
					{ "Current File Search", "当前文件搜索" },
					{ "File Browser", "文件浏览器" },
					{ "File Browser (Root Dir)", "文件浏览器（根目录）" },
					{ "File Browser (Cwd)", "文件浏览器（当前目录）" },
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
					{ "Config", "配置文件" },
					{ "Explorer", "文件浏览器" },
					-- GitHub 相关
					{ "GitHub Issues (all)", "GitHub问题（所有）" },
					{ "GitHub Issues (open)", "GitHub问题（打开）" },
					{ "GitHub Pull Requests (all)", "GitHub拉取请求（所有）" },
					{ "GitHub Pull Requests (open)", "GitHub拉取请求（打开）" },
					-- 缺失补全项 (采用原始风格)
					{ "picker_grep", "正则搜索" },
					{ "picker_files", "查找文件" },
					{ "Grep (Root Dir)", "正则搜索（根目录）" },
					{ "Grep (cwd)", "正则搜索（当前目录）" },
					{ "Word (Root Dir)", "搜索单词（根目录）" },
					{ "Word (cwd)", "搜索单词（当前目录）" },
					-- 终端相关
					{ "Terminal", "终端" },
					{ "Term (float)", "浮窗终端" },
					{ "Term (horizontal)", "竖直终端（上下）" },
					{ "Term (vertical)", "水平终端（左右）" },
					{ "Term (tab)", "标签页终端" },
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

			-- 为 git log 自定义高亮组
			vim.api.nvim_set_hl(0, "GitLogHead", { fg = "#D484FF", italic = false }) -- 亮紫色, 非斜体
			vim.api.nvim_set_hl(0, "GitLogTag", { fg = "#3891A6", italic = false }) -- 青色, 非斜体
			vim.api.nvim_set_hl(0, "GitLogRemote", { fg = "#9D9D9D", italic = false }) -- 灰色, 非斜体
			vim.api.nvim_set_hl(0, "GitLogBranch", { fg = "#50FA7B", italic = false }) -- 亮绿色, 非斜体
			-- 为内置组创建非斜体版本
			vim.api.nvim_set_hl(0, "GitLogComment", { fg = "#E5C07B", italic = false }) -- 淡黄色 (括号), 非斜体
			vim.api.nvim_set_hl(0, "GitLogDiagnosticInfo", { fg = "#61afef", italic = false }) -- Atom OneDark 信息颜色
			vim.api.nvim_set_hl(0, "GitLogType", { fg = "#c678dd", italic = false }) -- Atom OneDark 类型颜色
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
				desc = "文件浏览器（根目录）",
			},
			{
				"<leader>fE",
				function()
					require("snacks").explorer()
				end,
				desc = "文件浏览器（当前目录）",
			},
			{ "<leader>e", "<leader>fe", desc = "文件浏览器", remap = true },

			-- 最近文件
			{
				"<leader>fr",
				function()
					require("snacks").picker.recent()
				end,
				desc = "最近文件（根目录）",
			},
			{
				"<leader>fR",
				function()
					require("snacks").picker.recent({ cwd = vim.fn.getcwd() })
				end,
				desc = "最近文件（当前目录）",
			},

			-- Git 文件
			{
				"<leader>fg",
				function()
					require("snacks").picker.files({ cmd = "git ls-files" })
				end,
				desc = "查找Git文件",
			},

			-- Buffer 列表
			{
				"<leader>fb",
				function()
					require("snacks").picker.buffers()
				end,
				desc = "查找Buffer",
			},
			{
				"<leader>fB",
				function()
					require("snacks").picker.buffers({ hidden = true, nofile = true })
				end,
				desc = "查找Buffer（所有）",
			},

			-- 配置文件
			{
				"<leader>fc",
				function()
					require("snacks").picker.config_files()
				end,
				desc = "查找配置文件",
			},

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

			-- Git 增强映射 (中文化覆盖)
			-- Git检出：选择并切换分支（使用git switch）
			{
				"<leader>gc",
				function()
					local root = require("lazyvim.util").root()
					require("snacks").terminal("lazygit branch", {
						cwd = root,
						win = {
							position = "float",
							title = " Git Branch ",
							width = 0.8,
							height = 0.8,
						},
						interactive = true,
					})
				end,
				desc = "Git切换分支",
			},
			-- Git远程仓库子菜单（leader gr）
			{
				"<leader>gro",
				function()
					require("snacks").gitbrowse()
				end,
				desc = "浏览器打开",
				mode = { "n", "v" },
			},
			{
				"<leader>gry",
				function()
					-- 获取远程仓库URL并复制到剪贴板
					local cwd = vim.fn.getcwd()
					local remote = vim.fn.trim(vim.fn.system("git -C " .. cwd .. " config --get remote.origin.url"))

					if remote == "" then
						vim.notify("未找到远程仓库", vim.log.levels.WARN)
						return
					end

					-- 获取当前文件信息
					local file = vim.fn.expand("%:.")
					local branch = vim.fn.trim(vim.fn.system("git -C " .. cwd .. " rev-parse --abbrev-ref HEAD"))
					local line = vim.api.nvim_win_get_cursor(0)[1]

					-- 构建GitHub/GitLab URL
					local url = remote
						:gsub("%.git$", "")
						:gsub("^git@(.+):(.+)$", "https://%1/%2")
						:gsub("^git@(.+)/(.+)$", "https://%1/%2")
						:gsub("^https://.+@", "https://")

					-- 添加文件路径和行号
					if file and file ~= "" then
						url = url .. "/blob/" .. branch .. "/" .. file .. "#L" .. line
					else
						url = url .. "/tree/" .. branch
					end

					-- 复制到剪贴板
					vim.fn.setreg("+", url)
					vim.notify("已复制远程仓库链接", vim.log.levels.INFO)
				end,
				desc = "复制链接",
				mode = { "n", "v" },
			},
			{
				"<leader>ga",
				function()
					local root = require("lazyvim.util").root()
					vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " add -A")
					vim.notify("所有更改已添加到暂存区", vim.log.levels.INFO, { title = "Git" })
				end,
				desc = "Git暂存",
			},
			{
				"<leader>gb",
				function()
					require("snacks").git.blame_line()
				end,
				desc = "Git Blame",
			},
						{
				"<leader>gf",
				function()
					require("snacks").terminal("lazygit")
				end,
				desc = "查看本地差异 (LazyGit)",
			},
			{
				"<leader>gF",
				function()
					local remote = vim.fn.trim(vim.fn.system("git config --get remote.origin.url"))
					if remote == "" then
						vim.notify("未指定远程仓库地址", vim.log.levels.WARN)
						return
					end
					require("snacks").terminal("git fetch && lazygit")
				end,
				desc = "查看远程差异 (LazyGit)",
			},
			{
				"<leader>gD",
				function()
					local root = require("lazyvim.util").root()
					local verify_cmd = "git -C " .. vim.fn.shellescape(root) .. " rev-parse --verify origin/main"

					vim.fn.system(verify_cmd)
					if vim.v.shell_error ~= 0 then
						vim.notify("远程分支 'origin/main' 不存在", vim.log.levels.WARN)
						return
					end

					local diff_cmd = "git -C " .. vim.fn.shellescape(root) .. " diff origin/main"
					require("snacks").terminal(diff_cmd, {
						win = {
							position = "float",
							backdrop = false,
							border = "rounded",
							title = " Diff: origin/main ",
							title_pos = "center",
							width = 0.8,
							height = 0.8,
						},
						interactive = false,
					})
				end,
				desc = "Git差异（远程）",
			},
															{
															"<leader>gs",
															function()
																local root = require("lazyvim.util").root()
																require("snacks").terminal("lazygit stash", {
																	cwd = root,
																	win = {
																		position = "float",
																		title = " Git Stash ",
																		width = 0.8,
																		height = 0.8,
																	},
																	interactive = true,
																})
															end,
															desc = "Git Stash",
														},			-- Git提交图：显示 git log --oneline --graph --decorate --all
			{
				"<leader>gg",
				function()
					require("snacks").terminal("git log --oneline --graph --decorate --all", {
						win = {
							position = "float",
							backdrop = false,
							border = "rounded",
							title = " Git提交图 ",
							title_pos = "center",
							width = 0.8,
							height = 0.8,
						},
						interactive = false,
					})
				end,
				desc = "Git提交图",
			},
			-- Git提交详情：查看提交的完整代码变更
			{
				"<leader>gl",
				function()
					-- 自定义格式化函数，实现丰富的高亮
					local function git_log_oneline(item, picker)
						local ret = {} ---@type snacks.picker.Highlight[]
						local text = item.text

						-- 1. 高亮图形符号
						local graph_end = text:find("[^%s*|\\/_%-%.]") or 1
						if graph_end > 1 then
							ret[#ret + 1] = { text:sub(1, graph_end - 1), "GitLogDiagnosticInfo" }
							text = text:sub(graph_end)
						end

						-- 2. 高亮提交哈希
						local hash_match = text:match("^(%x+)")
						if hash_match then
							ret[#ret + 1] = { hash_match .. " ", "Keyword" }
							text = text:sub(#hash_match + 1)
							text = text:gsub("^%s*", "")
						end

						-- 3. 高亮分支和标签信息
						if text:sub(1, 1) == "(" then
							local decorations_end = text:find(")")
							if decorations_end then
								local decorations = text:sub(2, decorations_end - 1)
								ret[#ret + 1] = { "(", "GitLogComment" }

								local first = true
								for part in (decorations .. ","):gmatch("(.-),") do
									part = part:match("^%s*(.-)%s*$") -- trim whitespace
									if #part > 0 then
										if not first then
											ret[#ret + 1] = { ", ", "GitLogComment" }
										end
										first = false

										if part:match("^HEAD%s*->") then
											ret[#ret + 1] = { "HEAD", "GitLogHead" } -- 使用自定义的紫色高亮
											ret[#ret + 1] = { " -> ", "GitLogDiagnosticInfo" }
											local branch = part:gsub("^HEAD%s*->%s*", "")
											ret[#ret + 1] = { branch, "GitLogBranch" }
										elseif part:match("^tag:%s*") then
											ret[#ret + 1] = { "tag:", "GitLogType" }
											local tag = part:gsub("^tag:%s*", "")
											ret[#ret + 1] = { tag, "GitLogTag" }
										elseif part:find("/") then -- 简单判断是否为远程分支
											ret[#ret + 1] = { part, "GitLogRemote" }
										else
											ret[#ret + 1] = { part, "GitLogBranch" }
										end
									end
								end
								ret[#ret + 1] = { ") ", "GitLogComment" } -- Add a space after the closing parenthesis
								text = text:sub(decorations_end + 1)
								text = text:gsub("^%s*", "")
							end
						end

						-- 4. 提交信息
						ret[#ret + 1] = { text, "Normal" }

						return ret
					end

					-- 直接使用 git log 命令
					local result = vim.fn.systemlist("git log --oneline --all --graph --decorate -100")
					if vim.v.shell_error ~= 0 then
						vim.notify("获取 Git 日志失败", vim.log.levels.ERROR)
						return
					end

					-- 解析并创建 items
					local items = {}
					for _, line in ipairs(result) do
						local commit = line:match("(%w%x+)") -- 匹配十六进制提交哈希
						if commit then
							table.insert(items, {
								commit = commit,
								msg = line, -- 保存整行作为消息
								text = line,
							})
						end
					end

					require("snacks").picker({
						title = " Git日志（简洁） ",
						title_pos = "center",
						items = items,
						format = git_log_oneline,
						confirm = function(picker, item)
							picker:close()
							if item and item.commit then
								require("snacks").terminal("git show " .. item.commit, {
									win = {
										position = "float",
										backdrop = false,
										border = "rounded",
										title = " Git Diff: " .. item.commit .. " ",
										title_pos = "center",
									},
									interactive = false,
								})
							end
						end,
						layout = { preset = "select" },
					})
				end,
				desc = "Git日志（简洁）",
			},
			{
				"<leader>gp",
				function()
					local root = require("lazyvim.util").root()
					local cmd = "git -C " .. vim.fn.shellescape(root) .. " push"
					require("snacks").terminal(cmd, {
						win = { position = "float", title = " Git Push ", width = 0.8, height = 0.8 },
						interactive = true, -- Push might require credentials
					})
				end,
				desc = "Git推送",
			},
			{
				"<leader>gP",
				function()
					local root = require("lazyvim.util").root()
					local cmd = "git -C " .. vim.fn.shellescape(root) .. " pull"
					require("snacks").terminal(cmd, {
						win = { position = "float", title = " Git Pull ", width = 0.8, height = 0.8 },
						interactive = true, -- Pull can have merge conflicts
					})
				end,
				desc = "Git拉取",
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
