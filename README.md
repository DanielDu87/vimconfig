# Neovim 旗舰开发环境 (基于 LazyVim)

这是一套深度定制的 Neovim 环境，核心目标是：**透明美化、极致性能、全自动化工作流**。特别针对前端 (React/Vue/TS)、Python (Django/FastAPI) 及系统级后端开发进行了“武装到牙齿”的优化。

---

## 🎨 视觉与 UI 规范 (UI & Aesthetics)

- **全局透明**：背景透明度设为 `20`，支持浮动窗口与补全菜单同步透明。
- **菜单汉化**：`Which-Key` 菜单 100% 中文化，宽度扩展至 `0.9`，配备动态业务图标。
- **自动换行**：全局开启 `wrap`，长行代码在视口内自动折行，不破坏逻辑行。
- **内显提示**：全局开启 `Inlay Hints`，实时显示变量类型、函数参数名。
- **智能折叠**：基于 `Treesitter` 的高性能折叠逻辑，文件打开时默认全部展开。
- **文档美化**：Markdown 采用 **背景色块层级区分**，表格重线条网格化，代码块阴影。

---

## ✨ 格式化与代码质量 (Formatting & Linting)

### 📐 全局物理规范
- **缩进**：严格使用 **Tab**。
- **宽度**：视觉宽度统一为 **4**。
- **行宽**：Prettier 限制为 **120** 字符。
- **策略**：保存时触发同步格式化，确保写入硬盘的代码始终完美。

### 🛠️ 语言专属工具链
| 语言 | 格式化链 (Conform) | 质量检查 (Linter/LSP) | 核心特性 |
| :--- | :--- | :--- | :--- |
| **JS / TS** | `eslint_d` → `prettier` | `eslint-lsp` | 自动清理无用导入，Tailwind 类名自动排序 |
| **React** | `eslint_d` → `prettier` | `ts_ls` | 标签闭合不换行，120 宽屏排版 |
| **Vue** | `eslint_d` → `prettier` | `volar` | 逻辑修复与视觉排版串联执行 |
| **HTML** | `markuplint` → `prettier` | **Markuplint** | **强力纠错**：实时捕获标签闭合、嵌套错误 |
| **CSS / SCSS** | `stylelint` → `prettier` | `stylelint` | 自动执行属性逻辑排序 (Recess Order)，锁定全局路径 |
| **Python** | `isort` → `black` | `ruff` / `pyright` | 导入自动归类，强制 PEP8 规范，极致执行速度 |
| **Go** | `goimports` → `gofumpt` | `gopls` | 自动管理标准库引用，严苛的对齐排版 |
| **SQL** | `prettier` | - | 遵循现代 4 空格标准，关键字大写 |
| **Dockerfile**| `perl` (Custom) → `trim` | `hadolint` | **指令自动转大写**，自动压缩指令后多余空格 |
| **Markdown** | `prettier` | - | **极致清净**：彻底屏蔽所有诊断提示，仅保留背景色标题 |

---

## ⌨️ 快捷键终极指南

### 1. 代码开发与重构 (`<leader>c`)
- `<leader>cf`: **一键格式化** (同步执行所有工具链)
- `<leader>ca`: **代码操作** (💡 修复报错、重构、提取函数)
- `<leader>cr`: **智能重命名** (✏️ 跨文件同步重命名符号)
- `<leader>co`: **整理导入** (自动排序并删除无用引用)
- `<leader>cv`: **Python 环境** (自动扫描项目及全局 `/0.python-venv`)
- `<leader>cs`: **显示符号结构** (Outline，自动聚焦)
- `<leader>cX`: **一键修复全文件错误**
- `div.a + Tab`: **Emmet 极速展开** (HTML/JSX 适用)

### 2. 增强文件浏览器 (Snacks Explorer)
- `<leader>e`: **打开目录树**
- `<leader>H`: **切换隐藏文件** (仅切换 `.` 开头的文件，`.gitignore` 忽略的文件始终显示)
- **内部操作**：
    - `c`: **创建副本** (粘贴到同级自动重命名为 `~1`)
    - `p`: **智能粘贴** (支持目录粘贴到自身时产生副本)
    - `x` / `y`: **剪切 / 复制路径** | `d` / `r`: **删除 / 重命名**

### 3. 极速搜索与导航
- `/` 或 `?`: **行内快速搜索** (智能识别环境)
- `<leader>ff`: **查找文件** | `<leader>sg`: **全项目搜索**
- `gl`: **切换行诊断浮窗** | `Alt + z`: **跳转至末尾并居中**
- `Alt + h/l`: **行首 / 行尾跳转** | `q`: **安全关闭 Buffer**

---

## 🏗️ 目录结构说明
- `lua/config/`: 基础选项、自动命令、核心键位。
- `lua/plugins/`: 插件 specs 定义（按功能拆分，如 `theme.lua`, `markdown.lua`）。
- `lua/util/`: 自定义复杂逻辑（如 `format.lua` 负责 HTML 智能空行）。

---

## 📅 维护与提交
- **提交格式**：`date "+%Y-%m-%d %H:%M" 内容`。
- **更新策略**：配置变更后重启 Neovim 自动加载。
