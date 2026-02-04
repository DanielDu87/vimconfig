--==============================================================================
-- Snacks.nvim Explorer 配置
--==============================================================================
-- 配置文件浏览器和启动行为

return {
	{
		"snacks.nvim",
		opts = function(_, opts)
			--==============================================================================
			-- Explorer 宽度持久化配置（必须先定义函数）
			--==============================================================================
			local width_file = vim.fn.stdpath("config") .. "/.explorer_width"

			-- 读取保存的宽度
			local function load_width()
				local f = io.open(width_file, "r")
				if f then
					local content = f:read("*a")
					f:close()
					return tonumber(content) or 30
				end
				return 30
			end

			--==============================================================================
			-- 一劳永逸锁定 Snacks 侧边栏宽度
			--==============================================================================
			vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
				pattern = { "snacks_picker*", "snacks_explorer*" },
				callback = function()
					vim.wo.winfixwidth = true
					-- 如果是已经存在的窗口，尝试强制同步宽度
					pcall(function()
						local current_width = load_width()
						if vim.api.nvim_win_get_width(0) ~= current_width then
							vim.api.nvim_win_set_width(0, current_width)
						end
					end)
				end,
			})

			--==============================================================================
			-- 浮动窗口边框配置
			--==============================================================================
			opts.terminal = opts.terminal or {}
			opts.terminal.border = "rounded"
			opts.styles = opts.styles or {}
			opts.styles.float = opts.styles.float or {}
			opts.styles.float.border = "rounded"
			opts.styles.float.backdrop = 100

			--==============================================================================
			-- 加载自定义 Actions
			--==============================================================================
			-- 将庞大的自定义操作逻辑移至 lua/util/explorer_actions.lua
			local Actions = require("snacks.explorer.actions")
			require("util.explorer_actions").setup(Actions, require("snacks"))

			--==============================================================================
			-- 配置 Explorer 布局与按键映射
			--==============================================================================
			opts.picker = opts.picker or {}
			opts.picker.sources = opts.picker.sources or {}
			opts.picker.sources.explorer = opts.picker.sources.explorer or {}
			opts.picker.sources.explorer.win = opts.picker.sources.explorer.win or {}
			opts.picker.sources.explorer.win.list = opts.picker.sources.explorer.win.list or {}
			opts.picker.sources.explorer.win.list.keys = opts.picker.sources.explorer.win.list.keys or {}

			-- 设置 x 键映射到剪切操作
			opts.picker.sources.explorer.win.list.keys["x"] = { "explorer_cut", mode = { "n", "x" } }
			-- 设置 Esc 键映射到取消多选 (针对 explorer 源)
			opts.picker.sources.explorer.win.list.keys["<Esc>"] = { "list_clear_selected", mode = { "n" } }

			-- 参考: https://github.com/folke/snacks.nvim/discussions/2139
			opts.picker.sources.explorer.layout = function()
				return {
					preset = "sidebar",
					preview = false,
					layout = {
						width = load_width(),
						-- 锁定宽度，防止窗口重排时被拉伸
						win_options = { winfixwidth = true },
					},
				}
			end
			opts.picker.sources.explorer.ignored = true -- 默认显示被 git 忽略的文件 (如 db.sqlite3)
			opts.picker.sources.explorer.hidden = false -- 默认不显示隐藏文件 (如 .env)

			--==============================================================================
			-- Explorer 宽度持久化配置（带防抖）
			--==============================================================================
			local width_save_timer = nil
			local function save_width_debounced(width)
				-- 取消之前的定时器
				if width_save_timer then
					width_save_timer:stop()
					width_save_timer:close()
				end
				-- 创建新的定时器（500ms 后执行）
				width_save_timer = vim.loop.new_timer()
				width_save_timer:start(
					500,
					0,
					vim.schedule_wrap(function()
						local f = io.open(width_file, "w")
						if f then
							f:write(tostring(width))
							f:close()
						end
						width_save_timer:close()
						width_save_timer = nil
					end)
				)
			end

			-- 使用 autocmd 在窗口调整大小时保存宽度（带防抖）
			vim.api.nvim_create_autocmd("WinResized", {
				group = vim.api.nvim_create_augroup("SnacksExplorerWidth", { clear = true }),
				callback = function(ev)
					-- 检查是否有 explorer picker 在运行
					local ok, pickers = pcall(function()
						return require("snacks.picker").get({ source = "explorer" })
					end)
					if not ok or not pickers or #pickers == 0 then
						return
					end
					-- 获取第一个 explorer picker
					local picker = pickers[1]
					if picker.closed then
						return
					end
					-- 延迟保存当前宽度
					local ok2, size = pcall(function()
						return picker.layout.root:size()
					end)
					if ok2 and size and size.width then
						save_width_debounced(size.width)
					end
				end,
			})

			-- 修复从输入模式退出后按键识别问题：确保退出输入模式时焦点返回列表
			-- 添加自定义动作来聚焦到列表
			opts.picker.actions = opts.picker.actions or {}
			opts.picker.actions.explorer_focus_list = function(picker)
				-- 聚焦到列表
				picker:focus("list", { show = false })
			end

			opts.picker.sources.explorer.win.input = opts.picker.sources.explorer.win.input or {}
			opts.picker.sources.explorer.win.input.keys = opts.picker.sources.explorer.win.input.keys or {}
			-- 覆盖默认的 cancel 行为，改为聚焦到列表
			opts.picker.sources.explorer.win.input.keys["<Esc>"] = { "explorer_focus_list", mode = { "i" } }

			--==============================================================================
			-- 配置诊断图标显示在 git 状态图标左边
			--==============================================================================
			opts.picker.sources.explorer.formatters = opts.picker.sources.explorer.formatters or {}
			opts.picker.sources.explorer.formatters.severity = {
				pos = "right",
				icons = true,
				level = false,
			}

			-- 覆盖 severity 格式化器，支持 col 参数
			local format_mod = require("snacks.picker.format")
			local original_severity = format_mod.severity
			format_mod.severity = function(item, picker)
				local ret = {} ---@type snacks.picker.Highlight[]
				local severity = item.severity
				severity = type(severity) == "number" and vim.diagnostic.severity[severity] or severity
				if not severity or type(severity) == "number" then
					return ret
				end
				---@cast severity string
				local lower = severity:lower()
				local cap = severity:sub(1, 1):upper() .. lower:sub(2)

				if picker.opts.formatters.severity.pos == "right" then
					-- 使用配置的 col 值，默认为 2（在 git 图标左边）
					local col_offset = picker.opts.formatters.severity.col or 2
					return {
						{
							col = col_offset,
							virt_text = { { picker.opts.icons.diagnostics[cap], "Diagnostic" .. cap } },
							virt_text_pos = "right_align",
							hl_mode = "combine",
						},
					}
				end

				if picker.opts.formatters.severity.icons then
					ret[#ret + 1] = { picker.opts.icons.diagnostics[cap], "Diagnostic" .. cap, virtual = true }
					ret[#ret + 1] = { " ", virtual = true }
				end

				if picker.opts.formatters.severity.level then
					ret[#ret + 1] = { lower:upper(), "Diagnostic" .. cap, virtual = true }
					ret[#ret + 1] = { " ", virtual = true }
				end

				return ret
			end

			--==============================================================================
			-- 处理目录参数启动
			--==============================================================================
			-- 检测是否以目录参数启动
			local start_with_dir = false
			for _, a in ipairs(vim.fn.argv()) do
				if not vim.startswith(a, "-") and vim.fn.isdirectory(a) == 1 then
					start_with_dir = true
					vim.cmd("cd " .. vim.fn.fnamemodify(a, ":p"))
					break
				end
			end

			--==============================================================================
			-- 修改 Git 文件颜色
			--==============================================================================
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("SnacksExplorerHighlight", { clear = true }),
				callback = function()
					-- 未跟踪文件：绿色
					vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { link = "String" })
					-- 已添加文件：黄色
					vim.api.nvim_set_hl(0, "SnacksPickerGitStatusAdded", { link = "DiagnosticWarn" })
					-- 已暂存修改：蓝色
					vim.api.nvim_set_hl(0, "SnacksPickerGitStatusStaged", { link = "DiagnosticInfo" })
					-- 目录树光标行颜色（设置更亮的背景色）
					vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = "#3b4261" })
				end,
			})
			-- 立即应用一次（防止 ColorScheme 已经加载过）
			vim.schedule(function()
				vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { link = "String" })
				vim.api.nvim_set_hl(0, "SnacksPickerGitStatusAdded", { link = "DiagnosticWarn" })
				vim.api.nvim_set_hl(0, "SnacksPickerGitStatusStaged", { link = "DiagnosticInfo" })
				vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = "#3b4261" })
			end)

			--==============================================================================
			-- 启动时自动打开 Explorer（仅当非目录参数启动时）
			--==============================================================================
			-- 只有在不以目录参数启动时才自动打开 Explorer
			if not start_with_dir then
				vim.api.nvim_create_autocmd("UiEnter", {
					group = vim.api.nvim_create_augroup("SnacksExplorerAutoStart", { clear = true }),
					once = true,
					callback = function()
						-- 如果是 Git 模式，则不自动打开 Explorer
						if os.getenv("NVIM_GIT_MODE") then
							return
						end
						vim.schedule(function()
							local ok, Snacks = pcall(require, "snacks")
							if not ok or not Snacks.explorer then
								return
							end

							-- 检查是否已经有 Explorer 窗口
							local has_explorer = false
							for _, win in ipairs(vim.api.nvim_list_wins()) do
								local buf = vim.api.nvim_win_get_buf(win)
								local buf_name = vim.api.nvim_buf_get_name(buf)
								if
									buf_name:match("[Ee]xplorer")
									or buf_name:match("[Ss]nacks")
									or buf_name:match("picker")
								then
									has_explorer = true
									break
								end
							end

							if not has_explorer then
								-- 检测是否有文件参数，并获取第一个文件所在目录
								local has_file_arg = false
								local file_dir = nil
								for _, a in ipairs(vim.fn.argv()) do
									if not vim.startswith(a, "-") and vim.fn.isdirectory(a) == 0 and a ~= "" then
										has_file_arg = true
										file_dir = vim.fn.fnamemodify(a, ":p:h")
										break
									end
								end

								-- 优先使用文件所在目录，否则使用 root_dir
								local root = file_dir
									or vim.g.root_dir
									or (_G.LazyVim and _G.LazyVim.root and _G.LazyVim.root.get and _G.LazyVim.root.get())
									or vim.fn.getcwd()
								Snacks.explorer.open({ cwd = root })

								-- 只有在带文件参数启动时才切换到编辑器窗口
								if has_file_arg then
									vim.defer_fn(function()
										for _, win in ipairs(vim.api.nvim_list_wins()) do
											local buf = vim.api.nvim_win_get_buf(win)
											local filetype = vim.bo[buf].filetype
											if
												filetype ~= "snacks_explorer"
												and filetype ~= "snacks_picker"
												and filetype ~= "snacks_input"
											then
												pcall(vim.api.nvim_set_current_win, win)
												break
											end
										end
									end, 10)
								end
							end
						end)
					end,
					desc = "启动时自动打开 Snacks Explorer",
				})
			end

			--==============================================================================
			-- 修复 Explorer 在文件切换后消失的问题
			--==============================================================================
			-- 方案：将 q 键映射为关闭 buffer（而非窗口），避免布局重排导致 Explorer 消失

			-------------------------------------------------------------------------------
			-- Pinned 状态管理（方案 B：自己维护，不依赖 bufferline 内部 API）
			-------------------------------------------------------------------------------
			---@param buf number
			---@return boolean
			local function is_pinned(buf)
				-- 优先检查我们自己的 pinned 状态
				if vim.b[buf].pinned then
					return true
				end
				-- 兼容其他人可能用的 buf var 名
				if vim.b[buf].bufferline_pinned then
					return true
				end
				-- 检查 bufferline groups 的 pinned 状态
				local ok_groups, groups = pcall(require, "bufferline.groups")
				local ok_state, state = pcall(require, "bufferline.state")
				if ok_groups and ok_state and state.components then
					for _, element in ipairs(state.components) do
						if element.id == buf and groups._is_pinned(element) then
							return true
						end
					end
				end
				return false
			end

			-- 1. 命令行模式 :q 和 :x 映射为保存后删除 buffer
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = function()
					vim.api.nvim_create_user_command("Q", function(opts)
						local buf = vim.api.nvim_get_current_buf()
						-- 检查 pinned
						if is_pinned(buf) then
							vim.notify("Buffer已固定，无法关闭", vim.log.levels.WARN)
							return
						end
						local bufname = vim.api.nvim_buf_get_name(buf)
						-- 先保存（如果有文件名且已修改）
						if bufname ~= "" and vim.bo[buf].modified then
							vim.api.nvim_buf_call(buf, function()
								vim.cmd("write")
							end)
						end
						-- 使用 Snacks.bufdelete 只删除当前 buffer
						require("snacks").bufdelete(buf, opts.bang)
					end, { bang = true, desc = "Write and delete buffer" })
					vim.cmd("cnoreabbrev q Q")
					vim.cmd("cnoreabbrev q! Q!")
					vim.cmd("cnoreabbrev x Q")
					vim.cmd("cnoreabbrev x! Q!")
				end,
			})

			-- 2. 普通模式 q 键映射
			vim.api.nvim_create_autocmd("BufWinEnter", {
				group = vim.api.nvim_create_augroup("SnacksExplorerQKey", { clear = true }),
				callback = function(ev)
					-- 只对普通文件生效
					local buftype = vim.bo[ev.buf].buftype
					local filetype = vim.bo[ev.buf].filetype
					-- 排除特殊缓冲区
					if buftype ~= "" then
						return
					end
					-- 排除 Explorer 和 picker 等特殊类型
					if filetype == "snacks_explorer" or filetype == "snacks_picker" or filetype == "snacks_input" then
						return
					end
					-- 为这个 buffer 设置 q 键映射 (保存后删除 buffer)
					vim.keymap.set("n", "q", function()
						local buf = ev.buf
						-- 检查 pinned
						if is_pinned(buf) then
							vim.notify("Buffer已固定，无法关闭", vim.log.levels.WARN)
							return
						end
						-- 先保存当前 buffer（如果有文件名且已修改）
						local bufname = vim.api.nvim_buf_get_name(buf)
						if bufname ~= "" and vim.bo[buf].modified then
							vim.api.nvim_buf_call(buf, function()
								vim.cmd("write")
							end)
						end
						-- 使用 Snacks.bufdelete 只删除当前 buffer
						require("snacks").bufdelete(buf)
					end, {
						buffer = ev.buf,
						desc = "Write and delete buffer (keep window layout)",
					})
				end,
				desc = "将 q 键映射为关闭 buffer，保护 Explorer 窗口布局",
			})

			-- 3. Option+q 切换目录树
			vim.keymap.set("n", "<M-q>", function()
				local Snacks = require("snacks")
				Snacks.explorer()
			end, { desc = "Toggle Explorer" })

			-- 4. Option+=/- 切换 buffer
			vim.keymap.set("n", "<M-=>", function()
				vim.cmd("bnext")
			end, { desc = "Next buffer" })
			vim.keymap.set("n", "<M-->", function()
				vim.cmd("bprevious")
			end, { desc = "Previous buffer" })

			--==============================================================================
			-- 行内快速移动
			--==============================================================================
			-- 定义 <Plug> 映射作为动作基础
			vim.keymap.set({ "n", "o", "x" }, "<Plug>(MotionLineStart)", "^", { desc = "Motion to line start" })
			vim.keymap.set({ "n", "o", "x" }, "<Plug>(MotionLineEnd)", "$", { desc = "Motion to line end" })

			-- Normal 模式快捷移动
			vim.keymap.set("n", "<M-h>", "<Plug>(MotionLineStart)", { desc = "Move to line start" })
			vim.keymap.set("n", "<M-l>", "<Plug>(MotionLineEnd)", { desc = "Move to line end" })

			-- Operator-pending 模式（配合 d, c, y 等操作符）
			vim.keymap.set("o", "<M-h>", "<Plug>(MotionLineStart)", { desc = "Operator: to line start" })
			vim.keymap.set("o", "<M-l>", "<Plug>(MotionLineEnd)", { desc = "Operator: to line end" })

			-- Visual 模式扩展选择
			vim.keymap.set("x", "<M-h>", "^", { desc = "Visual select to line start" })
			vim.keymap.set("x", "<M-l>", "$", { desc = "Visual select to line end" })

			--==============================================================================
			-- 屏幕滚动
			--==============================================================================
			-- Alt + z 跳转到文件末尾并居中
			vim.keymap.set({ "n", "i" }, "<M-z>", function()
				vim.cmd("normal! Gzz")
			end, { desc = "Go to end of file and center" })

			return opts
		end,
	},

	--==============================================================================
	-- 覆盖 LazyVim 的 bufferline 配置
	--==============================================================================
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			opts.options = opts.options or {}
			opts.options.always_show_bufferline = true
			return opts
		end,
		config = function(_, opts)
			require("bufferline").setup(opts)
			-- 使用 ColorScheme 事件确保在主题加载后设置高亮
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("BufferlineHighlights", { clear = true }),
				callback = function()
					-- 设置未激活标签页的文字颜色（更亮）
					vim.api.nvim_set_hl(0, "BufferLineBackground", { fg = "#9aa5ce", bold = true })
					vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { fg = "#9aa5ce", bold = true })
					-- 为当前选中的buffer添加下划线（指定下划线颜色）
					vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { underline = true, sp = "#2b85b7", bold = true })
					-- 为有错误/警告的当前buffer也添加下划线
					vim.api.nvim_set_hl(0, "BufferLineErrorSelected", { underline = true, sp = "#2b85b7", bold = true })
					vim.api.nvim_set_hl(0, "BufferLineWarningSelected", { underline = true, sp = "#2b85b7", bold = true })
					vim.api.nvim_set_hl(0, "BufferLineInfoSelected", { underline = true, sp = "#2b85b7", bold = true })
					vim.api.nvim_set_hl(0, "BufferLineHintSelected", { underline = true, sp = "#2b85b7", bold = true })
				end,
			})
			-- 立即执行一次
			vim.cmd("doautocmd ColorScheme")
		end,
		keys = {
			{
				"<leader>bp",
				function()
					vim.cmd("BufferLineTogglePin")
				end,
				desc = "切换固定",
			},
		},
	},
}
