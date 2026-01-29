return {
  "zerbiniandrea/conventional-commits.nvim",
  cmd = "ConventionalCommit",
  config = function()
    require("conventional-commits").setup({
      show_emoji_step = true,
      show_preview = true,
      border = "rounded",
    })
  end,
}