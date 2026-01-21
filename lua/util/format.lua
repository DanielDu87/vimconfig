local M = {}

---@class FormatOpts
---@field force? boolean

-- 通用格式化函数
---@param opts? FormatOpts
function M.format(opts)
	local ft = vim.bo.filetype

	if ft == "html" then
		-- HTML 格式化 + 清理空行
		local pos = vim.fn.getpos(".")
		require("conform").format({ lsp_format = "fallback" })
		vim.cmd([[silent! %s/\s\+$//e]])
		vim.cmd([[silent! %g/^\s*$/d]])
		vim.fn.setpos(".", pos)
	elseif ft == "python" then
		-- Python 格式化 + 清理行尾空白
		vim.b.autoformat = false
		local pos = vim.fn.getpos(".")
		require("conform").format({ lsp_format = "never" })
		vim.cmd([[silent! %s/\s\+$//e]])
		vim.fn.setpos(".", pos)
	else
		-- 其他文件：LazyVim 格式化 + 清理行尾空白
		local pos = vim.fn.getpos(".")
		require("lazyvim.util.format").format({ force = true })
		vim.cmd([[silent! %s/\s\+$//e]])
		vim.fn.setpos(".", pos)
	end
end

return M
