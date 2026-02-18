--==============================================================================
-- Ghost 诊断全局状态管理（按文件类型）
--==============================================================================
-- 状态文件路径
local state_file = vim.fn.expand("~/Documents/neovim_files/ghost_diagnostic.json")

-- 存储每个文件类型是否启用 ghost 诊断
local ghost_state = {
	_by_ft = {}, -- 按文件类型存储：{ ["lua"] = true, ["python"] = false, ... }
}

-- 读取状态文件
local function load_state()
	local f = io.open(state_file, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local ok, data = pcall(vim.json.decode, content)
		if ok and type(data) == "table" then
			ghost_state._by_ft = data
		end
	end
end

-- 保存状态文件
local function save_state()
	local f = io.open(state_file, "w")
	if f then
		f:write(vim.json.encode(ghost_state._by_ft))
		f:close()
	end
end

-- 获取当前 buffer 文件类型的 ghost 状态
local function get_ghost_state(ft)
	if ghost_state._by_ft[ft] == nil then
		-- 默认启用
		return true
	end
	return ghost_state._by_ft[ft]
end

-- 设置文件类型的 ghost 状态
local function set_ghost_state(ft, enabled)
	ghost_state._by_ft[ft] = enabled
	save_state()
end

-- 切换当前 buffer 文件类型的 ghost 状态
local function toggle_ghost()
	local ft = vim.bo.filetype
	if ft == "" then
		vim.notify("当前文件无文件类型", vim.log.levels.WARN)
		return
	end

	local current_state = get_ghost_state(ft)
	local new_state = not current_state
	set_ghost_state(ft, new_state)

	-- 重新配置诊断
	local diag = require("tiny-inline-diagnostic")
	if new_state then
		diag.enable()
		vim.notify(("已启用 Ghost 诊断（%s）"):format(ft), vim.log.levels.INFO)
	else
		diag.disable()
		vim.notify(("已禁用 Ghost 诊断（%s）"):format(ft), vim.log.levels.INFO)
	end

	-- 触发诊断重新渲染
	vim.cmd("doautocmd DiagnosticChanged")
end

-- 根据 buffer 文件类型应用保存的 ghost 状态
local function apply_ghost_state_for_buffer(bufnr)
	bufnr = bufnr or 0
	local ft = vim.bo[bufnr].filetype
	local diag = require("tiny-inline-diagnostic")

	if ft == "" or ft:match("^snacks_") then
		diag.disable()
		return
	end

	local enabled = get_ghost_state(ft)
	if enabled then
		diag.enable()
	else
		diag.disable()
	end
end

return {
	-- 1. 配置 tiny-inline-diagnostic 插件（多行换行显示）
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy", -- 改为 VeryLazy 确保稳定加载
		priority = 1000, -- 提高优先级
		config = function()
			-- 加载保存的状态
			load_state()

			-- 必须在这里强制禁用原生虚拟文字，防止冲突
			vim.diagnostic.config({ virtual_text = false })

			-- 默认配置（启动时使用）
			require("tiny-inline-diagnostic").setup({
				preset = "ghost",
				hi = {
					-- 直接自定义高亮颜色，确保边缘符号和文字一致
					error = "DiagnosticError",
					warn = "DiagnosticWarn",
					info = "DiagnosticInfo",
					hint = "DiagnosticHint",
				},
				blend = {
					factor = 0, -- 完全禁用颜色混合
				},
				options = {
					show_source = false,
					throttle = 0,
					softwrap = 60,
					multilines = { enabled = true },
					overflow = { mode = "wrap" },
					overwrite_events = { "LspAttach", "DiagnosticChanged", "BufEnter", "BufWritePost" },
					enable_on_insert = true,
				},
			})

			-- 覆盖 tiny-inline-diagnostic 的高亮组函数
			local function fix_diagnostic_colors()
				-- 定义颜色
				local colors = {
					error = "#f7768e",
					warn = "#e0af68",
					info = "#7dcfff",
					hint = "#9aa5ce",
				}

				-- 计算背景色（基于当前背景的半透明混合）
				local bg_color = vim.o.background == "light" and "#ffffff" or "#1a1b26"

				for severity, color in pairs(colors) do
					local severity_cap = severity:sub(1, 1):upper() .. severity:sub(2)

					-- 计算半透明背景（20% 不透明度）
					-- 使用 vim.fn.tomix 无法直接做，这里使用预计算的值
					local ghost_bg = {
						error = "#3d2428",  -- 红色的半透明背景
						warn = "#3d3324",   -- 黄色的半透明背景
						info = "#1e2d3d",   -- 青色的半透明背景
						hint = "#24283d",   -- 蓝色的半透明背景
					}

					-- 设置文字高亮组
					vim.api.nvim_set_hl(0, "TinyInlineDiagnosticVirtualText" .. severity_cap, {
						fg = color,
						bg = ghost_bg[severity] or bg_color,
					})

					-- 设置边缘符号高亮组（使用相同的 fg 和 bg）
					vim.api.nvim_set_hl(0, "TinyInlineInvDiagnosticVirtualText" .. severity_cap, {
						fg = color,
						bg = ghost_bg[severity] or bg_color,
					})

					-- NoBg 变体
					vim.api.nvim_set_hl(0, "TinyInlineInvDiagnosticVirtualText" .. severity_cap .. "NoBg", {
						fg = color,
						bg = "NONE",
					})
				end
			end

			-- ColorScheme 时覆盖
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = function()
					vim.schedule(fix_diagnostic_colors)
				end,
			})

			-- 插件加载后立即覆盖
			vim.schedule(function()
				fix_diagnostic_colors()
			end)

			-- 立即应用当前状态
			apply_ghost_state_for_buffer()

			-- 当进入 buffer 时自动应用保存的 ghost 状态
			-- 但排除预览窗口
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function()
					-- 检查是否在预览窗口中
					local current_win = vim.api.nvim_get_current_win()
					if vim.w[current_win].is_snacks_preview then
						return
					end
					local current_buf = vim.api.nvim_get_current_buf()
					if vim.b[current_buf].snacks_preview then
						return
					end
					apply_ghost_state_for_buffer()
				end,
			})
		end,
		keys = {
			{
				"<leader>cg",
				function()
					toggle_ghost()
				end,
				desc = "切换 Ghost 诊断",
			},
		},
	},

	-- 2. 配置 LSP 诊断选项和重构键位（nvim-lspconfig）
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy",
		config = function()
			-- -----------------------------------------------------------------------
			-- 全局诊断配置：这是确保 tiny-inline-diagnostic 正常工作的关键
			-- -----------------------------------------------------------------------
			vim.diagnostic.config({
				virtual_text = false, -- 禁用原生虚拟文字，由 tiny-inline 接管
				signs = true,
				underline = true,
				update_in_insert = true,
				severity_sort = true,
				float = {
					header = "",
					source = "if_many",
					border = "rounded",
					focusable = false,
					focus = false,
				},
			})

			-- 设置 Visual 模式的智能重构键位
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimKeymaps",
				callback = function()
					vim.keymap.set("x", "<leader>cr", function()
						require("util.refactor_smart").smart_visual_refactor()
					end, { desc = "智能重构操作", remap = false })
				end,
				once = true,
			})
		end,
	},

	-- 3. 配置光标悬停自动显示诊断浮窗
	{
		"neovim/nvim-lspconfig",
		event = "LspAttach",
		callback = function(args)
			-- 光标停留时自动显示诊断浮窗
			vim.api.nvim_create_autocmd("CursorHold", {
				buffer = args.buf,
				callback = function()
					local opts = {
						focus = false,
						close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
						border = "rounded",
						source = "if_many",
						header = "",
						wrap = true,
					}
					local diagnostics = vim.diagnostic.get(args.buf, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
					if #diagnostics > 0 then
						vim.diagnostic.open_float(nil, opts)
					end
				end,
			})
		end,
	},
}
