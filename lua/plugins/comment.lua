return {
  {
    "nvim-mini/mini.comment",
    event = "VeryLazy",
    opts = {
      options = {
        custom_commentstring = function()
          -- 安全调用，以防 ts_context_commentstring 不可用
          local ok, ts_comment = pcall(require, "ts_context_commentstring.internal")
          if ok then
            return ts_comment.calculate_commentstring() or vim.bo.commentstring
          end
          return vim.bo.commentstring
        end,
      },
    },
    config = function(_, opts)
      require("mini.comment").setup(opts)
    end,
    keys = {
      -- 使用 remap = true 来调用插件内置的 gc 映射，确保逻辑一致且无报错
      { "<leader>c/", "gcc", mode = "n", remap = true, desc = "切换行注释" },
      { "<leader>c/", "gc", mode = "v", remap = true, desc = "切换选区注释" },
    },
  },
}
