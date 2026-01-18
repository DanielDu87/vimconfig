--==============================================================================
-- 行号颜色配置
--==============================================================================

vim.opt.number = true
vim.opt.relativenumber = true

local function set_line_number_hl()
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#909090", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#909090", bg = "NONE" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#909090", bg = "NONE" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffffff", bg = "NONE", bold = true })
end

-- VimEnter 时延迟执行，确保主题加载完成
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("LineNrColor", { clear = true }),
  callback = function()
    vim.schedule(set_line_number_hl)
  end,
})

-- ColorScheme 变化时重新应用
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("LineNrColorScheme", { clear = true }),
  callback = set_line_number_hl,
})

return {}
