# Neovim 深度定制配置 (基于 LazyVim)

本仓库包含一份基于 [LazyVim](https://www.lazyvim.org/) 构建的高级 **Neovim 配置文件**。它专为全栈开发（TypeScript, Vue, Python, Docker）量身定制，核心理念是**高性能**、**视觉透明化**以及**极致的中文本地化体验**。

## ✨ 核心特性

### 1. 🎨 极致 UI 与主题

- **全局透明化**：编辑器背景、浮动窗口、侧边栏、补全菜单等均已配置为透明，完美融入终端背景（配置位于 `lua/plugins/theme.lua`）
- **主题持久化**：主题选择会自动保存到 `~/.local/state/nvim/colorscheme`，重启后自动恢复。支持 Tokyo Night（默认）、OneDark、Solarized 等主题。
- **深度中文本地化**：
    - `Which-Key` 快捷键菜单全中文注释，覆盖所有主要功能菜单
    - `Lazy.nvim` 插件管理器界面中文化
    - 文件资源管理器操作菜单中文化
    - 统一的中文括号格式：`功能（说明）`，如 `查找文件（根目录）`、`查找文件（当前目录）`
    - Snacks Picker 通知自动汉化（未找到结果、通知历史等）
- **代码补全视觉增强**：
    - 选中项背景色：`#4e5a7e`（蓝灰色），加粗显示
    - Copilot 虚文本颜色：`#a9b1d6`（较亮灰蓝色），提升可读性
- **界面美化**：集成 `Snacks.nvim` 提供现代化的 UI 组件（Picker, Notifier, Terminal, Scratch, Explorer, Dashboard）
- **Buffer 栏增强**：
    - 当前选中的 buffer 显示蓝色下划线（`#2b85b7`），清晰标识当前编辑位置
    - 即使在有错误/警告的 buffer 上，下划线也始终显示，不会被诊断颜色覆盖
    - 固定的 buffer 显示 📌 图标
- **Git Log 视图增强**：
    - `<leader>gl` 命令提供高度可视化的 Git 提交详情视图
    - 通过自定义高亮，清晰区分 HEAD 指针（亮紫色）、本地分支（亮绿色）、远程分支（灰色）和标签（青色）
    - 支持按 Tab 键在历史列表和差异预览之间切换焦点，确认提交后自动打开 Diffview

### 2. ⚡️ 统一运行中心 (Runner)

本配置内置了强大的 **统一运行中心** (`lua/plugins/runner.lua`)，提供从单文件到复杂项目的异步运行方案：

- **核心架构**：后台静默运行 + 实时 Tail 直播出口。
- **异步日志窗**：提供专属的 `runnerlog` 语法高亮，支持错误路径高亮、URL 识别和 Django/Python 命令美化。
- **智能滚动**：支持三种模式（`never` 从不滚动、`auto` 接近底部时跟随、`on_complete` 完成后置底）。
- **灵活配置**：
    - **文件级**：`<leader>rc` 为特定文件配置运行命令前缀。
    - **项目级**：`<leader>rC` 为整个项目配置完整运行命令。
    - **浏览器**：可配置项目或文件关联的浏览器 URL，运行后自动打开（支持 Arc、Chrome 等）。
- **一键预览**：
    - HTML: 自动启动 `browser-sync` 并通过 Arc/Chrome 打开预览。
    - JavaScript/Python: 自动识别解释器（支持虚拟环境检测）并运行。
- **资源管理**：`<leader>rs` 强力终止所有相关后台任务，自动清理端口冲突。

### 3. 🔖 简单书签系统 (Bookmarks)

自定义实现的轻量级书签方案 (`lua/util/marks.lua`)，完全契合开发者习惯：

- **视觉提示**：在符号栏（SignColumn）显示 `🔖` 图标。
- **持久化存储**：书签自动保存到 `~/bookmarks.json`，重启 Neovim 依然保留。
- **快速操作**：`m` 切换书签，`[` / `]` + `m` 快速在书签间跳转。
- **智能搜索**：`'`（单引号）或 `<leader>bs` 调出 `Snacks.picker` 搜索书签，支持预览且高亮目标行。

### 4. 📂 增强型文件管理 (Explorer)

- **Snacks Explorer**：采用现代化的文件浏览体验，支持多选、浮窗、侧边栏模式。
- **智能操作**：重写了文件操作逻辑 (`lua/util/explorer_actions.lua`)，支持 Windows 风格的**剪切/复制/粘贴**。
- **冲突处理**：粘贴时自动检测文件名冲突，并提供重命名或自动备份策略。
- **路径修复**：复制路径到剪贴板时自动去除多余换行符。
- **宽度持久化**：Explorer 宽度自动保存，重启后恢复布局。

### 5. 🧡 Git 集成

- **多层次工具链**：Fugitive (状态面板) + Diffview (全屏差异) + LazyGit (TUI) + Better Git Blame (行/选区追溯)。
- **规范化提交**：内置 `ConventionalCommit` 支持，强迫症级别的提交信息规范。
- **行内 Blame**：实时显示当前行的 Git Blame 详情。

### 6. 🛠 代码规范与工具链

- **强制 Tab 缩进**：全项目强制使用 **Tab** (宽度 4)，通过自定义管道确保保存时同步格式化。
- **实时诊断**：配合 `tiny-inline-diagnostic` 提供美观的多行诊断显示。
- **智能重构**：Visual 模式下 `<leader>r` 智能提取函数、变量、代码块，带中文菜单。
- **Tailwind 自动激活**：编辑 HTML 时若检测无配置，自动生成最简 `tailwind.config.js` 以激活 LSP 智能补全。

## ⌨️ 快捷键与菜单大全 (Keymaps)

> **Leader Key** 设置为 `<Space>` (空格键)

### 📂 文件与浏览器 (File & Explorer) - `<leader>f` / `<leader>e`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader><space>` | **查找文件** (根目录) |
| `<leader>fe` | **文件浏览器** (根目录) |
| `<leader>fE` | **文件浏览器** (当前目录) |
| `<leader>e` | **切换文件浏览器** |
| `<leader>ff` | **查找文件** (根目录) |
| `<leader>fF` | **查找文件** (当前目录) |
| `<leader>fg` | **查找 Git 文件** |
| `<leader>fr` | **最近文件** (根目录) |
| `<leader>fR` | **最近文件** (当前目录) |
| `<leader>fc` | **查找配置文件** |
| `<leader>fb` | **查找 Buffer** |
| `<leader>fB` | **查找 Buffer** (包含隐藏) |
| `<leader>fn` | **新建文件** |
| `<leader>fp` | **项目列表** |
| **Explorer 内部** | |
| `x` | **剪切** 文件 |
| `y` | **复制** 文件/路径 |
| `p` | **粘贴** (自动重命名/移动) |
| `d` | **删除** (带确认) |
| `r` | **重命名** |
| `a` | **新建** 文件/目录 |
| `q` | **关闭 Buffer** (保留窗口) |
| `<M-q>` | **切换浏览器** (全局) |

### 🗂️ 缓冲区与书签 (Buffers & Marks) - `<leader>b`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>bb` | **切换到其他 Buffer** |
| `<leader>bd` | **关闭当前 Buffer** |
| `<leader>bh` | **上一个 Buffer** |
| `<leader>bl` | **下一个 Buffer** |
| `<leader>bo` | **关闭其他 Buffer** |
| `<leader>bp` | **切换固定 (Pin)** |
| `<leader>bH` | **关闭左侧所有 Buffer** |
| `<leader>bL` | **关闭右侧所有 Buffer** |
| `<leader>bP` | **关闭非固定 Buffer** (保护布局) |
| **书签操作** | |
| `m` | **切换书签** |
| `]m` | **下一个书签** |
| `[m` | **上一个书签** |
| `'` (单引号) | **搜索书签** (Picker) |
| `<leader>bs` | **搜索书签** (Picker) |
| `<leader>bc` | **清空当前文件书签** |
| `<leader>bC` | **清空所有书签** |

### 🚀 运行与调试 (Run & Debug) - `<leader>r` / `<leader>d`

| 快捷键 | 描述 |
| :--- | :--- |
| **运行 (Runner)** | |
| `<leader>rr` | **运行当前文件** (HTML/JS/Py) |
| `<leader>rp` | **运行项目** |
| `<leader>rl` | **查看运行日志** |
| `<leader>rs` | **停止所有任务** |
| `<leader>rc` | **配置文件运行命令** |
| `<leader>rC` | **配置项目运行命令** |
| `<leader>rb` | **配置文件浏览器 URL** |
| `<leader>rB` | **配置项目浏览器 URL** |
| `<leader>ro` | **打开关联浏览器** |
| `<leader>rv` | **选择 Python 虚拟环境** |
| `<leader>rV` | **选择 TS 工作区版本** |
| **调试 (DAP)** | |
| `<leader>dt` | **切换调试面板** (UI) |
| `<leader>dc` | **开始/继续** (Continue) |
| `<leader>di` | **步入** (Step Into) |
| `<leader>do` | **步过** (Step Over) |
| `<leader>du` | **步出** (Step Out) |
| `<leader>db` | **切换断点** |
| `<leader>dB` | **条件断点** |
| `<leader>dX` | **清除所有断点** |
| `<leader>dM` | **调试方法** (Python) |
| `<leader>dC` | **调试类** (Python) |
| `<leader>dp` | **切换性能分析器** |
| `<leader>dh` | **性能分析高亮** |
| `<leader>dd` | **文档诊断** (列表) |
| `<leader>dD` | **项目诊断** (列表) |

### 🛠️ 代码与 LSP (Code) - `<leader>c`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>ca` | **代码操作** (Code Action) |
| `<leader>cA` | **项目操作** (Source Action) |
| `<leader>cr` | **重命名** (Rename) |
| `<leader>cf` | **格式化代码** (Format) |
| `<leader>cl` | **LSP 信息** |
| `<leader>cm` | **Mason 管理** |
| `<leader>cd` | **行诊断** (浮窗) |
| `<leader>cn` | **跳转到指定行** |
| `<leader>c/` | **切换行注释** |
| **TypeScript/Vue 增强** | |
| `<leader>co` | **整理导入** |
| `<leader>cu` | **删除未使用导入** |
| `<leader>ci` | **添加缺失导入** |
| `<leader>cx` | **修复所有诊断** |
| **智能重构** | |
| `<leader>r` (Visual) | **智能重构** (提取函数/变量) |

### 🧡 Git 集成 - `<leader>g`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>gg` | **Git 提交图** |
| `<leader>gl` | **Git 日志** (提交+差异) |
| `<leader>gc` | **Git 面板** (Fugitive) |
| `<leader>gs` | **Git 状态** (Picker) |
| `<leader>gb` | **Git Blame** (行/选区) |
| `<leader>gd` | **本地差异** (LazyGit) |
| `<leader>gD` | **远程差异** (LazyGit) |
| `<leader>gp` | **推送** (Fetch first) |
| `<leader>gP` | **拉取** (Pull) |
| `<leader>gC` | **切换分支** |
| `<leader>gS` | **Git Stash** |
| `<leader>ga` | **暂存所有** (git add -A) |
| `<leader>gro` | **浏览器打开远程仓库** |

### 📜 历史记录 - `<leader>h`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>hn` | **通知历史** |
| `<leader>hl` | **最后一条通知** |
| `<leader>ha` | **所有通知** |
| `<leader>hx` | **清除通知** |
| `<leader>hc` | **命令历史** |
| `<leader>hs` | **搜索历史** |

### 🔍 搜索 (Search) - `<leader>s` / `s`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>sg` | **全局搜索** (Grep) |
| `<leader>sw` | **搜索单词** (项目) |
| `<leader>sW` | **搜索单词** (目录) |
| `<leader>sr` | **查找并替换** |
| `<leader>sk` | **查看快捷键** |
| `<leader>sm` | **标记管理** |
| `<leader>ss` | **文档符号** |
| `<leader>sS` | **项目符号** |
| `/` 或 `?` | **当前文件搜索** (行列表) |
| `s` | **Flash 跳转** |

### 🎨 界面与窗口 (UI & Windows) - `<leader>u` / `<leader>w`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>ut` | **切换透明模式** |
| `<leader>ua` | **切换动画** |
| `<leader>uT` | **切换标签栏** |
| `<leader>ul` | **切换行号** |
| `<leader>ud` | **切换诊断显示** |
| `<leader>uz` | **切换禅模式** |
| `<leader>uZ` | **切换缩放模式** |
| `<leader>w-` | **向下分割** |
| `<leader>w|` | **向右分割** |
| `<leader>wd` | **关闭窗口** |
| `<leader>wm` | **最大化/恢复** |
| `<leader>wr` | **调整窗口大小** |
| `<leader>w=` | **均衡窗口** |
| `<leader>wh/j/k/l` | **切换窗口** (左/下/上/右) |
| `<leader>wH/J/K/L` | **移动窗口** (左/下/上/右) |

### 💻 终端与标签页 (Terminal & Tabs) - `<leader>t` / `<leader><tab>`

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>tf` | **浮窗终端** |
| `<leader>th` | **水平终端** (Bottom) |
| `<leader>tv` | **垂直终端** (Right) |
| `<leader>tt` | **标签页终端** |
| `<leader><tab><tab>`| **新建标签页** |
| `<leader><tab>d` | **关闭标签页** |
| `<leader><tab>n/p` | **下/上一个标签页** |

### ⌨️ 通用编辑 (General)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>k` | **DevDocs 查询** (关键词) |
| `<leader>K` | **DevDocs 搜索** (输入) |
| `gl` | **行诊断** (浮窗切换) |
| `<M-v>` | **竖向块选择** |
| `<A-j>` / `<A-k>` | **移动行/块** (Alt+j/k) |
| `ciq` | **修改 "" 内容** |
| `cie` | **修改 '' 内容** |
| `cib` | **修改 () 内容** |
| `<M-z>` | **跳转文件末尾并居中** |
| `<M-h>` / `<M-l>` | **跳转行首/行尾** |
| `q` | **关闭 Buffer** (保护布局) |

---
**配置维护者**: Dyx | **基于**: LazyVim | **更新日期**: 2026-02-07
