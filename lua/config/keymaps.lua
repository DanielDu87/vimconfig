--==============================================================================
-- Neovim 键位映射配置
--==============================================================================
-- 这些键位映射会在 VeryLazy 事件时自动加载
--
-- LazyVim 已经预配置了大量实用的键位映射
-- 完整列表: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- 使用 :LazyKeys 命令或 <leader>sk 查看所有键位映射

--==============================================================================
-- 禁用 K 键 hover 功能
--==============================================================================
vim.keymap.set("n", "K", "<nop>", { desc = "禁用 K 键" })

--==============================================================================
-- DevDocs 文档搜索
--==============================================================================
local function open_url(url)
  local opener = (vim.fn.has("mac") == 1) and "open"
    or (vim.fn.has("win32") == 1) and "start"
    or "xdg-open"
  vim.fn.jobstart({ opener, url }, { detach = true })
end

local function devdocs_search(q)
  q = (q or vim.fn.expand("<cword>")):gsub(" ", "%%20")
  open_url("https://devdocs.io/#q=" .. q)
end

-- leader+k: 搜索当前单词
vim.keymap.set("n", "<leader>k", function()
  devdocs_search()
end, { desc = "搜索 DevDocs (当前单词)" })

-- leader+K: 输入查询
vim.keymap.set("n", "<leader>K", function()
  vim.ui.input({ prompt = "DevDocs 查询: " }, function(q)
    if q and #q > 0 then
      devdocs_search(q)
    end
  end)
end, { desc = "搜索 DevDocs (输入查询)" })

