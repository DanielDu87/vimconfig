# Neovim 深度定制配置 (基于 LazyVim)

本仓库包含一份基于 [LazyVim](https://www.lazyvim.org/) 构建的高级 **Neovim 配置文件**。它专为全栈开发（TypeScript, Vue, Python, Docker）量身定制，核心理念是**高性能**、**视觉透明化**以及**极致的中文本地化体验**。

## ✨ 核心特性

### 1. 🎨 极致 UI 与主题

- **全局透明化**：编辑器背景、浮动窗口、侧边栏、补全菜单等均已配置为透明。
- **主题持久化**：支持 Tokyo Night（默认）、OneDark、Solarized 等，自动保存并恢复主题选择。
- **深度中文本地化**：`Which-Key`、`Lazy.nvim` 界面、文件浏览器菜单、Snacks Picker 通知全中文化。
- **界面美化**：集成 `Snacks.nvim` 提供现代化的 UI 组件（Picker, Notifier, Terminal, Scratch, Explorer, Dashboard）。

### 2. 🍱 窗口与布局持久化 (Persistence)

本配置解决了 Neovim 窗口管理的痛点，实现了全方位的“大小记忆”：

- **全局分割比例**：自动记录您手动调整的每一个分割窗口（水平或垂直）的大小，重启后立即恢复。
- **侧边栏宽度**：`Snacks Explorer` 的侧边栏宽度在调整后会自动持久化。
- **调试布局 (DAP)**：调试面板（变量、堆栈、控制台等）的尺寸在调整后自动记录，下次开启调试时**瞬间无跳变恢复**。
- **智能调整**：`<leader>wr` 会根据当前窗口分割方向智能提示尺寸调整，并触发自动保存。

### 3. 🤖 AI 增强与智能补全 (AI & Completion)

- **GitHub Copilot**：
    - **内联虚文本**：类似 VSCode 的 Ghost Text 自动补全，按 `Tab` 键一键采纳。
    - **交互面板**：`<M-CR>` 调出 Copilot 面板，自动刷新多种建议方案。
- **高性能补全 (Blink.cmp)**：
    - **极速响应**：基于 Rust 开发的新一代补全引擎，延迟极低。
    - **视觉增强**：补全列表支持彩色预览（如颜色代码、图标）和详细的类型标注。
    - **智能排序**：LSP 结果、代码片段（Snippets）、路径补全与 Buffer 单词智能混合排序。

### 4. 📄 动态模板系统 (Templates)

- **一键建档**：`<leader>tn` 调出模板选择器。
- **丰富预设**：涵盖 Dockerfile、docker-compose、HTML5、React/Vue 组件、FastAPI、Express、Python/Node 基础模板等。
- **智能变量**：自动填充文件名、创建日期、当前用户、项目名称，并支持 Snippet 光标定位。

### 5. ⚡️ 统一运行中心 (Runner)

- **异步执行**：自定义后台引擎 (`lua/plugins/runner.lua`)。
- **日志 Tail**：专用 `runnerlog` 窗口，支持错误高亮、URL 识别和自动滚动。
- **多语言支持**：HTML (Browser-sync)、JS (Node)、Python (Venv 检测)。

### 6. 🔖 简单书签系统 (Bookmarks)

- **持久化记录**：书签保存至 `~/bookmarks.json`。
- **视觉反馈**：SignColumn 显示 `🔖` 图标，支持 `[` / `]` + `m` 快速跳转。
- **快速搜索**：`'`（单引号）一键搜索并预览所有书签。

## ⌨️ 快捷键大全 (Keymaps)

### 🚀 运行、调试与模板 (Run & Debug & Template)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>rr` | **运行当前文件** (HTML/JS/Py) |
| `<leader>rp` | **运行项目** |
| `<leader>rl` | **查看运行日志** |
| `<leader>rs` | **停止所有任务** |
| `<leader>tn` | **根据模板新建文件** 📄 |
| `<leader>rv` | **选择 Python 虚拟环境** |
| `<leader>dt` | **切换调试面板** (自动恢复尺寸) |
| `<leader>db` | **切换断点** (持久化) |
| `<leader>dp` | **切换性能分析器** |

### 🤖 AI 与补全 (AI & Completion)

| 快捷键 | 描述 |
| :--- | :--- |
| `Tab` (插入) | **采纳 Copilot 建议** / **补全确认** |
| `<M-CR>` | **打开 Copilot 面板** |
| `gr` (面板) | **刷新建议** |
| `<M-]>` / `<M-[>`| **下/上一个 AI 建议** |

### 📂 文件与浏览器 (Explorer)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>e` | **切换资源管理器** |
| `<M-q>` | **切换资源管理器** (快捷键) |
| `x` / `y` / `p` | **剪切 / 复制 / 粘贴** |
| `a` / `r` / `d` | **新建 / 重命名 / 删除** |

### 🗂️ 缓冲区与书签 (Buffers & Marks)

| 快捷键 | 描述 |
| :--- | :--- |
| `m` | **切换书签** |
| `'` (单引号) | **搜索书签** (Picker) |
| `]m` / `[m` | **下一个/上一个书签** |
| `<leader>bp` | **切换固定 (Pin)** |
| `<leader>bP` | **关闭非固定 Buffer** (保护布局) |

### 🍱 窗口管理 (Windows)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>wr` | **调整窗口大小** (触发持久化保存) |
| `<leader>wm` | **最大化/恢复窗口** |
| `<leader>w-` / `|`| **分割窗口** (下/右) |
| `<leader>w=` | **均衡窗口大小** |

### 🛠 代码与 LSP (Code)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>ca/A` | **代码操作 / 项目操作** |
| `<leader>cr` | **重命名** |
| `<leader>cf` | **格式化代码** (强制 Tab) |
| `<leader>r` (Visual) | **智能重构** (提取函数/变量) |
| `gl` | **行诊断** (浮窗切换) |

---
**配置维护者**: Dyx | **基于**: LazyVim | **更新日期**: 2026-02-07
