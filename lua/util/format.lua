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
		quiet = false, -- 显式开启错误提示
	})

	-- 2. 针对 HTML 的特殊智能空行控制
	if ft == "html" then
		-- 第一步：删除所有空行
		vim.cmd([[silent! %g/^\s*$/d]])
				-- 第二步：仅当 body 为空时 (<body></body>) 强制撑开空行，并保持闭合标签对齐
				-- 这里插入一个换行，再插入一个空行，最后在闭合标签前加一个 \t (如果您用的是 Tab)
				vim.cmd([[
		silent! %s/\(<body[^>]*>\)\(<\/body>\)/\1\r\r\t\2/e]])
				end

	-- 3. 统一清理行尾空白（通用操作）
	vim.cmd([[silent! %s/\s\+$//e]])

	-- 3. 恢复光标位置
	vim.fn.setpos(".", pos)
end

return M
