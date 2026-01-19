--==============================================================================
-- Lazy.nvim 中文界面
--==============================================================================
return {
	{
		"folke/lazy.nvim",
		opts = function()
			-- 覆盖 Lazy.nvim UI 文本
			local Util = require("lazy.util")
			local Config = require("lazy.core.config")
			local Loader = require("lazy.core.loader")

			-- 保存原始函数
			local original_handler = nil

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
			local function translate(text)
				return translations[text] or text
			end

			-- 在 Lazy UI 打开时进行文本替换
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "lazy://*",
				callback = function(ev)
					local buf = ev.buf
					-- 延迟执行，确保 UI 渲染完成
					vim.defer_fn(function()
						if not vim.api.nvim_buf_is_valid(buf) then
							return
						end
						-- 获取所有行
						local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
						local modified = false
						for i, line in ipairs(lines) do
							-- 翻译菜单项
							local new_line = line
							for en, zh in pairs(translations) do
								new_line = new_line:gsub(en, zh)
							end
							if new_line ~= line then
								lines[i] = new_line
								modified = true
							end
						end
						if modified then
							vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
						end
					end, 50)
				end,
			})

			-- 持续翻译（应对动态内容）
			vim.api.nvim_create_autocmd("BufWinEnter", {
				pattern = "lazy://*",
				callback = function(ev)
					local buf = ev.buf
					local timer = vim.loop.new_timer()
					timer:start(100, 200, vim.schedule_wrap(function()
						if not vim.api.nvim_buf_is_valid(buf) then
							timer:stop()
							timer:close()
							return
						end
						local win = vim.fn.bufwinid(buf)
						if win == -1 then
							timer:stop()
							timer:close()
							return
						end
						local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
						local modified = false
						for i, line in ipairs(lines) do
							local new_line = line
							for en, zh in pairs(translations) do
								new_line = new_line:gsub(en, zh)
							end
							if new_line ~= line then
								lines[i] = new_line
								modified = true
							end
						end
						if modified then
							vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
						end
					end))
				end,
			})
		end,
	},
}
