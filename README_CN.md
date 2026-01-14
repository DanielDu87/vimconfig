# LazyVim 配置说明

基于 LazyVim starter 模板的 Neovim 配置，专门针对 **前端 + Python + Docker** 开发进行了优化。

## 配置文件结构

```
~/.config/nvim/
├── init.lua                    # 主入口文件
├── lua/
│   ├── config/                 # 核心配置目录
│   │   ├── lazy.lua           # lazy.nvim 配置
│   │   ├── options.lua        # 基础选项
│   │   ├── keymaps.lua        # 键位映射
│   │   └── autocmds.lua       # 自动命令
│   └── plugins/
│       ├── extras.lua         # 所有 LazyVim extras
│       ├── example.lua        # 插件配置示例
│       └── highlight.lua      # 语法高亮增强
```

## ✨ 已启用的功能

### 🎨 前端开发

- **HTML/HTMX** - 语法高亮、补全、Emmet
- **CSS/SCSS/LESS** - 完整支持、Stylelint
- **JavaScript/TypeScript** - 完整支持
- **✅ React** - JSX/TSX 语法高亮和补全
- **✅ Vue** - Vue 2/3 完整支持（Volar）
- **Tailwind CSS** - 类名补全和颜色预览
- **ESLint** - 代码检查
- **Prettier** - 代码格式化

### 🐳 Docker 支持

- **Dockerfile** - 语法高亮、自动补全
- **docker-compose.yml** - 语法高亮、验证
- **Docker LSP** - 智能提示
- **Hadolint** - Dockerfile 检查

### 🐍 Python 开发

- **Python** - 完整支持
- **Django/Flask/FastAPI** - 框架支持
- **Pyright** - 类型检查和智能补全
- **Black** - 代码格式化
- **Ruff** - 快速的 Python 检查和格式化
- **Debugpy** - Python 调试器

### 🔧 核心功能

- **LSP** - 代码补全、跳转定义、查找引用
- **Treesitter** - 高级语法高亮（所有语言）
- **彩虹括号** - 不同层级括号不同颜色
- **颜色预览** - 显示颜色代码（#fff, rgb()）
- **缩进线** - 可视化缩进层级
- **上下文显示** - 显示当前函数/类名
- **自动闭合标签** - HTML/Vue/JSX 自动闭合
- **Telescope** - 模糊查找文件和文本
- **Git 集成** - Git 状态、diff、blame
- **自动格式化** - 保存时自动格式化
- **代码检查** - 实时错误和警告提示

## 🚀 快速开始

### 1. 启动 Neovim

```bash
nvim
```

首次启动会自动安装所有插件和 LSP 服务器（约 3-5 分钟）。

### 2. 安装系统依赖（推荐）

```bash
# macOS
brew install python node go docker

# Linux (Ubuntu/Debian)
sudo apt install python3 python3-venv nodejs npm docker.io
```

### 3. Python 虚拟环境

```bash
# 创建虚拟环境
python -m venv .venv

# 激活后打开 Neovim
source .venv/bin/activate
nvim
```

## 📝 常用命令

| 命令 | 说明 |
|------|------|
| `:Lazy` | 插件管理 |
| `:Mason` | LSP/工具管理 |
| `:LazyKeys` | 查看快捷键 |
| `<leader>sk` | 搜索快捷键 |
| `:TSUpdate` | 更新 Treesitter parsers |

## ⌨️ 常用快捷键

### 文件操作
- `<leader>ff` - 查找文件
- `<leader>fg` - 查找文本
- `<leader>fb` - 查找 buffer

### 代码导航
- `gd` - 跳转到定义
- `gr` - 查找引用
- `[d` / `]d` - 上/下一个诊断
- `<leader>ca` - 代码操作

### Treesitter 文本对象
- `af` - 选择函数
- `if` - 选择函数内容
- `ac` - 选择类
- `ic` - 选择类内容

### Git
- `<leader>gg` - 打开 Lazygit
- `<leader>gb` - Git blame

### Python 特有
- `<leader>tf` - 测试文件
- `<leader>td` - 测试最近的

## 🎨 语法高亮功能

### Treesitter 高级高亮
- ✅ 所有语言的精确语法高亮
- ✅ 增量选择（智能选择代码块）
- ✅ 语法文本对象
- ✅ 自动缩进

### 视觉增强
- ✅ **彩虹括号** - 不同层级括号不同颜色
- ✅ **颜色预览** - 显示 #fff, rgb() 等颜色
- ✅ **Tailwind 颜色** - Tailwind 类名颜色预览
- ✅ **缩进线** - 显示缩进层级
- ✅ **匹配高亮** - 高亮匹配的括号
- ✅ **上下文显示** - 顶部显示当前函数/类
- ✅ **Yank 高亮** - 复制时高亮选中文本
- ✅ **自动闭合** - HTML/Vue/JSX 标签自动闭合

## 📦 自动安装的工具

### 前端 & React/Vue
- typescript-language-server (JS/TS LSP)
- vue-language-server (Vue LSP - Volar)
- vscode-html-language-server (HTML LSP)
- vscode-css-language-server (CSS LSP)
- tailwindcss-language-server (Tailwind 支持)
- emmet-language-server (HTML/CSS 快速编写)
- stylelint-language-server (CSS/SCSS 检查)
- prettierd (代码格式化)
- eslint_d (代码检查)

### Docker
- docker-compose-language-service
- hadolint (Dockerfile 检查)

### Python
- pyright (Python LSP)
- black (Python 格式化)
- isort (import 排序)
- ruff (Python 检查和格式化)
- mypy (类型检查)
- debugpy (Python 调试器)

### 配置文件
- vscode-json-language-server (JSON LSP)
- yaml-language-server (YAML LSP)

## 🔧 可选配置

### 添加新的 LazyVim Extras

在 `lua/config/lazy.lua` 的 `spec` 部分，在 extras 区域添加：

```lua
-- 例如，启用 Svelte 框架
{ import = "lazyvim.plugins.extras.lang.svelte" },

-- 启用 Angular 框架
{ import = "lazyvim.plugins.extras.lang.angular" },

-- 启用 AI 辅助（Codeium）
{ import = "lazyvim.plugins.extras.ai.codeium" },
```

**注意：** 按照 LazyVim 官方规范，导入顺序必须是：
1. `lazyvim.plugins`（已有）
2. `lazyvim.plugins.extras.*`（在这里添加）
3. 自定义 plugins（最后）

## 🐛 故障排查

### LSP 不工作

1. 检查 LSP 状态：`:Mason`
2. 查看 LSP 日志：`:LspInfo`
3. 重启 LSP：`:LspRestart`

### 格式化不工作

1. 检查格式化器：`:Mason`
2. 查看格式化器状态：`:ConformInfo`

### 语法高亮不工作

1. 更新 Treesitter：`:TSUpdate`
2. 检查已安装 parsers：`:TSInstallInfo`
3. 手动安装 parser：`:TSInstall python`

### 插件错误

1. 查看插件日志：`:Lazy`
2. 查看错误详情：`:messages`
3. 查看错误日志：`:lua print(vim.inspect(vim.v.errors))`

## 📚 参考资源

- [LazyVim 官方文档](https://lazyvim.github.io/)
- [LazyVim Extras](https://lazyvim.github.io/extras)
- [LazyVim Python 文档](https://lazyvim.github.io/extras/lang/python)
- [Treesitter 文档](https://github.com/nvim-treesitter/nvim-treesitter)

## 🎯 支持的文件类型

### 前端
- `.html`, `.htm` - HTML
- `.css`, `.scss`, `.sass`, `.less` - CSS
- `.js`, `.jsx`, `.mjs` - JavaScript
- `.ts`, `.tsx` - TypeScript
- `.vue` - Vue 单文件组件

### Docker
- `Dockerfile` - Docker 文件
- `docker-compose.yml` - Docker Compose
- `.dockerignore` - Docker 忽略文件

### Python
- `.py` - Python 源代码
- `pyproject.toml` - Python 项目配置
- `requirements.txt` - Python 依赖
- `Dockerfile` - Python Docker 文件

### 配置文件
- `.json`, `.jsonc` - JSON
- `.yaml`, `.yml` - YAML
- `.toml` - TOML

---

**配置已完成，专注于前端 + Python + Docker 开发！** 🚀
