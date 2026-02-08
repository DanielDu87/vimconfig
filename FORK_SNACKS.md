# Fork snacks.nvim 指南

## 为什么需要 Fork？

当前我们对 `snacks.nvim` 插件进行了以下修改：

1. **`tree.lua`**: 修改 `assert_dir` 函数，优雅处理非目录路径
2. **`preview.lua`**: 文件不存在时显示"文件已被删除"而不是错误

这些修改在插件更新后会丢失。通过 fork 可以永久保存这些修改。

## 快速开始

### 1. 在 GitHub 上 Fork

访问 https://github.com/folke/snacks.nvim 并点击右上角的 Fork 按钮。

你的 fork 地址应该是：`https://github.com/DanielDu87/snacks.nvim`

### 2. Clone 并应用修改

```bash
# Clone 你的 fork
git clone https://github.com/DanielDu87/snacks.nvim.git ~/Code/forks/snacks.nvim
cd ~/Code/forks/snacks.nvim

# 添加上游仓库
git remote add upstream https://github.com/folke/snacks.nvim.git

# 创建并切换到新分支
git checkout -b custom

# 应用修改（见下方）
```

### 3. 应用修改到文件

**修改 `lua/snacks/explorer/tree.lua` 第 32-34 行：**
```lua
local function assert_dir(path)
  if vim.fn.isdirectory(path) ~= 1 then
    return false
  end
  return true
end
```

**修改 `lua/snacks/picker/preview.lua` 第 131-134 行：**
```lua
      local stat = uv.fs_stat(path)
      if not stat then
        ctx.preview:notify("文件已被删除", "warn")
        return false
      end
```

### 4. 提交并推送

```bash
git add .
git commit -m "feat: 优化目录检测和书签处理"
git push -u origin custom
```

### 5. 更新 Neovim 配置

修改 `lua/plugins/overrides.lua`：

```lua
{
    "folke/snacks.nvim",
    priority = 1000,
    -- 使用你的 fork
    url = "https://github.com/DanielDu87/snacks.nvim.git",
    branch = "custom", -- 使用你的自定义分支
}
```

### 6. 更新插件

在 Neovim 中执行：
```vim
:Lazy sync
```

## 保持 Fork 与上游同步

定期合并上游更新：

```bash
cd ~/Code/forks/snacks.nvim
git fetch upstream
git rebase upstream/main
git push origin custom --force-with-lease
```
