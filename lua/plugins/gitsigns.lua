return {
  "lewis6991/gitsigns.nvim",
  config = function()
    -- 将 GitSignsCurrentLineBlame 的高亮设置为紫色
    vim.cmd("highlight GitSignsCurrentLineBlame guifg=#A020F0")
  end,
}