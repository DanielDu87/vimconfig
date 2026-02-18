--==============================================================================
-- Editor 插件配置：覆盖 LazyVim 默认的编辑器行为
--==============================================================================
-- 本文件主要配置：
-- 1. 快捷键重新组织 (将窗口/Buffer操作归类)
-- 2. WhichKey 菜单定制与中文化
-- 3. Snacks.nvim 核心组件配置 (Picker, Explorer, Scratch)

--==============================================================================
-- 窗口大小保存系统初始化
--==============================================================================
-- 延迟初始化，确保 Neovim 完全启动
vim.defer_fn(function()
	require("util.window_sizes").setup()
end, 0)

--==============================================================================
-- 1. 快捷键深度定制
--==============================================================================
-- 我们在 LazyVim 加载完默认键位后，通过 autocmd 进行精准覆盖
vim.api.nvim_create_autocmd("User", {
	pattern = "LazyVimKeymaps",
	callback = function()
		-- ---------------------------------------------------------------------------
		-- 删除 LazyVim 默认的 UI Toggle 键位（使用自定义的 emoji 图标版本）
		-- ---------------------------------------------------------------------------
		local safe_del = function(mode, lhs)
			pcall(vim.keymap.del, mode, lhs)
		end
		safe_del("n", "<leader>ua") -- 删除默认的动画切换（重新定义）
		-- safe_del("n", "<leader>ub") -- 保留默认的背景模式切换
		safe_del("n", "<leader>uc") -- 删除默认的文本隐藏切换（重新定义）
		safe_del("n", "<leader>uD") -- 删除默认的暗化切换（重新定义）
		-- safe_del("n", "<leader>uf") -- 保留格式化切换（LazyVim内置）
		-- safe_del("n", "<leader>uF") -- 保留格式化切换（LazyVim内置）
		-- safe_del("n", "<leader>ug") -- 保留默认的缩进引导线切换
		-- safe_del("n", "<leader>uh") -- 保留默认的代码透镜切换
		safe_del("n", "<leader>uL") -- 删除默认的相对行号切换（重新定义）
		-- safe_del("n", "<leader>ul") -- 保留默认的行号切换
		-- safe_del("n", "<leader>us") -- 保留默认的拼写检查切换
		safe_del("n", "<leader>uS") -- 删除默认的平滑滚动切换（重新定义）
		safe_del("n", "<leader>uT") -- 删除默认的treesitter切换（我们要用作透明模式）
		safe_del("n", "<leader>uA") -- 删除默认的标签栏切换（重新定义）
		-- safe_del("n", "<leader>uw") -- 保留默认的自动换行切换
		safe_del("n", "<leader>uz") -- 删除默认的禅模式切换（重新定义）
		safe_del("n", "<leader>uZ") -- 删除默认的缩放模式切换（重新定义）
		-- safe_del("n", "<leader>ud") -- 保留LazyVim默认的诊断切换
		-- safe_del("n", "<leader>uG") -- 保留LazyVim默认的Git signs切换

		-- ---------------------------------------------------------------------------
		-- 窗口管理：统一移到 <leader>w (Windows) 组
		-- ---------------------------------------------------------------------------
		safe_del("n", "<leader>-") -- 删除默认的横向分割
		safe_del("n", "<leader>|") -- 删除默认的纵向分割

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
		safe_del("n", "<leader>.")

		-- ---------------------------------------------------------------------------
		-- Buffer管理：清理默认的冗余键位
		-- ---------------------------------------------------------------------------
		safe_del("n", "<leader>`") -- 切换到上一个Buffer
		safe_del("n", "<leader>,") -- Buffer列表
		safe_del("n", "<leader>br") -- LazyVim 默认的向右关闭
		safe_del("n", "<leader>bl") -- LazyVim 默认的向左关闭
		safe_del("n", "<leader>bD") -- 隐藏默认的关闭Buffer和窗口

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
		-- 性能分析快捷键（直接放在 <leader>d 菜单）
		-- ---------------------------------------------------------------------------
		vim.keymap.set("n", "<leader>dp", function()
			require("snacks").toggle.profiler()
		end, { desc = "切换性能分析器" })
		vim.keymap.set("n", "<leader>dh", function()
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
		vim.keymap.set("n", "<leader>dM", function()
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

		-- LSP 相关快捷键
		vim.keymap.set("n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "LSP信息" })
		vim.keymap.set("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason插件管理" })
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作" })
		vim.keymap.set({ "n", "v" }, "<leader>cA", function()
			vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
		end, { desc = "项目操作" })
		vim.keymap.set("n", "<leader>cc", vim.lsp.codelens.run, { desc = "运行代码透镜" })
		vim.keymap.set("n", "<leader>cC", vim.lsp.codelens.refresh, { desc = "刷新并显示代码透镜" })
		vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "显示行诊断信息" })

		-- 针对 vtsls 优化的专有操作 (TypeScript/Vue)
		local function vtsls_cmd(cmd)
			return function()
				local ok, vtsls = pcall(require, "vtsls")
				if ok and vtsls.commands and vtsls.commands[cmd] then
					vtsls.commands[cmd]()
				else
					-- 回退到通用代码操作
					local action_map = {
						organize_imports = "source.organizeImports",
						remove_unused_imports = "source.removeUnused",
						add_missing_imports = "source.addMissingImports",
						fix_all = "source.fixAll",
					}
                    -- 如果不是 vtsls 特有命令（如 rename），则回退到标准 LSP
                    if cmd == "rename" then
                        vim.lsp.buf.rename()
                    else
					    vim.lsp.buf.code_action({ apply = true, context = { only = { action_map[cmd] or "source" }, diagnostics = {} } })
                    end
				end
			end
		end

		vim.keymap.set("n", "<leader>co", vtsls_cmd("organize_imports"), { desc = "整理导入" })
		vim.keymap.set("n", "<leader>cu", vtsls_cmd("remove_unused_imports"), { desc = "删除未使用的导入" })
		vim.keymap.set("n", "<leader>ci", vtsls_cmd("add_missing_imports"), { desc = "添加缺失导入" })
		vim.keymap.set("n", "<leader>cx", vtsls_cmd("fix_all"), { desc = "修复所有诊断" })
		vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "重命名" })

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
			layout = { columns = 3, spacing = 3, align = "center" },
			-- 只在 <leader> 前缀时弹出菜单，隐藏操作符模式（c/d/y 等）的菜单
			triggers = { "<leader>" },
			icons = {
				rules = false, -- 禁用默认图标规则
			},
			win = {
				width = 0.8,
				height = { min = 4, max = math.huge },
				col = 0.5,
				row = 0.9,
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
				{ "<leader><tab>d", desc = "关闭标签页", icon = "❌" },
				{ "<leader><tab>f", desc = "第一个标签页", icon = "⏮️" },
				{ "<leader><tab>l", desc = "最后一条标签页", icon = "⏭️" },
				{ "<leader><tab>o", desc = "关闭其他标签页", icon = "🗑️" },
				{ "<leader><tab>p", desc = "上一个标签页", icon = "⬅️" },
				{ "<leader><tab>n", desc = "下一个标签页", icon = "➡️" },
				{ "<leader><tab><tab>", desc = "新建标签页", icon = "📄" },
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
				{ "<leader>bD", desc = "which_key_ignore" },
				{ "<leader>br", desc = "which_key_ignore" },
				{ "<leader>sn", desc = "which_key_ignore" },
				{ "<leader>s/", desc = "which_key_ignore" },
				-- 按字母分组，大小写放在一起
				{ "<leader>b", group = "缓冲区和书签", icon = "🗂️" },

				{ "<leader>r", group = "运行/调试", icon = "🚀" },
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
				{ "<leader>bh", desc = "上一个Buffer", icon = "⬅️" },
				{ "<leader>bl", desc = "下一个Buffer", icon = "➡️" },
				{ "<leader>bn", desc = "打开全局临时Buffer", icon = "📝" },
				{ "<leader>bo", desc = "关闭其他Buffer", icon = "🗑️" },
				{ "<leader>bp", desc = "切换固定", icon = "📌" },
				{ "<leader>bH", desc = "关闭左侧所有Buffer", icon = "🗑️" },
				{ "<leader>bL", desc = "关闭右侧所有Buffer", icon = "🗑️" },
				{ "<leader>c", group = "代码", icon = "🛠️" },
				{ "<leader>c/", desc = "切换行注释", icon = "💬" },
				{ "<leader>ca", desc = "代码操作", icon = "💡" },
				{ "<leader>cg", desc = "切换Ghost诊断", icon = "👻" },
				{ "<leader>cA", desc = "项目操作", icon = "⚛️" },
				{ "<leader>cc", desc = "运行代码透镜", icon = "💎" },
				{ "<leader>cC", desc = "刷新并显示代码透镜", icon = "🔄" },
				{ "<leader>cd", desc = "显示行诊断信息", icon = "🔍" },
				{ "<leader>cl", desc = "LSP信息", icon = "ℹ️" },
				{ "<leader>cm", desc = "Mason插件管理", icon = "📦" },
				{ "<leader>co", desc = "整理导入", icon = "📦" },
				{ "<leader>cu", desc = "删除未使用的导入", icon = "🗑️" },
				{ "<leader>ci", desc = "添加缺失导入", icon = "📥" },
				{ "<leader>cx", desc = "修复所有诊断", icon = "🛠️" },
				{ "<leader>cF", desc = "格式化注入语言", icon = "🛠️" },
				{ "<leader>cs", desc = "显示符号结构", icon = "🔍" },
				{ "<leader>cr", desc = "重命名", icon = "✍️" },
				{ "<leader>rv", desc = "选择Python虚拟环境", icon = "🐍" },
				{ "<leader>d", group = "调试/诊断", icon = "🔧" },
				{ "<leader>dP", desc = "which_key_ignore" },
				{ "<leader>dd", desc = "文档诊断", icon = "🚨" },
				{ "<leader>dD", desc = "项目诊断", icon = "🚑" },
				{ "<leader>db", desc = "切换断点（持久化）", icon = "🔴" },
				{ "<leader>dB", desc = "条件断点（持久化）", icon = "⭕" },
				{ "<leader>dC", desc = "调试类（Class）", icon = "🐍" },
				{ "<leader>dX", desc = "清除所有断点（持久化）", icon = "🗑️" },
				{ "<leader>dc", desc = "开始/继续调试", icon = "▶️" },
				{ "<leader>di", desc = "步入（Into）", icon = "⬇️" },
				{ "<leader>do", desc = "步过（Over）", icon = "➡️" },
				{ "<leader>du", desc = "步出（Out）", icon = "⬆️" },
				{ "<leader>dt", desc = "切换调试面板", icon = "🖥️" },
				{ "<leader>dM", desc = "调试方法（Method）", icon = "🐍" },
				{ "<leader>dp", desc = "切换性能分析器", icon = "📊" },
				{ "<leader>dh", desc = "性能分析高亮", icon = "✨" },
				{ "<leader>x", group = "诊断/修复", icon = "🚑" },
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
				{ "<leader>gc", desc = "Git提交", icon = "📝" },
				{ "<leader>gC", desc = "Git切换分支", icon = "🔀" },
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
				{ "<leader>gs", desc = "Git状态", icon = "📊" },
				{ "<leader>gS", desc = "Git Stash", icon = "📦" },
				{ "<leader>h", group = "历史", icon = "📜" },
				{ "<leader>hn", desc = "通知历史记录", icon = "📜" },
				{ "<leader>hl", desc = "最后一条通知", icon = "💬" },
				{ "<leader>ha", desc = "所有通知", icon = "📨" },
				{ "<leader>hx", desc = "清除所有通知", icon = "🗑️" },
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
				{ "<leader>sa", desc = "自动执行命令", icon = "🤖" },
				{ "<leader>sb", desc = "查找当前文件行", icon = "📖" },
				{ "<leader>sc", desc = "命令历史", icon = "🕰️" },
				{ "<leader>sC", desc = "所有命令", icon = "💻" },
				{ "<leader>sg", desc = "全局搜索（根目录）", icon = "🔭" },
				{ "<leader>sG", desc = "全局搜索（当前目录）", icon = "🔎" },
				{ "<leader>sh", desc = "帮助文档", icon = "❓" },
				{ "<leader>sH", desc = "高亮组", icon = "🎨" },
				{ "<leader>si", desc = "图标插件", icon = "🎭" },
				{ "<leader>sj", desc = "跳转记录", icon = "👣" },
				{ "<leader>sk", desc = "快捷键查看", icon = "⌨️" },
				{ "<leader>sl", desc = "位置列表", icon = "📍" },
				{ "<leader>sm", desc = "标记管理", icon = "🔖" },
				{ "<leader>sq", desc = "快速修复列表", icon = "🛠️" },
				{ "<leader>sR", desc = "恢复上次搜索", icon = "↩️" },
				{ "<leader>sr", desc = "查找并替换", icon = "🔄" },
				{ '<leader>s"', desc = "寄存器", icon = "📋" },
				{ "<leader>su", desc = "撤销历史", icon = "📜" },
				{ "<leader>sw", desc = "搜索单词（项目）", icon = "🔡" },
				{ "<leader>sW", desc = "搜索单词（目录）", icon = "🔠" },
				{ "<leader>sB", desc = "查找所有打开文件", icon = "📁" },
				{ "<leader>sp", desc = "搜索插件配置", icon = "🧩" },
				{ "<leader>st", desc = "待办事项（全部类型）", icon = "✅" },
				{ "<leader>sT", desc = "待办事项（仅TODO/FIX/FIXME）", icon = "📝" },
				{ "<leader>sd", desc = "诊断信息", icon = "📋" },
				{ "<leader>sD", desc = "Buffer诊断信息", icon = "🚑" },
				{ "<leader>sM", desc = "手册页", icon = "📚" },
				{ "<leader>ss", desc = "文档符号", icon = "💎" },
				{ "<leader>sS", desc = "项目符号", icon = "⚛️" },
											{ "<leader>S", desc = "打开全局临时Buffer", icon = "📝" },
											{ "<leader>t", group = "终端与模板", icon = "💻" },
											{ "<leader>tf", desc = "浮窗终端", icon = "💎" },
											{ "<leader>th", desc = "竖直终端（上下）", icon = "↕️" },
											{ "<leader>tv", desc = "水平终端（左右）", icon = "↔️" },
											{ "<leader>tt", desc = "标签页终端", icon = "📑" },
											{ "<leader>tn", desc = "新建文件 (模板)", icon = "📄" },				{ "<leader>u", group = "界面", icon = "🎨" },
				{ "<leader>ua", desc = "which_key_ignore" },
				{ "<leader>ub", desc = "切换背景模式", icon = "🌓" },
				{ "<leader>ud", desc = "切换诊断显示", icon = "🔍" },
				{ "<leader>uf", desc = "切换自动格式化", icon = "🛠️" },
				{ "<leader>ug", desc = "切换缩进引导线", icon = "📏" },
				{ "<leader>uh", desc = "切换代码透镜", icon = "💎" },
				{ "<leader>ul", desc = "切换行号模式", icon = "🔢" },
				{ "<leader>un", desc = "切换通知系统", icon = "🔔" },
				{ "<leader>us", desc = "切换拼写检查", icon = "📝" },
				{ "<leader>uT", desc = "切换标签栏", icon = "🏷️" },
				{ "<leader>ut", desc = "切换透明模式", icon = "👻" },
				{ "<leader>uw", desc = "切换自动换行", icon = "↩️" },
				{ "<leader>w", group = "窗口", icon = "🍱" },
				{ "<leader>w-", desc = "向下分割窗口", icon = "🥞" },
				{ "<leader>w|", desc = "向右分割窗口", icon = "⏸️" },
				{ "<leader>wd", desc = "关闭当前窗口", icon = "🗑️" },
				{ "<leader>wh", desc = "切换到左侧窗口", icon = "⬅️" },
				{ "<leader>wj", desc = "切换到下方窗口", icon = "⬇️" },
				{ "<leader>wk", desc = "切换到上方窗口", icon = "⬆️" },
				{ "<leader>wl", desc = "切换到右侧窗口", icon = "➡️" },
				{ "<leader>wH", desc = "向左移动窗口", icon = "◀️" },
				{ "<leader>wJ", desc = "向下移动窗口", icon = "🔽" },
				{ "<leader>wK", desc = "向上移动窗口", icon = "🔼" },
				{ "<leader>wL", desc = "向右移动窗口", icon = "▶️" },
				{ "<leader>w=", desc = "均衡窗口大小", icon = "📏" },
				{ "<leader>wm", desc = "最大化/恢复窗口", icon = "🔍" },
				{ "<leader>wr", desc = "调整窗口大小", icon = "📐" },
				{ "<leader>ww", desc = "切换到其他窗口", icon = "🔁", remap = true },
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
					{ "Recent", "最近文件" },
					{ "Projects", "项目列表" },
					{ "Command History", "命令历史" },
					{ "Buffer Lines", "查找Buffer行" },
					{ "Search for Plugin Spec", "搜索插件配置" },
					{ "Visual selection or word", "选区或单词" },
					{ "Registers", "寄存器" },
					{ "Search History", "搜索历史" },
					{ "Autocmds", "自动命令" },
					{ "Commands", "命令" },
					{ "Diagnostics", "诊断信息" },
					{ "Buffer Diagnostics", "Buffer诊断信息" },
					{ "Help Pages", "帮助文档" },
					{ "Highlights", "高亮组" },
					{ "Icons", "图标插件" },
					{ "Jumps", "跳转记录" },
					{ "Keymaps", "快捷键映射" },
					{ "Buffer Keymaps (which-key)", "Buffer快捷键查询（which-key）" },
					{ "Location List", "位置列表" },
					{ "Man Pages", "手册页" },
					{ "Marks", "标记" },
					{ "Resume", "恢复上一次" },
					{ "Quickfix List", "快速修复列表" },
					{ "Undotree", "撤销树" },
					{ "Colorschemes", "配色方案" },
					{ "Todo", "待办事项" },
					{ "LSP Symbols", "LSP符号" },
					{ "LSP Workspace Symbols", "LSP工作区符号" },
					{ "Notifications", "通知" },
					{ "Noice", "通知" },
					-- 界面与功能开关
					{ "Disable Animations", "禁用动画" },
					{ "Enable Animations", "开启动画" },
					{ "Disable Tabline", "禁用标签栏" },
					{ "Enable Tabline", "开启标签栏" },
					{ "Disable Conceal Level", "禁用文本隐藏" },
					{ "Enable Conceal Level", "开启文本隐藏" },
					{ "Enable Dimming", "开启非活动暗化" },
					{ "Disable Dimming", "禁用非活动暗化" },
					{ "Disable Auto Format (Buffer)", "禁用自动格式化（Buffer）" },
					{ "Enable Auto Format (Buffer)", "开启自动格式化（Buffer）" },
					{ "Disable Auto Format (Global)", "禁用全局自动格式化" },
					{ "Enable Auto Format (Global)", "开启全局自动格式化" },
					{ "Disable Auto Format", "禁用自动格式化" },
					{ "Enable Auto Format", "开启自动格式化" },
					{ "Disable Git Signs", "禁用 Git 标记" },
					{ "Enable Git Signs", "开启 Git 标记" },
					{ "Inspect Pos", "查看位置信息" },
					{ "Inspect Tree", "查看语法树" },
					{ "Enable Relative Number", "开启相对行号" },
					{ "Disable Relative Number", "禁用相对行号" },
					{ "Disable Mini Pairs", "禁用自动配对" },
					{ "Enable Mini Pairs", "开启自动配对" },
					{ "Redraw / Clear hlsearch / Diff Update", "刷新并清除搜索高亮" },
					{ "Disable Smooth Scroll", "禁用平滑滚动" },
					{ "Enable Smooth Scroll", "开启平滑滚动" },
					{ "Enable Zen Mode", "开启禅模式" },
					{ "Disable Zen Mode", "禁用禅模式" },
					{ "Enable Zoom Mode", "开启缩放模式" },
					{ "Disable Zoom Mode", "禁用缩放模式" },
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
					{ "Increase Window Width", "增加窗口宽度" }, -- 其他
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
					{ "Select VirtualEnv", "选择Python虚拟环境" },
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
					-- 性能分析器相关
					{ "Enable Profiler", "开启性能分析器" },
					{ "Disable Profiler", "禁用性能分析器" },
					{ "Enable 性能分析器", "开启性能分析器" },
					{ "Disable 性能分析器", "禁用性能分析器" },
					{ "Enable Profiler Highlights", "开启分析器高亮" },
					{ "Disable Profiler Highlights", "禁用分析器高亮" },
					{ "Enable 性能分析器高亮", "开启分析器高亮" },
					{ "Disable 性能分析器高亮", "禁用分析器高亮" },
					{ "Enable 性能分析器 高亮组", "开启分析器高亮" },
					{ "Disable 性能分析器 高亮组", "禁用分析器高亮" },
					{ "Profiler Scratch Buffer", "性能分析临时Buffer" },
					{ "Profiler", "性能分析器" },
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
					-- 标签页相关
					{ "Close Tab", "关闭标签页" },
					{ "First Tab", "第一个标签页" },
					{ "Last Tab", "最后一条标签页" },
					{ "Other Tabs", "关闭其他标签页" },
					{ "Previous Tab", "上一个标签页" },
					{ "Next Tab", "下一个标签页" },
					{ "New Tab", "新建标签页" },
				},
			},
		},
		config = function(_, opts)
			-- 设置 which-key 边框颜色 (透明背景)
			vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#2b85b7", bg = "NONE", default = true })
			vim.api.nvim_set_hl(0, "WhichKeyNormal", { bg = "NONE", default = true })
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

			-- 临时Buffer操作（全局持久化）
			{
				"<leader>S",
				function()
					require("snacks").scratch({
						name = "全局临时Buffer",
						ft = "text",
						file = vim.fn.expand("~/Documents/neovim_files/global-scratch.md"),
					})
				end,
				desc = "打开全局临时Buffer",
			},

			-- Buffer与窗口操作
			{ "<leader>bb", "<cmd>e #<cr>", desc = "切换到其他Buffer" },
			{
				"<leader>bn",
				function()
					require("snacks").scratch({
						name = "全局临时Buffer",
						ft = "text",
						file = vim.fn.expand("~/Documents/neovim_files/global-scratch.md"),
					})
				end,
				desc = "打开全局临时Buffer",
			},

			-- 诊断相关 (从 <leader>s 迁移)
			{
				"<leader>dd",
				function()
					require("snacks").picker.diagnostics()
				end,
				desc = "文档诊断",
			},
			{
				"<leader>dD",
				function()
					require("snacks").picker.diagnostics({ root = true })
				end,
				desc = "项目诊断",
			},

			-- 窗口管理：原生操作符映射
			{ "<leader>w-", "<C-W>s", mode = "n", desc = "向下分割窗口", remap = true },
			{ "<leader>w|", "<C-W>v", mode = "n", desc = "向右分割窗口", remap = true },
			{ "<leader>wd", "<C-W>c", mode = "n", desc = "关闭当前窗口", remap = true },
			{ "<leader>wh", "<C-W>h", mode = "n", desc = "切换到左侧窗口", remap = true },
			{ "<leader>wj", "<C-W>j", mode = "n", desc = "切换到下方窗口", remap = true },
			{ "<leader>wk", "<C-W>k", mode = "n", desc = "切换到上方窗口", remap = true },
			{ "<leader>wl", "<C-W>l", mode = "n", desc = "切换到右侧窗口", remap = true },
			{ "<leader>wH", "<C-W>H", mode = "n", desc = "向左移动窗口", remap = true },
			{ "<leader>wJ", "<C-W>J", mode = "n", desc = "向下移动窗口", remap = true },
			{ "<leader>wK", "<C-W>K", mode = "n", desc = "向上移动窗口", remap = true },
			{ "<leader>wL", "<C-W>L", mode = "n", desc = "向右移动窗口", remap = true },
			{ "<leader>w=", "<C-W>=", mode = "n", desc = "均衡窗口大小", remap = true },
			{ "<leader>ww", "<C-W>w", mode = "n", desc = "切换到其他窗口", remap = true },
			{
				"<leader>wm",
				function()
					require("snacks").toggle.zoom()
				end,
				desc = "最大化/恢复窗口",
			},
			{
				"<leader>wr",
				function()
					-- 智能调整窗口大小：自动检测窗口类型并调整尺寸
					local win = vim.api.nvim_get_current_win()
					local win_config = vim.api.nvim_win_get_config(win)
					local is_float = win_config.relative ~= "" -- 浮窗

					if is_float then
						vim.notify("浮窗暂不支持通过此方式调整大小", vim.log.levels.WARN)
						return
					end

					-- 检测窗口是水平分割还是垂直分割
					local win_width = vim.api.nvim_win_get_width(win)
					local win_height = vim.api.nvim_win_get_height(win)

					-- 获取所有窗口信息判断分割类型
					local windows = vim.api.nvim_list_wins()
					local has_vertical_neighbor = false -- 是否有左右邻居（垂直分割）
					local has_horizontal_neighbor = false -- 是否有上下邻居（水平分割）

					local win_row = vim.api.nvim_win_get_position(win)[1]
					local win_col = vim.api.nvim_win_get_position(win)[2]

					for _, w in ipairs(windows) do
						if w ~= win then
							local w_pos = vim.api.nvim_win_get_position(w)
							local w_row = w_pos[1]
							local w_col = w_pos[2]
							local w_height = vim.api.nvim_win_get_height(w)
							local w_width = vim.api.nvim_win_get_width(w)

							-- 检查是否有重叠的行（左右邻居）
							if not (win_row + win_height <= w_row or win_row >= w_row + w_height) then
								has_vertical_neighbor = true
							end
							-- 检查是否有重叠的列（上下邻居）
							if not (win_col + win_width <= w_col or win_col >= w_col + w_width) then
								has_horizontal_neighbor = true
							end
						end
					end

					-- 根据分割类型预设不同的推荐尺寸
					local function prompt_size(prompt, default, max_val)
						local opts = {
							prompt = prompt,
							default = tostring(default),
							completion = "number",
						}
						vim.ui.input(opts, function(input)
							if not input then
								return
							end
							local num = tonumber(input)
							if num and num > 0 and num <= max_val then
								return num
							end
						end)
					end

					if has_vertical_neighbor and not has_horizontal_neighbor then
						-- 纯垂直分割，调整宽度
						local current = win_width
						local max_cols = vim.o.columns
						local default = math.floor(max_cols * 0.5)
						vim.ui.input({
							prompt = string.format("设置窗口宽度 (当前 %d，最大 %d): ", current, max_cols),
							default = tostring(default),
							completion = "number",
						}, function(input)
							if not input then
								return
							end
							local width = tonumber(input)
							if width and width > 0 and width <= max_cols then
								vim.api.nvim_win_set_width(win, width)
								-- 保存窗口大小
								require("util.window_sizes").save_current_size()
							end
						end)
					elseif has_horizontal_neighbor and not has_vertical_neighbor then
						-- 纯水平分割，调整高度
						local current = win_height
						local max_lines = vim.o.lines
						local default = math.floor(max_lines * 0.4)
						vim.ui.input({
							prompt = string.format("设置窗口高度 (当前 %d，最大 %d): ", current, max_lines),
							default = tostring(default),
							completion = "number",
						}, function(input)
							if not input then
								return
							end
							local height = tonumber(input)
							if height and height > 0 and height <= max_lines then
								vim.api.nvim_win_set_height(win, height)
								-- 保存窗口大小
								require("util.window_sizes").save_current_size()
							end
						end)
					else
						-- 混合分割或只有一个窗口
						if #windows > 1 then
							-- 混合分割，让用户选择
							vim.ui.select({
								{ text = "宽度", value = "width" },
								{ text = "高度", value = "height" },
							}, {
								prompt = "选择要调整的维度：",
								format_item = function(item)
									return item.text
								end,
							}, function(choice)
								if not choice then
									return
								end
								if choice.value == "width" then
									local current = win_width
									local max_cols = vim.o.columns
									vim.ui.input({
										prompt = string.format("设置窗口宽度 (当前 %d，最大 %d): ", current, max_cols),
										default = tostring(current),
										completion = "number",
									}, function(input)
										if not input then
											return
										end
										local width = tonumber(input)
										if width and width > 0 and width <= max_cols then
											vim.api.nvim_win_set_width(win, width)
											-- 保存窗口大小
											require("util.window_sizes").save_current_size()
										end
									end)
								else
									local current = win_height
									local max_lines = vim.o.lines
									vim.ui.input({
										prompt = string.format("设置窗口高度 (当前 %d，最大 %d): ", current, max_lines),
										default = tostring(current),
										completion = "number",
									}, function(input)
										if not input then
											return
										end
										local height = tonumber(input)
										if height and height > 0 and height <= max_lines then
											vim.api.nvim_win_set_height(win, height)
											-- 保存窗口大小
											require("util.window_sizes").save_current_size()
										end
									end)
								end
							end)
						end
					end
				end,
				desc = "调整窗口大小",
			},

			-- Git 增强映射 (中文化覆盖)
			{
				"<leader>ga",
				function()
					local output = vim.fn.system("git add -A")
					if vim.v.shell_error == 0 then
						vim.notify("当前目录下的更改已全部暂存", vim.log.levels.INFO, { title = "Git" })
					else
						vim.notify("暂存失败: " .. output, vim.log.levels.ERROR, { title = "Git" })
					end
				end,
				desc = "Git暂存 (当前目录)",
			},
			-- Git检出：选择并切换分支
			{
				"<leader>gC",
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
			-- Git提交 (悬浮审核)
			{
				"<leader>gc",
				function()
					-- 获取屏幕尺寸
					local width = math.floor(vim.o.columns * 0.65)
					local height = math.floor(vim.o.lines * 0.8)
					local col = math.floor((vim.o.columns - width) / 2)
					local row = math.floor((vim.o.lines - height) / 2)

					-- 1. 首先在当前上下文执行 Git 命令
					vim.cmd("Git")
					local git_buf = vim.api.nvim_get_current_buf()
					vim.cmd("close") -- 关闭自动弹出的普通窗口

					-- 2. 创建浮动窗口并放入 Git buffer
					vim.api.nvim_open_win(git_buf, true, {
						relative = "editor",
						width = width,
						height = height,
						col = col,
						row = row,
						style = "minimal",
						border = "rounded",
						title = " Fugitive Status ",
						title_pos = "center",
					})
				end,
				desc = "Git面板 (Fugitive 悬浮)",
			},
			{
				"<leader>gb",
				function()
					require("snacks").git.blame_line()
				end,
				mode = "n",
				desc = "Git Blame/行追溯",
			},
			{
				"<leader>gb",
				":'<,'>BlameInvestigateLines<CR>",
				mode = "v",
				desc = "Git Blame (选区)",
			},
			{
				"<leader>gd",
				function()
					require("snacks").terminal("lazygit", {
						cwd = require("lazyvim.util").root(),
						win = {
							position = "float",
							title = " LazyGit Diff ",
							width = 0.8,
							height = 0.8,
						},
					})
				end,
				desc = "查看本地差异 (LazyGit)",
			},
			{
				"<leader>gD",
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
				"<leader>gs",
				function()
					require("snacks").picker.git_status()
				end,
				desc = "Git状态",
			},
			{
				"<leader>gS",
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
			},
			-- Git提交图：显示 git log --oneline --graph --decorate --all
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
					require("snacks").picker.git_log({
						title = " Git 日志 ",
						title_pos = "center",
						win = {
							input = {
								keys = {
									["<Tab>"] = { "focus_preview", mode = { "i", "n" } },
								},
							},
							list = {
								keys = {
									["<Tab>"] = { "focus_preview", mode = { "n" } },
								},
							},
							preview = {
								keys = {
									["<Tab>"] = { "focus_input", mode = { "n" } },
								},
							},
						},
						layout = {
							layout = {
								box = "vertical", -- 改为纵向排列
								width = 0.75,
								height = 0.7,
								{
									box = "vertical",
									border = "rounded",
									title = " 提交历史 ",
									height = 0.4, -- 上方历史占 40% 高度
									{ win = "input", height = 1, border = "bottom" },
									{ win = "list", border = "none" },
								},
								{
									win = "preview",
									title = " 差异预览 ",
									border = "rounded",
									height = 0.6, -- 下方预览占 60% 高度
								},
							},
						},
						confirm = function(picker, item)
							picker:close()
							if item and (item.commit or item.hash) then
								local commit = item.commit or item.hash
								vim.cmd("DiffviewOpen " .. commit)
							end
						end,
					})
				end,
				desc = "Git日志（自定义宽布局）",
			},
			{
				"<leader>gp",
				function()
					local root = require("lazyvim.util").root()
					-- 先 fetch 所有远程，然后 push
					local cmd = "git -C "
						.. vim.fn.shellescape(root)
						.. " fetch --all && git -C "
						.. vim.fn.shellescape(root)
						.. " push"
					require("snacks").terminal(cmd, {
						win = { position = "float", title = " Git Fetch & Push ", width = 0.65, height = 0.8 },
						interactive = true, -- Push might require credentials
					})
				end,
				desc = "Git推送（先fetch）",
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

			-- UI 选项切换（使用 Snacks.toggle API，自动集成 Emoji 图标）
			{
				"<leader>ua",
				function()
					-- 保存当前视图状态
					local win = vim.api.nvim_get_current_win()
					local view = vim.fn.winsaveview()
					local mode = vim.api.nvim_get_mode().mode

					local ok, toggle = pcall(require("snacks").toggle.animate)
					if ok and toggle then
						-- 切换动画
						toggle:toggle()

						-- 延迟恢复视图和模式（确保切换完成）
						vim.schedule(function()
							pcall(vim.fn.winrestview, view)
							-- 如果之前不在插入模式，确保不进入插入模式
							if mode ~= "i" then
								vim.cmd("stopinsert")
							end
						end)
					else
						vim.notify("动画切换功能不可用", vim.log.levels.WARN)
					end
				end,
				desc = "切换动画",
			},
			{
				"<leader>uT",
				function()
					require("snacks").toggle.option("showtabline", { off = 0, on = 2, name = "标签栏" }):toggle()
				end,
				desc = "切换标签栏",
			},
			{
				"<leader>uc",
				function()
					require("snacks").toggle.option("conceallevel", { off = 0, on = 2, name = "文本隐藏" }):toggle()
				end,
				desc = "切换文本隐藏",
			},
			{
				"<leader>uD",
				function()
					require("snacks").toggle.dim():toggle()
				end,
				desc = "切换暗化",
			},
			{
				"<leader>uL",
				function()
					require("snacks").toggle.option("relativenumber", { name = "相对行号" }):toggle()
				end,
				desc = "切换相对行号",
			},
			{
				"<leader>uS",
				function()
					require("snacks").toggle.scroll():toggle()
				end,
				desc = "切换平滑滚动",
			},
			{
				"<leader>uz",
				function()
					require("snacks").toggle.zen():toggle()
				end,
				desc = "切换禅模式",
			},
			{
				"<leader>uZ",
				function()
					require("snacks").toggle.zoom():toggle()
				end,
				desc = "切换缩放模式",
			},
			{
				"<leader>ut",
				function()
					vim.g.transparent_enabled = not vim.g.transparent_enabled
					if vim.g.transparent_enabled then
						vim.cmd("set winblend=0")
						vim.cmd("set pumblend=0")
						vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
						vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
						vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
						vim.notify("已开启透明模式", vim.log.levels.INFO)
					else
						vim.cmd("set winblend=0")
						vim.cmd("set pumblend=0")
						vim.cmd("hi Normal ctermbg=0 guibg=#1a1b26")
						vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1a1b26" })
						vim.api.nvim_set_hl(0, "NormalNC", { bg = "#1a1b26" })
						vim.notify("已禁用透明模式", vim.log.levels.INFO)
					end
				end,
				desc = "切换透明模式",
			},

			-- 快捷搜索：/ 和 ?
			{ "/", snacks_lines, desc = "当前文件搜索", mode = { "n", "v" } },
			{ "?", snacks_lines, desc = "当前文件搜索", mode = { "n", "v" } },

			-- 标签页操作
			{ "<leader><tab>n", "<cmd>tabnext<cr>", desc = "下一个标签页" },
			{ "<leader><tab>p", "<cmd>tabprevious<cr>", desc = "上一个标签页" },
			{ "<leader><tab>f", "<cmd>tabfirst<cr>", desc = "第一个标签页" },
			{ "<leader><tab>l", "<cmd>tablast<cr>", desc = "最后一条标签页" },
			{ "<leader><tab>d", "<cmd>tabclose<cr>", desc = "关闭标签页" },
			{ "<leader><tab>o", "<cmd>tabonly<cr>", desc = "关闭其他标签页" },
			{ "<leader><tab><tab>", "<cmd>tabnew<cr>", desc = "新建标签页" },
		},
		opts = function(_, opts)
			-- 辅助函数：确保返回整数
			local function safe_int(val, max)
				if type(val) == "number" and val < 1 then
					return math.floor(max * val)
				end
				return val
			end

			local lines = vim.o.lines
			local cols = vim.o.columns

			-- 0. 覆盖 Snacks Toggle 默认图标为 Emoji
			opts.toggle = vim.tbl_deep_extend("force", opts.toggle or {}, {
				icon = {
					enabled = "✅ ",
					disabled = "❌ ",
				},
			})

			-- 1. 通知系统优化：开启自动换行与高度自适应
			opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
				style = "detailed",
				wrap = true,
				width = { min = 20, max = safe_int(0.4, cols) },
				height = { min = 1, max = safe_int(0.8, lines) },
				top = 3, -- 距离顶部向下移动 3 行（避开标签栏）
			})

			-- 2. 全局样式覆盖：确保换行在底层生效
			opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
				notification = { wo = { wrap = true, linebreak = true, breakindent = true } },
				detailed = { wo = { wrap = true, linebreak = true, breakindent = true } },
			})

			-- 3. Picker 全局视觉美化
			opts.picker = opts.picker or {}
			opts.picker.prompt = "" -- 严格还原原始设置

			-- 修复 Snacks.nvim explorer diagnostics 的 bug (buffer id 无效问题)
			vim.schedule(function()
				local ok, explorer_diags = pcall(require, "snacks.explorer.diagnostics")
				if ok and explorer_diags.update then
					local original_update = explorer_diags.update
					explorer_diags.update = function(cwd)
						-- 先过滤掉无效的 buffer
						local valid_diags = {}
						for _, diag in ipairs(vim.diagnostic.get()) do
							if diag.bufnr and vim.api.nvim_buf_is_valid(diag.bufnr) then
								table.insert(valid_diags, diag)
							end
						end
						-- 临时替换 vim.diagnostic.get
						local old_get = vim.diagnostic.get
						vim.diagnostic.get = function()
							return valid_diags
						end
						local ret = original_update(cwd)
						vim.diagnostic.get = old_get
						return ret
					end
				end
			end)

			-- 添加清除选择的动作
			opts.picker.actions = opts.picker.actions or {}
			opts.picker.actions.list_clear_selected = function(picker)
				picker.list:set_selected({})
			end

			-- 布局配置 - 控制宽度 (强制取整并为 select 提供固定尺寸)
			opts.picker.layouts = {
				default = {
					layout = {
						box = "horizontal",
						width = math.floor(safe_int(0.75, cols)),
						min_width = 80,
						height = math.floor(safe_int(0.8, lines)),
						{
							box = "vertical",
							border = "rounded",
							title = "{title} {live} {flags}",
							{ win = "input", height = 1, border = "bottom" },
							{ win = "list", border = "none" },
						},
						{
							win = "preview",
							title = "{preview}",
							border = "rounded",
							width = math.floor(safe_int(0.5, cols)),
						},
					},
				},
				vertical = {
					layout = {
						backdrop = false,
						width = math.floor(safe_int(0.75, cols)),
						min_width = 80,
						height = math.floor(safe_int(0.8, lines)),
						box = "vertical",
						border = "rounded",
						title = "{title} {live} {flags}",
						title_pos = "center",
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
						{
							win = "preview",
							title = "{preview}",
							height = math.floor(safe_int(0.4, lines)),
							border = "top",
						},
					},
				},
				telescope = {
					reverse = true,
					layout = {
						box = "horizontal",
						backdrop = false,
						width = math.floor(safe_int(0.75, cols)),
						height = math.floor(safe_int(0.9, lines)),
						border = "rounded",
						{
							box = "vertical",
							{ win = "list", title = " Results ", title_pos = "center", border = "rounded" },
							{
								win = "input",
								height = 1,
								border = "rounded",
								title = "{title} {live} {flags}",
								title_pos = "center",
							},
						},
						{
							win = "preview",
							title = "{preview:Preview}",
							width = math.floor(safe_int(0.45, cols)),
							border = "rounded",
							title_pos = "center",
						},
					},
				},
				select = {
					layout = {
						box = "vertical",
						backdrop = false,
						width = 60, -- 针对 Mason 等搜索框：使用固定整数宽度
						height = 12, -- 针对 Mason 等搜索框：使用固定整数高度
						border = "rounded",
						title = "{title}",
						title_pos = "center",
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
					},
				},
				ivy = {
					layout = {
						box = "vertical",
						backdrop = false,
						row = -1,
						width = math.floor(safe_int(0.75, cols)),
						height = math.floor(safe_int(0.4, lines)),
						border = "top",
						title = " {title} {live} {flags}",
						title_pos = "left",
						{ win = "input", height = 1, border = "bottom" },
						{
							box = "horizontal",
							{ win = "list", border = "none" },
							{
								win = "preview",
								title = "{preview}",
								width = math.floor(safe_int(0.5, cols)),
								border = "left",
							},
						},
					},
				},
			}

			-- 源特定增强
			opts.picker.sources = opts.picker.sources or {}

			-- 自定义文件预览函数：使用真实 buffer 以获得完整的语法高亮
			local function real_buffer_preview(ctx)
				local Snacks = require("snacks")
				local path = ctx.item.file
				if not path then
					return Snacks.picker.preview.file(ctx)
				end

				-- 检查是否是目录
				if vim.fn.isdirectory(path) == 1 then
					return Snacks.picker.preview.directory(ctx)
				end

				-- 检查文件大小
				local stat = vim.uv.fs_stat(path)
				if not stat then
					ctx.preview:notify("文件不存在", "warn")
					return
				end
				local max_size = ctx.picker.opts.previewers.file.max_size or (10 * 1024 * 1024)
				if stat.size > max_size then
					ctx.preview:notify("文件过大 > 10MB", "warn")
					return
				end

				-- 设置标题
				local title = ctx.item.title or vim.fn.fnamemodify(path, ":t")
				ctx.preview:set_title(title)

				-- 总是创建新的预览 buffer（不复用编辑器中的 buffer，避免冲突）
				local preview_buf = vim.fn.bufadd(path)
				if not vim.api.nvim_buf_is_valid(preview_buf) then
					return Snacks.picker.preview.file(ctx)
				end

				-- 标记为预览 buffer
				vim.b[preview_buf].snacks_picker_loaded = true
				vim.b[preview_buf].snacks_preview = true -- 标记为预览 buffer，用于禁用 ghost text
				vim.bo[preview_buf].buflisted = false

				-- 加载 buffer 内容（如果还没加载）
				if not vim.api.nvim_buf_is_loaded(preview_buf) then
					vim.fn.bufload(preview_buf)
				end

				-- 再次检查 buffer 有效性
				if not vim.api.nvim_buf_is_valid(preview_buf) then
					return Snacks.picker.preview.file(ctx)
				end

				-- 设置预览窗口的 buffer
				ctx.preview:set_buf(preview_buf)

				-- 标记此窗口为预览窗口（其他插件可据此禁用功能）
				local preview_win_id = ctx.preview.win.win
				if preview_win_id and vim.api.nvim_win_is_valid(preview_win_id) then
					vim.w[preview_win_id].is_snacks_preview = true
				end

				-- 在预览窗口设置 Tab 键映射（切换回输入框）
				-- 只设置一次，避免重复
				if not vim.b[preview_buf].tab_keymap_set then
					if preview_win_id and vim.api.nvim_win_is_valid(preview_win_id) then
						vim.api.nvim_buf_set_keymap(preview_buf, "n", "<Tab>", "", {
							callback = function()
								-- 切换回输入框（使用 win.win 获取实际的窗口 ID）
								local input_win_id = ctx.picker.input.win.win
								if input_win_id and vim.api.nvim_win_is_valid(input_win_id) then
									vim.api.nvim_set_current_win(input_win_id)
								end
							end,
							nowait = true,
							silent = true,
						})
						vim.b[preview_buf].tab_keymap_set = true
					end
				end

				-- 设置位置
				ctx.preview:loc()
			end

			-- 为常用源添加 Tab 键支持
			for _, source in ipairs({ "files", "recent", "buffers", "git_status", "git_log" }) do
				opts.picker.sources[source] = opts.picker.sources[source] or {}
				opts.picker.sources[source].layout = opts.picker.sources[source].layout or "default"

				-- 只为 files 和 recent 使用自定义预览（获得完整语法高亮）
				if source == "files" or source == "recent" then
					opts.picker.sources[source].preview = real_buffer_preview
				end

				-- 为所有源添加 Tab 键支持（预览窗口支持 insert 和 normal 模式）
				opts.picker.sources[source].win = vim.tbl_deep_extend("force", opts.picker.sources[source].win or {}, {
					input = { keys = { ["<Tab>"] = { "focus_preview", mode = { "i", "n" } } } },
					list = { keys = { ["<Tab>"] = { "focus_preview", mode = { "n" } } } },
					preview = { keys = { ["<Tab>"] = { "focus_input", mode = { "i", "n" } } } },
				})
			end

			-- 图标插件布局：增加边框并限制大小
			opts.picker.sources.icons = {
				layout = {
					layout = {
						box = "vertical",
						border = "rounded",
						title = " 图标插件 ",
						title_pos = "center",
						width = safe_int(0.75, cols),
						height = safe_int(0.7, lines),
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
					},
				},
			}

			-- 诊断布局：增加边框并限制大小
			opts.picker.sources.diagnostics = {
				layout = {
					layout = {
						box = "vertical",
						border = "rounded",
						title = " 诊断信息 ",
						title_pos = "center",
						width = safe_int(0.75, cols),
						height = safe_int(0.7, lines),
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
					},
				},
			}

			-- 文档符号布局：增加边框并限制大小
			opts.picker.sources.lsp_symbols = {
				layout = {
					layout = {
						box = "vertical",
						border = "rounded",
						title = " 文档符号 ",
						title_pos = "center",
						width = safe_int(0.75, cols),
						height = safe_int(0.7, lines),
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
					},
				},
			}

			-- 项目符号布局：增加边框并限制大小
			opts.picker.sources.lsp_workspace_symbols = {
				layout = {
					layout = {
						box = "vertical",
						border = "rounded",
						title = " 项目符号 ",
						title_pos = "center",
						width = safe_int(0.75, cols),
						height = safe_int(0.7, lines),
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
					},
				},
			} -- Buffer列表：显示固定状态图标
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
						width = safe_int(0.4, cols),
						min_width = 80,
						height = safe_int(0.4, lines),
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
		config = function(_, opts)
			require("snacks").setup(opts)

			-- 汉化翻译映射表
			local translations = {
				diagnostics = "诊断",
				files = "文件",
				buffers = "已打开文件",
				grep = "全局搜索",
				live_grep = "实时搜索",
				command_history = "命令历史",
				search_history = "搜索历史",
				git_status = "Git 状态",
				git_branches = "Git 分支",
				git_log = "Git 日志",
				git_files = "Git 文件",
				undo = "撤销历史",
				icons = "图标插件",
				keymaps = "快捷键",
				marks = "标记",
				projects = "项目",
				todo_comments = "待办事项",
			}

			-- 核心汉化逻辑函数
			local function translate_msg(msg)
				if type(msg) ~= "string" then
					return msg
				end
				local msg_low = msg:lower()
				if msg_low:find("no results") then
					local source = msg:match("`(.+)`") or msg:match("for%s+(.+)$")
					if source then
						local translated_source = translations[source] or source
						return ("未找到“%s”的相关结果"):format(translated_source)
					else
						return "未找到相关结果"
					end
				end
				return msg
			end

			-- 1. 拦截标准通知系统
			local original_notify = vim.notify
			vim.notify = function(msg, level, notify_opts)
				original_notify(translate_msg(msg), level, notify_opts)
			end

			-- 2. 拦截 Snacks 内部通知系统 (核心：彻底根治)
			local Snacks = require("snacks")

			if Snacks.notify then
				-- 拦截所有级别的通知函数 (info, warn, error, etc.)
				for _, method in ipairs({ "info", "warn", "error", "debug" }) do
					if Snacks.notify[method] then
						local original_method = Snacks.notify[method]
						Snacks.notify[method] = function(msg, notify_opts)
							original_method(translate_msg(msg), notify_opts)
						end
					end
				end
				-- 拦截通用 notify 方法
				local original_snack_notify = Snacks.notify.notify or Snacks.notify
				if type(original_snack_notify) == "function" then
					Snacks.notify.notify = function(msg, level, notify_opts)
						original_snack_notify(translate_msg(msg), level, notify_opts)
					end
				end
			end
		end,
	},
}
