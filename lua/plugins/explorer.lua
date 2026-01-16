--==============================================================================
-- Snacks.nvim 配置
--==============================================================================
-- 配置文件浏览器和启动行为

return {
	-- LazyVim 默认会安装 snacks.nvim；这里用 opts 扩展配置
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			--==============================================================================
			-- 启动时自动打开 Explorer
			--==============================================================================
			vim.api.nvim_create_autocmd("VimEnter", {
				group = vim.api.nvim_create_augroup("SnacksExplorerAutoStart", { clear = true }),
				callback = function()
					-- 是否"带文件启动"：argv 里存在非目录参数，就认为是打开文件启动
					local argv = vim.fn.argv()
					local has_file_arg = false
					for _, a in ipairs(argv) do
						-- nvim --some-flag 之类不算；目录也不算
						if not vim.startswith(a, "-") and vim.fn.isdirectory(a) == 0 then
							has_file_arg = true
							break
						end
					end

					-- 记录启动时的当前窗口（通常是文件窗口/初始窗口）
					local start_win = vim.api.nvim_get_current_win()

					vim.schedule(function()
						local ok, Snacks = pcall(require, "snacks")
						if not ok or not Snacks.explorer then
							return
						end

						local LazyVim = _G.LazyVim
						local root = vim.g.root_dir
							or (LazyVim and LazyVim.root and LazyVim.root.get and LazyVim.root.get())
							or vim.fn.getcwd()

						Snacks.explorer.open({ cwd = root })

						-- 焦点策略：
						-- 1) 有文件参数启动：焦点回到文件窗口
						-- 2) 无文件参数启动：焦点留在 Explorer（什么都不做）
						if has_file_arg then
							-- 使用多层 schedule 确保 Explorer 完全打开后再切换
							vim.schedule(function()
								vim.schedule(function()
									if vim.api.nvim_win_is_valid(start_win) then
										vim.api.nvim_set_current_win(start_win)
									end
								end)
							end)
						end
					end)
				end,
				desc = "启动时自动打开 Snacks Explorer",
			})
		end,
	},
}
