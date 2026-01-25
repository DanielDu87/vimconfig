--==============================================================================
-- 代码重构插件配置 (Refactoring)
--==============================================================================
-- 本文件配置专业级的代码重构功能：
--
-- 插件组合：
--   1. refactoring.nvim  - 结构化重构（提取函数/变量、内联等）
--   2. inc-rename.nvim   - 带实时预览的重命名（自动接管 LSP 重命名）
--
-- 所有快捷键都在 <leader>c (代码操作) 组下
-- Visual 模式下选中代码后操作

return {
	--==========================================================================
	-- refactoring.nvim：结构化重构操作
	--==========================================================================
	{
		"ThePrimeagen/refactoring.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			-- 禁用类型提示（使用原生UI）
			prompt_func_return_type = {
				go = false,
				java = false,
				cpp = false,
				c = false,
				h = false,
				hpp = false,
				py = false,
			},
			prompt_func_param_type = {
				go = false,
				java = false,
				cpp = false,
				c = false,
				h = false,
				hpp = false,
				py = false,
			},
			printf_statements = {},
			print_var_statements = {},
			-- 自动进入 Insert 模式
			right_click_ctrl_o = true,
		},
		config = function(_, opts)
			require("refactoring").setup(opts)

			-- 自动进入 Insert 模式（当 refactoring 输入框出现时）
			local function start_insert_on_refactor()
				-- 使用 schedule 以防在创建缓冲的同一 tick 触发
				vim.schedule(function()
					-- 尝试多种进入 insert 的方法以提高兼容性
					local ok = pcall(vim.cmd, "startinsert")
					if not ok then
						-- 备选：通过 feedkeys 发送 'i'
						pcall(vim.api.nvim_feedkeys, vim.api.nvim_replace_termcodes("i", true, false, true), "n", false)
					end
				end)
			end

			-- 监听更多事件以覆盖不同环境下的显示方式
			local patterns = { "refactoring://*" }
			local events = { "BufEnter", "BufWinEnter", "WinEnter", "BufReadPost", "BufNewFile" }
			for _, ev in ipairs(events) do
				vim.api.nvim_create_autocmd(ev, {
					pattern = patterns,
					callback = start_insert_on_refactor,
				})
			end
			-- 兼容性：部分版本/配置会设置 filetype，监听 FileType 以确保进入 insert
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "refactoring",
				callback = start_insert_on_refactor,
			})
			-- 兼容 Snacks 插件的输入缓冲（filetype: snacks_input）
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "snacks_input",
				callback = start_insert_on_refactor,
			})

			-- 持续聚焦定时器：用于在某些情况下（其他插件或逻辑会抢焦点）重复将焦点切到 refactor 缓冲并进入 insert
			local focus_timers = {}
			local function start_focus_timer(bufnr)
				-- 清理已有定时器
				if focus_timers[bufnr] then
					pcall(function() focus_timers[bufnr]:stop(); focus_timers[bufnr]:close() end)
					focus_timers[bufnr] = nil
				end
				local timer = vim.loop.new_timer()
				local attempts = 0
				timer:start(0, 50, vim.schedule_wrap(function()
					attempts = attempts + 1
					if not vim.api.nvim_buf_is_valid(bufnr) then
						pcall(timer.stop, timer); pcall(timer.close, timer); focus_timers[bufnr] = nil; return
					end
					-- 在所有窗口中查找显示该缓冲的窗口并聚焦
					for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
						for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
							if vim.api.nvim_win_get_buf(win) == bufnr then
								pcall(vim.api.nvim_set_current_win, win)
								pcall(vim.cmd, "startinsert")
								break
							end
						end
					end
					-- 限制尝试次数（大约 50ms * 20 = 1s）
					if attempts >= 20 then
						pcall(timer.stop, timer); pcall(timer.close, timer); focus_timers[bufnr] = nil
					end
				end))
				focus_timers[bufnr] = timer
			end

			-- 当 refactoring 缓冲创建或显示时启动聚焦定时器
			vim.api.nvim_create_autocmd({ "BufCreate", "BufWinEnter", "BufEnter" }, {
				pattern = "refactoring://*",
				callback = function(args) start_focus_timer(args.buf) end,
			})
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "snacks_input",
				callback = function(args) start_focus_timer(args.buf) end,
			})
			-- 兼容 Snacks 插件的输入缓冲（filetype: snacks_input）
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "snacks_input",
				callback = start_insert_on_refactor,
			})
		end,
	},

	--==========================================================================
	-- inc-rename.nvim：带实时预览的重命名（自动接管 LSP 重命名）
	--==========================================================================
	{
		"smjonas/inc-rename.nvim",
		event = "BufRead",
		config = function()
			-- 自定义高亮样式
			vim.api.nvim_set_hl(0, "IncRenameTitle", { fg = "#2b85b7", bold = true })
			vim.api.nvim_set_hl(0, "IncRenameSignature", { fg = "#ff9e64", italic = true })
			vim.api.nvim_set_hl(0, "IncRenameMatch", { fg = "#7dcfff", underline = true, bold = true })

			require("inc_rename").setup({
				cmd_name = "IncRename",
				hl_group = "IncRenameMatch",
				border = {
					{ "┌", "IncRenameTitle" },
					{ "─", "IncRenameTitle" },
					{ "┐", "IncRenameTitle" },
					{ "│", "IncRenameTitle" },
					{ "┘", "IncRenameTitle" },
					{ "─", "IncRenameTitle" },
					{ "└", "IncRenameTitle" },
					{ "│", "IncRenameTitle" },
				},
				show_message = true,
				preview_empty_name = false,
				msg_format = function(details)
					local old_name = details.old_name
					local new_name = details.new_name
					local count = details.count
					return string.format("将 '%s' 重命名为 '%s' (%d 处修改)", old_name, new_name, count)
				end,
			})
		end,
	},
}
