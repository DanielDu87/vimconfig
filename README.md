# Neovim 旗舰配置手册 (Frontend & Backend)

本配置基于 **LazyVim** 框架，旨在为 **前端 (React/Vue/TS)**、**Python (Django/FastAPI)** 及 **系统开发** 提供极致的效率与审美体验。

---

## 💎 核心插件生态与架构

| 插件 | 核心作用 | 定制化说明 |
| :--- | :--- | :--- |
| **Snacks.nvim** | 全能基石 | 负责侧边栏目录树、Dashboard、极速搜索 (Picker)、浮动终端 |
| **Conform.nvim** | 格式化中枢 | **强制同步执行**，支持工具链串联（如 eslint_d -> prettier） |
| **LSPConfig** | 语言智能 | **禁用 vtsls**，锁定 **ts_ls** 以确保重构稳定性；禁用 Marksman 无用提示 |
| **Which-Key** | 快捷键导航 | **100% 中文化**，宽度扩展至 0.9，适配业务图标 |
| **Render-Markdown**| 文档美化 | 标题采用 **背景色块层级区分**，表格重线条网格化，代码块阴影 |
| **Venv-selector** | Python 环境 | 深度整合项目本地环境与全局 `/0.python-venv` 环境仓库 |

---

## ✨ 格式化与代码质量矩阵 (Formatting & Linting)

**全局物理规范**：缩进 **Tab**，显示宽度 **4**，长行限制 **120**，保存时同步格式化。

| 语言 | 格式化工具链 (Formatter) | 质量检查 (Linter/LSP) | 核心特色 |
| :--- | :--- | :--- | :--- |
| **JS / TS** | `eslint_d` → `prettier` | `eslint-lsp` | 自动清理无用导入，Tailwind 类名自动排序 |
| **React** | `eslint_d` → `prettier` | `ts_ls` (tsserver) | 标签闭合不换行，宽屏适配 (120宽) |
| **Vue** | `eslint_d` → `prettier` | `volar` | 逻辑修复与视觉排版无缝串联 |
| **HTML** | `prettier` (Custom) | `superhtml` | **极致紧凑**：保存时自动删除所有空行 |
| **CSS / SCSS** | `stylelint` → `prettier` | **Stylelint** | 锁定全局路径，属性逻辑排序 (Recess Order) |
| **Python** | `isort` → `black` | `ruff` / `pyright` | PEP8 规范 4空格，极致执行速度 |
| **Go** | `goimports` → `gofumpt` | `gopls` | 自动管理标准库引用，严苛的对齐排版 |
| **SQL** | `prettier` | - | 遵循现代 4 空格标准，关键字大写 |
| **Dockerfile** | `perl` (Custom) → `trim` | `hadolint` | **指令自动转大写**，智能压缩多余空格 |
| **Markdown** | `prettier` | `marksman` | 内嵌代码同步格式化，标题背景色块区分 |

---

## ⌨️ 快捷键终极指南

### 1. 代码开发与重构 (`<leader>c`)
- `<leader>cf`: **一键格式化** (全语种同步执行)
- `<leader>ca`: **代码操作** (💡 修复报错、提取函数、重构)
- `<leader>cr`: **智能重命名** (✏️ 跨文件同步重命名符号)
- `<leader>co`: **整理导入** (📦 自动排序并删除无用引用)
- `<leader>cv`: **切换 Python 环境** (🐍 自动扫描全局仓库)
- `<leader>cs`: **显示符号结构** (🔍 Outline 侧边栏，自动聚焦)
- `<leader>cX`: **修复全文件错误** (🛠️ 一键 Auto-fix)

### 2. 增强文件浏览器 (Snacks Explorer)
- `<leader>e`: **打开目录树**
- `<leader>H`: **切换隐藏文件** (仅切换 `.` 开头的文件，`.gitignore` 忽略的文件始终显示)
- **内部操作**：
    - `c`: **创建副本** (粘贴到同级自动重命名 `~1`)
    - `p`: **智能粘贴** (支持目录粘贴到自身时产生副本，不再产生嵌套错误)
    - `x` / `y`: **剪切 / 复制路径** | `d` / `r`: **删除 / 重命名**

### 3. 极速搜索与导航
- `/` 或 `?`: **行内快速搜索** (智能环境识别：在普通代码中搜索，在 UI 窗口中恢复原功能)
- `<leader>ff`: **查找文件** | `<leader>sg`: **全项目 Grep**
- `gl`: **切换行诊断浮窗** | `Alt + z`: **跳转至文件末尾并居中**
- `Alt + h/l`: **行首 / 行尾跳转** | `q`: **安全关闭 Buffer** (保持布局)

---

## 🔧 系统底层优化细节
- **透明视觉**：`winblend = 20`, `pumblend = 20`。
- **自动换行**：全局开启 `wrap`，不破坏代码物理行。
- **折叠逻辑**：基于 `Treesitter` 的高性能折叠，默认全部展开。
- **内显提示**：`Inlay Hints` 始终开启，辅助阅读 TS/Python 类型。
- **错误预警**：开启格式化错误显式通知，工具缺失或配置错误时弹出 Error 提醒。

---

## 🏗️ 维护与开发规范
- **文件分布**：`lua/plugins/` 采用关注点分离模式，禁止 monolithic 配置。
- **提交规范**：`date "+%Y-%m-%d %H:%M" 内容`。
- **格式化规则**：Lua 代码遵循项目物理根目录的 `stylua.toml`。