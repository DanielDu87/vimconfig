# Neovim 配置

基于 LazyVim 的个人 Neovim 配置，专注于 **前端 + Python + Docker** 开发。

## 配置文件结构

```
~/.config/nvim/
├── init.lua                    # 主入口文件
├── lua/
│   ├── config/                 # 核心配置目录
│   │   ├── lazy.lua           # lazy.nvim 配置
│   │   ├── options.lua        # 基础选项（透明度、缩进等）
│   │   ├── keymaps.lua        # 键位映射
│   │   └── autocmds.lua       # 自动命令
│   └── plugins/               # 插件配置目录
│       ├── extras.lua         # 所有 LazyVim extras
│       ├── editor.lua         # Which-key、Snacks 全局配置
│       ├── explorer.lua       # 文件浏览器（中文化）
│       ├── theme.lua          # Tokyo Night 主题 + 透明度
│       ├── highlight.lua      # Treesitter、彩虹括号等
│       ├── icons.lua          # 自定义文件图标
│       ├── lazy_ui.lua        # Lazy.nvim 中文界面
│       └── line-number.lua    # 行号颜色配置
```

## 已启用的语言支持

### 前端开发
- **TypeScript/JavaScript** - 完整支持，包括 JSX/TSX
- **Vue** - Vue 2/3 完整支持（Volar）
- **Tailwind CSS** - 类名补全和颜色预览
- **HTML/CSS** - 语法高亮、Emmet
- **ESLint** - 代码检查
- **Prettier** - 代码格式化

### Python 开发
- **Pyright** - 类型检查和智能补全
- **Black** - 代码格式化
- **Ruff** - 快速的 Python 检查和格式化
- **Debugpy** - Python 调试器

### Docker
- **Dockerfile** - 语法高亮
- **docker-compose** - 语法高亮
- **Hadolint** - Dockerfile 检查

### 配置文件
- **JSON/YAML** - 语法高亮和验证

## 快捷键

### 文件操作（Snacks Picker）

| 快捷键 | 说明 |
|--------|------|
| `<leader>ff` | 查找文件 |
| `<leader>fg` | 查找文本 |
| `<leader>fc` | 查找已打开文件 |
| `<leader>fr` | 最近文件 |
| `<leader>/` | 文件内容查找 |
| `/` 或 `?` | 当前文件搜索（非模糊匹配） |
| `<leader>fe` | 文件浏览器（根目录） |
| `<leader>fE` | 文件浏览器（当前目录） |
| `<leader>e` | 文件浏览器（同 `<leader>fe`） |

### 缓冲区操作

| 快捷键 | 说明 |
|--------|------|
| `<leader>bb` | 切换到其他缓冲区 |
| `<leader>bf` | 缓冲区列表 |
| `<leader>bd` | 关闭当前缓冲区 |
| `<leader>bD` | 关闭缓冲区和窗口 |
| `<leader>bh` | 上一个缓冲区 |
| `<leader>bl` | 下一个缓冲区 |
| `<leader>bo` | 关闭其他缓冲区 |
| `<leader>bp` | 切换固定状态（Pin） |
| `<M-=>` | 下一个缓冲区 |
| `<M-->` | 上一个缓冲区 |
| `q` | 关闭缓冲区（保持窗口布局） |

### 窗口操作（`<leader>w` 组）

| 快捷键 | 说明 |
|--------|------|
| `<leader>w-` | 向下分割窗口 |
| `<leader>w\|` | 向右分割窗口 |
| `<leader>wd` | 关闭当前窗口 |
| `<leader>wh` | 切换到左侧窗口 |
| `<leader>wj` | 切换到下方窗口 |
| `<leader>wk` | 切换到上方窗口 |
| `<leader>wl` | 切换到右侧窗口 |
| `<leader>wH` | 向左移动窗口 |
| `<leader>wJ` | 向下移动窗口 |
| `<leader>wK` | 向上移动窗口 |
| `<leader>wL` | 向右移动窗口 |
| `<leader>w=` | 均衡窗口大小 |
| `<leader>wm` | 最大化/恢复窗口 |
| `<leader>ww` | 切换到其他窗口 |

### 文件浏览器

| 快捷键 | 说明 |
|--------|------|
| `<M-q>` | 切换文件浏览器 |
| `<leader>H` | 切换显示隐藏文件 |
| `x` | 剪切文件 |
| `y` | 复制文件 |
| `p` | 粘贴文件 |
| `a` | 新建文件/目录 |
| `r` | 重命名文件 |
| `m` | 移动文件 |
| `d` | 删除文件 |
| `o` | 用系统默认程序打开 |

### 代码导航

| 快捷键 | 说明 |
|--------|------|
| `gd` | 跳转到定义 |
| `gD` | 跳转到声明 |
| `gr` | 查找引用 |
| `gi` | 跳转到实现 |
| `K` | 禁用（原本的 hover 功能） |
| `<leader>k` | 查询 DevDocs（当前关键词） |
| `<leader>K` | 搜索 DevDocs（输入查询） |

### 诊断与修复

| 快捷键 | 说明 |
|--------|------|
| `[d` | 上一个诊断 |
| `]d` | 下一个诊断 |
| `[e` | 上一个错误 |
| `]e` | 下一个错误 |
| `[w` | 上一个警告 |
| `]w` | 下一个警告 |
| `<leader>cf` | 格式化代码 |
| `<leader>ca` | 代码操作 |

### Git 操作

| 快捷键 | 说明 |
|--------|------|
| `<leader>gg` | 打开 Lazygit |
| `<leader>gb` | Git blame |
| `<leader>gs` | Git 状态 |
| `<leader>gd` | Git diff |
| `<leader>gh` | 变更历史 |

### 临时缓冲区（Scratch）

| 快捷键 | 说明 |
|--------|------|
| `<leader>Ss` | 打开默认临时缓冲区 |
| `<leader>Sn` | 新建命名临时缓冲区 |
| `<leader>S.` | 切换临时缓冲区 |
| `<leader>SS` | 选择/管理临时缓冲区 |

### 历史记录（`<leader>h` 组）

| 快捷键 | 说明 |
|--------|------|
| `<leader>hn` | 通知历史 |
| `<leader>hc` | 命令历史 |
| `<leader>hs` | 搜索历史 |

### 标签页（`<leader><tab>` 组）

| 快捷键 | 说明 |
|--------|------|
| `<leader><tab>n` | 新建标签页 |
| `<leader><tab>l` | 最后一个标签页 |
| `<leader><tab>f` | 第一个标签页 |
| `<leader><tab><tab>` | 切换到其他标签页 |

### 退出与会话

| 快捷键 | 说明 |
|--------|------|
| `<leader>qq` | 退出 |
| `<leader>qa` | 全部退出 |

### 代码操作（`<leader>c` 组）

| 快捷键 | 说明 |
|--------|------|
| `<leader>ca` | 代码操作 |
| `<leader>cr` | 重命名符号 |
| `<leader>cf` | 格式化代码 |

### 选项与界面（`<leader>u` 组）

| 快捷键 | 说明 |
|--------|------|
| `<leader>un` | 切换行号 |
| `<leader>ur` | 切换相对行号 |
| `<leader>uw` | 切换换行显示 |
| `<leader>uh` | 切换高亮搜索结果 |

### 其他快捷键

| 快捷键 | 说明 |
|--------|------|
| `<M-h>` | 跳转到行首 |
| `<M-l>` | 跳转到行尾 |
| `<M-z>` | 跳转到文件末尾并居中 |
| `<leader>l` | 打开插件管理器 |
| `<leader>L` | Lazy 更新历史 |

## Treesitter 文本对象

| 快捷键 | 说明 |
|--------|------|
| `af` | 选择函数 |
| `if` | 选择函数内容 |
| `ac` | 选择类 |
| `ic` | 选择类内容 |
| `aa` | 选择参数 |
| `ia` | 选择参数内容 |

## 常用命令

| 命令 | 说明 |
|------|------|
| `:Lazy` | 插件管理器 |
| `:Mason` | LSP/工具管理器 |
| `:Lazy sync` | 同步并更新插件 |
| `:Lazy clean` | 清理未使用的插件 |
| `:MasonUpdate` | 更新 Mason 工具 |
| `<leader>sk` | 搜索快捷键 |
| `:TSUpdate` | 更新 Treesitter |
| `:ConformInfo` | 查看格式化器状态 |
| `:LspInfo` | 查看 LSP 状态 |

## 主题配置

- **默认主题**: Tokyo Night（透明背景）
- **样式**: Night 风格
- **透明度**: 完全透明（编辑器、浮动窗口、侧边栏）
- **光标行**: `#3d4458`（深灰色）
- **主题持久化**: 选择的主题会保存，重启后保持

## 自动安装的工具

### 前端
- `typescript-language-server` - JS/TS LSP
- `vue-language-server` - Vue LSP（Volar）
- `vscode-html-language-server` - HTML LSP
- `vscode-css-language-server` - CSS LSP
- `tailwindcss-language-server` - Tailwind 支持
- `emmet-language-server` - Emmet
- `prettierd` - 代码格式化
- `eslint_d` - 代码检查

### Python
- `pyright` - Python LSP
- `black` - 格式化
- `ruff` - 检查和格式化
- `debugpy` - 调试器

### Docker
- `docker-compose-language-service`
- `hadolint` - Dockerfile 检查

### 配置文件
- `vscode-json-language-server` - JSON LSP
- `yaml-language-server` - YAML LSP

## 可选 Extras

在 `lua/plugins/extras.lua` 中可启用的额外功能：

```lua
-- Svelte 框架
{ import = "lazyvim.plugins.extras.lang.svelte" }

-- Angular 框架
{ import = "lazyvim.plugins.extras.lang.angular" }

-- Go 语言
{ import = "lazyvim.plugins.extras.lang.go" }

-- Rust 语言
{ import = "lazyvim.plugins.extras.lang.rust" }

-- AI 辅助（Codeium - 免费）
{ import = "lazyvim.plugins.extras.ai.codeium" }

-- GitHub Copilot（需订阅）
{ import = "lazyvim.plugins.extras.ai.copilot" }
```

## 特色功能

### 中文化界面
- 文件浏览器操作提示全部中文
- Which-key 菜单中文标签
- Lazy.nvim 界面中文翻译

### 智能文件操作
- 复制文件时自动重命名（`file~1`, `file~2`...）
- 粘贴时冲突检测和确认
- 剪切/复制模式区分

### 语法高亮增强
- 彩虹括号
- 颜色代码预览（`#fff`, `rgb()` 等）
- Tailwind 类名颜色预览
- 缩进参考线
- 当前代码上下文显示
- 自动闭合标签

### 编辑器优化
- 使用 tab 缩进（4 空格宽度）
- 相对行号
- Treesitter 折叠
- 透明背景

## 故障排查

### LSP 不工作
1. `:Mason` 检查工具是否已安装
2. `:LspInfo` 查看 LSP 状态
3. `:LspRestart` 重启 LSP

### 格式化不工作
1. `:Mason` 检查格式化器
2. `:ConformInfo` 查看格式化器状态

### 语法高亮问题
1. `:TSUpdate` 更新 Treesitter
2. `:TSInstallInfo` 查看 parsers

### 插件错误
1. `:Lazy` 查看插件日志
2. `:messages` 查看错误信息

## 参考资源

- [LazyVim 官方文档](https://lazyvim.github.io/)
- [LazyVim Extras](https://lazyvim.github.io/extras)
- [Snacks.nvim 文档](https://github.com/folke/snacks.nvim)
- [CLAUDE.md](./CLAUDE.md) - 配置架构说明
