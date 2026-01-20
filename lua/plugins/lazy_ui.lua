--==============================================================================
-- Lazy.nvim 中文界面
--==============================================================================
return {
	{
		"folke/lazy.nvim",
		opts = function()
			-- 中文翻译映射
			local translations = {
				["Home"] = "主页",
				["Install"] = "安装",
				["Update"] = "更新",
				["Sync"] = "同步",
				["Clean"] = "清理",
				["Check"] = "检查",
				["Log"] = "日志",
				["Restore"] = "恢复",
				["Profile"] = "性能",
				["Debug"] = "调试",
				["Help"] = "帮助",
				["Quit"] = "退出",
				["Close"] = "关闭",
				["Toggle Debug"] = "切换调试",
				["Select Scratch Buffer"] = "选择临时缓冲区",
			}

			-- 翻译函数
			local function translate_lines(lines)
				for i, line in ipairs(lines) do
					for en, zh in pairs(translations) do
						lines[i] = line:gsub(en, zh)
					end
				end
				return lines
			end

			-- Lazy UI 打开时翻译
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "lazy://*",
				callback = function(ev)
					vim.defer_fn(function()
						if not vim.api.nvim_buf_is_valid(ev.buf) then
							return
						end
						local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
						local translated = translate_lines(lines)
						vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, translated)
					end, 50)
				end,
			})

			-- 在用户操作后重新翻译（按键事件）
			vim.api.nvim_create_autocmd("BufWinEnter", {
				pattern = "lazy://*",
				callback = function(ev)
					vim.api.nvim_create_autocmd("FileType", {
						once = true,
						callback = function()
							if not vim.api.nvim_buf_is_valid(ev.buf) then
								return
							end
							local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
							local translated = translate_lines(lines)
							vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, translated)
						end,
					})
				end,
			})
		end,
	},
}
