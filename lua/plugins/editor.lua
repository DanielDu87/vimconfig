--==============================================================================
-- Editor 插件配置：覆盖 LazyVim 默认的编辑器行为
--==============================================================================
-- 本文件主要配置：
-- 1. 快捷键重新组织 (将窗口/缓冲区操作归类)
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
		-- 临时缓冲区：统一移到 <leader>S (Scratch) 组
		-- ---------------------------------------------------------------------------
		vim.keymap.del("n", "<leader>.")

		-- ---------------------------------------------------------------------------
		-- 缓冲区管理：清理默认的冗余键位
		-- ---------------------------------------------------------------------------
		vim.keymap.del("n", "<leader>`") -- 切换到上一个缓冲区
		vim.keymap.del("n", "<leader>,") -- 缓冲区列表
		vim.keymap.del("n", "<leader>br") -- LazyVim 默认的向右关闭
		vim.keymap.del("n", "<leader>bl") -- LazyVim 默认的向左关闭

		-- 设置更直观的缓冲区导航 (小写 h/l)
		vim.keymap.set("n", "<leader>bh", "<cmd>bprevious<cr>", { desc = "上一个缓冲区" })
		vim.keymap.set("n", "<leader>bl", "<cmd>bnext<cr>", { desc = "下一个缓冲区" })

		-- ---------------------------------------------------------------------------
		-- 辅助函数：批量关闭缓冲区逻辑（跳过固定/Pinned缓冲区）
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

		-- 关闭当前缓冲区左侧所有非固定文件
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
			vim.notify(string.format("已清理左侧 %d 个文件", closed), vim.log.levels.INFO)
		end

		-- 关闭当前缓冲区右侧所有非固定文件
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
			vim.notify(string.format("已清理右侧 %d 个文件", closed), vim.log.levels.INFO)
		end

		-- 绑定批量关闭键位 (大写 H/L)
		vim.keymap.set("n", "<leader>bH", close_left_non_pinned, { desc = "关闭左侧所有缓冲区" })
		vim.keymap.set("n", "<leader>bL", close_right_non_pinned, { desc = "关闭右侧所有缓冲区" })
	end,
})

--==============================================================================
-- 2. 优化 <leader>bP：关闭非固定文件并锁定侧边栏布局
--==============================================================================
-- 此逻辑专门修复在关闭大量缓冲区时，侧边栏（如目录树）被系统均分导致的闪烁和变形
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

			vim.notify(string.format("清理完成，共关闭 %d 个文件", count), vim.log.levels.INFO)
		end

		vim.keymap.set("n", "<leader>bP", close_non_pinned_buffers_preserve_side_width, {
			desc = "清理所有非固定缓冲区",
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
				width = 0.8,
				height = { min = 4, max = math.huge },
				col = 0.5,
				row = 0.8,
				border = "rounded",
				title = "  ◈ 快捷操作菜单 ◈  ",
				title_pos = "center",
				wo = {
					conceallevel = 0,
					winhighlight = "Normal:WhichKeyNormal,FloatBorder:WhichKeyBorder",
				},
			},
			-- 分组定义与中文化
			spec = {
				{ "<leader>b", group = "缓冲区 (Buffer)", icon = "🗂️" },
				{ "<leader>c", group = "代码 (Code)", icon = "🛠️" },
				{ "<leader>d", group = "调试 (Debug)", icon = "🔧" },
				{ "<leader>e", group = "文件浏览器", icon = "📂" },
				{ "<leader>f", group = "文件查找 (Find)", icon = "📁" },
				{ "<leader>g", group = "Git版本控制", icon = "🧡" },
				{ "<leader>h", group = "历史记录", icon = "📜" },
				{ "<leader>q", group = "退出/会话", icon = "🚪" },
				{ "<leader>s", group = "全局搜索 (Search)", icon = "🔍" },
				{ "<leader>S", group = "临时缓冲区 (Scratch)", icon = "📝" },
				{ "<leader>u", group = "界面美化 (UI)", icon = "🎨" },
				{ "<leader>w", group = "窗口管理 (Window)", icon = "🖼️" },
				{ "<leader>x", group = "诊断修复 (Diagnostic)", icon = "⚠️" },
				-- 键位功能补充
				{ "<leader>Ss", desc = "默认临时缓冲区" },
				{ "<leader>Sn", desc = "新建命名缓冲区" },
				{ "<leader>SS", desc = "缓冲区管理中心" },
				-- 忽略已移动的功能项，防止菜单重复显示
				{ "<leader>-", desc = "which_key_ignore" },
				{ "<leader>|", desc = "which_key_ignore" },
				{ "<leader>.", desc = "which_key_ignore" },
				{ "<leader>`", desc = "which_key_ignore" },
				{ "<leader>,", desc = "which_key_ignore" },
				{ "<leader>br", desc = "which_key_ignore" },
			},
			-- 批量描述替换 (将插件自带的英文描述翻译为中文)
			replace = {
				desc = {
					{ "Keywordprg", "关键词查询" },
					{ "Explorer", "文件浏览器" },
					{ "Buffers", "缓冲区列表" },
					{ "Recent", "最近打开文件" },
					{ "Projects", "项目列表" },
					{ "Command History", "命令执行历史" },
					{ "Search History", "搜索匹配历史" },
					{ "Diagnostics", "诊断信息" },
					{ "Goto Definition", "跳转到定义" },
					{ "Next Diagnostic", "下一个诊断" },
					{ "Prev Diagnostic", "上一个诊断" },
					{ "Format", "智能格式化" },
					{ "Line Diagnostics", "当前行诊断" },
					{ "Toggle Pin", "固定缓冲区" },
					{ "Save File", "保存当前文件" },
					{ "Quit All", "退出所有窗口" },
					-- 搜索/Grep 相关补全
					{ "Grep", "正则搜索" },
					{ "Grep (Root Dir)", "全局正则搜索" },
					{ "Grep (cwd)", "当前目录正则搜索" },
					{ "Word (Root Dir)", "全局单词搜索" },
					{ "Word (cwd)", "当前目录单词搜索" },
					{ "Find Files (Root Dir)", "查找文件 (根目录)" },
					{ "Find Files (cwd)", "查找文件 (当前目录)" },
				},
			},
		},
		config = function(_, opts)
			-- 自定义 WhichKey 的视觉高亮，确保与 Snacks 风格一致
			vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#2b85b7", default = true })
			vim.api.nvim_set_hl(0, "WhichKeyNormal", { bg = "#1a1b26", default = true })
			require("which-key").setup(opts)
		end,
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
				desc = "文件浏览器 (项目根目录)",
			},
			{
				"<leader>fE",
				function()
					require("snacks").explorer()
				end,
				desc = "文件浏览器 (当前所在目录)",
			},
			{ "<leader>e", "<leader>fe", desc = "文件浏览器", remap = true },

			-- 临时缓冲区操作
			{
				"<leader>Ss",
				function()
					require("snacks").scratch({ ft = "" })
				end,
				desc = "打开默认临时缓冲区",
			},
			{
				"<leader>Sn",
				function()
					require("snacks").scratch({ name = vim.fn.input("缓冲区名称: "), ft = "" })
				end,
				desc = "新建命名临时缓冲区",
			},
			{
				"<leader>S.",
				function()
					require("snacks").scratch()
				end,
				desc = "切换临时缓冲区",
			},
			{
				"<leader>SS",
				function()
					require("snacks").picker.scratch()
				end,
				desc = "临时缓冲区管理",
			},

			-- 缓冲区与窗口操作
			{ "<leader>bb", "<cmd>e #<cr>", desc = "快速切换回上个文件" },
			{
				"<leader>bf",
				function()
					require("snacks").picker.buffers()
				end,
				desc = "已打开文件列表",
			},

			-- 窗口管理：原生操作符映射
			{ "<leader>w-", "<C-W>s", desc = "横向分割窗口", remap = true },
			{ "<leader>w|", "<C-W>v", desc = "纵向分割窗口", remap = true },
			{ "<leader>wd", "<C-W>c", desc = "关闭当前窗口", remap = true },
			{ "<leader>wh", "<C-W>h", desc = "移至左侧窗口", remap = true },
			{ "<leader>wj", "<C-W>j", desc = "移至下方窗口", remap = true },
			{ "<leader>wk", "<C-W>k", desc = "移至上方窗口", remap = true },
			{ "<leader>wl", "<C-W>l", desc = "移至右侧窗口", remap = true },
			{ "<leader>wH", "<C-W>H", desc = "窗口左移", remap = true },
			{ "<leader>wJ", "<C-W>J", desc = "窗口下移", remap = true },
			{ "<leader>wK", "<C-W>K", desc = "窗口上移", remap = true },
			{ "<leader>wL", "<C-W>L", desc = "窗口右移", remap = true },
			{ "<leader>w=", "<C-W>=", desc = "自动均分窗口大小", remap = true },
			{ "<leader>ww", "<C-W>w", desc = "切换至其他窗口", remap = true },
			{
				"<leader>wm",
				function()
					require("snacks").toggle.zoom()
				end,
				desc = "最大化/恢复窗口状态",
			},

			-- 快捷搜索：/ 和 ?
			{ "/", snacks_lines, desc = "精准行搜索 (当前文件)", mode = { "n", "v" } },
			{ "?", snacks_lines, desc = "精准行搜索 (当前文件)", mode = { "n", "v" } },
		},

		opts = function(_, opts)
			-- Picker 全局视觉美化
			opts.picker = opts.picker or {}
			opts.picker.prompt = " " -- 清空提示符，保持简洁
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
				wo = { statuscolumn = "", signcolumn = "no", number = false, concealcursor = "n" },
			}

			-- 源特定增强
			opts.picker.sources = opts.picker.sources or {}
			-- 缓冲区列表：显示固定状态图标
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
