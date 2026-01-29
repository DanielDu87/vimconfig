return {
  "ethanamaher/better-git-blame.nvim",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "sindrets/diffview.nvim", -- Optional but highly recommended, and already installed
  },

  config = function()
    require("better-git-blame").setup({
      -- calling setup alone will setup the commands
    })
  end,
}