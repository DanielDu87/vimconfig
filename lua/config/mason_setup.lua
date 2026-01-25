-- 自动确保 ruff 可用（通过 mason 管理）
-- 说明：
--  1. 如果你使用 Mason 管理工具，本模块会在 VeryLazy 时尝试确保 ruff 已安装。
--  2. 如果 mason / mason-registry 未就绪或网络不可用，会静默失败不影响启动。
local function ensure_ruff()
  local ok_mason, mason_registry = pcall(require, "mason-registry")
  if not ok_mason then
    return
  end

  local pkg_name = "ruff"
  if not mason_registry.is_installed(pkg_name) then
    local pkg = mason_registry.get_package(pkg_name)
    if pkg then
      -- 异步安装，避免阻塞启动
      vim.schedule(function()
        pcall(function() pkg:install() end)
      end)
    end
  end
end

-- 在 VeryLazy 阶段运行（若你的 LazyVim 支持 User events，可改为更合适的事件）
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    pcall(ensure_ruff)
  end,
  once = true,
})

