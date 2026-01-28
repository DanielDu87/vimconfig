local M = {}

--==============================================================================
-- 格式化配置映射表
--==============================================================================
local ft_configs = {
	-- HTML: 使用 fallback
	html = { lsp_format = "fallback" },
	-- Python: 禁用 LSP 格式化，完全信任 conform (black/isort)
	python = { lsp_format = "never" },
	-- Dockerfile: 禁用 LSP (dockerls 不做大写转换)，强制使用 conform (perl)
	dockerfile = { lsp_format = "never" },
	-- SQL: 禁用 LSP 格式化，强制使用 sql-formatter
	sql = { lsp_format = "never" },
	-- Go: 禁用 LSP，强制使用 goimports
	go = { lsp_format = "never" },
	-- 默认配置
	["_"] = { lsp_format = "never" },
}

---@class FormatOpts
---@field force? boolean

--==============================================================================
-- 统一格式化逻辑
--==============================================================================
---@param opts? FormatOpts
function M.format(opts)
	local ft = vim.bo.filetype
	local config = ft_configs[ft] or ft_configs["_"]
	local pos = vim.fn.getpos(".")

	-- 1. 调用 Conform 进行格式化（强制同步执行）
	require("conform").format({
		lsp_format = config.lsp_format,
		async = false,
		timeout_ms = 5000,
		quiet = true, -- 我们手动处理报错显示
	}, function(err)
		if err then
			-- -----------------------------------------------------------------------
			-- 通用报错信息深度清洗与美化逻辑 (健壮版)
			-- -----------------------------------------------------------------------
			local msg = type(err) == "string" and err or vim.inspect(err)
			if not msg or msg == "" then
				return
			end

			-- 1. 基础噪音过滤 (ANSI 颜色, 各种错误前缀)
			msg = msg:gsub("\27%[[0-9;]*m", "")
			msg = msg:gsub("Formatter '.-' .-: ", "")
			msg = msg:gsub("command failed[:%s]*", "")
			msg = msg:gsub("stderr[:%s]*", "")
			-- 移除 Prettier 常见的 [error] 或 error: 前缀
			msg = msg:gsub("%%[?[Ee][Rr][Rr][Oo][Rr]%%]?[:%s]*", "")

			-- 2. 移除长链接
			msg = msg:gsub("For more info see https?://%S+", "")

			-- 3. 智能路径缩减：将 /Users/xxx/path/to/file.ext 缩短为 file.ext
			-- 使用兼容性更好的匹配模式
			msg = msg:gsub("/[%w%._%-%s/]+/([%w%._%-%s]+)", "%1")

			-- 4. 修复语法错误名称
			msg = msg:gsub("SyntaxUnexpected", "SyntaxError: Unexpected")
			msg = vim.trim(msg)

			-- 5. 万能代码预览对齐处理 (使用 pcall 确保安全)
			local ok, final_msg = pcall(function()
				local lines_table = {}
				for line in msg:gmatch("[^\r\n]+") do
					local trimmed = line:gsub("^%s*", "")
					if trimmed:match("|") then
						if trimmed:match("^>") then
							table.insert(lines_table, trimmed)
						elseif trimmed:match("^%d+") then
							table.insert(lines_table, "  " .. trimmed)
						elseif trimmed:match("^|") then
							table.insert(lines_table, "     " .. trimmed)
						else
							table.insert(lines_table, "  " .. trimmed)
						end
					else
						table.insert(lines_table, line)
					end
				end
				return table.concat(lines_table, "\n")
			end)

			-- 发送通知
			vim.notify(ok and final_msg or msg, vim.log.levels.ERROR, {
				title = "代码格式化异常",
				icon = "󰉁",
			})
		end
	end)

	-- 2. 针对 HTML 的特殊智能空行控制
	if ft == "html" then
		vim.cmd([[silent! %g/^\s*$/d]])
		vim.cmd([[silent! %s/\(<body[^>]*>\)\(<\/body>\)/\1\r\r\t\2/e]])
	end

	-- 3. 统一清理行尾空白（通用操作）
	vim.cmd([[silent! %s/\s\+$//e]])

	-- 4. 恢复光标位置
	vim.fn.setpos(".", pos)
end

return M