-- Lua 配置：为 Python 启用 nvim-lint（使用 ruff）并在保存/打开时自动运行
-- 说明：
--  1. 依赖插件：mfussenegger/nvim-lint（已在插件列表中声明）
--  2. 需要在系统中安装 ruff（可使用 pipx/pip 或 Mason 安装）

local ok, lint = pcall(require, "lint")
if not ok then
  -- 若 nvim-lint 未安装，则静默失败（避免启动错误）
  return
end

-- 将 ruff 设为 Python 的 linter（若已在其他地方配置，这里不会覆盖）
lint.linters_by_ft = lint.linters_by_ft or {}
lint.linters_by_ft.python = lint.linters_by_ft.python or { "ruff" }

-- 自动在保存与读取后运行 lint（增加 BufEnter 以兼容快速切换）
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "BufEnter" }, {
  pattern = { "*.py" },
  callback = function(args)
    -- 仅对当前缓冲运行 lint，避免影响其它窗口
    pcall(function()
      require("lint").try_lint()
    end)
  end,
})

-- 提供命令快速触发
vim.api.nvim_create_user_command("RunPythonLint", function()
  pcall(function() require("lint").try_lint() end)
end, { desc = "对当前 Python 文件运行 ruff lint" })

