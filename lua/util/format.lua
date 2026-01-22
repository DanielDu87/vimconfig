local M = {}

--==============================================================================
-- 格式化配置映射表
--==============================================================================
local ft_configs = {
	-- HTML: 使用 fallback，且需要额外清理空行
	html = { lsp_format = "fallback", clean_blank_lines = true },
	-- Python: 禁用 LSP 格式化，完全信任 conform (black/isort)
	python = { lsp_format = "never" },
	-- Dockerfile: 禁用 LSP (dockerls 不做大写转换)，强制使用 conform (perl)
	dockerfile = { lsp_format = "never" },
	-- SQL: 禁用 LSP 格式化，强制使用 sql-formatter
	sql = { lsp_format = "never" },
	-- Go: 禁用 LSP，强制使用 goimports
	go = { lsp_format = "never" },
	-- 默认配置
	["_"] = { lsp_format = "fallback" },
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
	})

	-- 2. 统一清理行尾空白（通用操作）
	vim.cmd([[silent! %s/\s\+$//e]])

	-- 3. 特殊清理逻辑：清理 HTML 中的冗余空行
	if config.clean_blank_lines then
		vim.cmd([[silent! %g/^\s*$/d]])
	end

	-- 4. 恢复光标位置
	vim.fn.setpos(".", pos)
end

return M
