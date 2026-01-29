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
      {
        "<leader>c/",
        function()
          require("mini.comment").toggle()
        end,
        mode = { "n", "v" },
        desc = "切换行注释",
      },
    },
  },
}