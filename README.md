# Neovim 深度定制配置 (基于 LazyVim)

本仓库包含一份基于 [LazyVim](https://www.lazyvim.org/) 构建的高级 **Neovim 配置文件**。它专为全栈开发（TypeScript, Vue, Python, Docker）量身定制，核心理念是**高性能**、**视觉透明化**以及**极致的中文本地化体验**。

## ✨ 核心特性

### 1. 🎨 极致 UI 与主题

- **全局透明化**：编辑器背景、浮动窗口、侧边栏、补全菜单等均已配置为透明。
- **主题持久化**：支持 Tokyo Night（默认）、OneDark、Solarized 等，自动保存并恢复主题选择。
- **深度中文本地化**：`Which-Key`、`Lazy.nvim` 界面、文件浏览器菜单、Snacks Picker 通知全中文化。
- **界面美化**：集成 `Snacks.nvim` 提供现代化的 UI 组件（Picker, Notifier, Terminal, Scratch, Explorer, Dashboard）。

### 2. 🍱 窗口与布局持久化 (Persistence)

本配置解决了 Neovim 窗口管理的痛点，实现了全方位的“记忆”功能：

- **分割比例持久化**：通过 `lua/util/window_sizes.lua` 自动记录您手动调整的每一个分割窗口（水平或垂直）的大小，重启后立即恢复。
- **Explorer 宽度**：`Snacks Explorer` 的侧边栏宽度在调整后会自动持久化保存。
- **调试布局 (DAP)**：调试面板（变量、堆栈、控制台等）的尺寸在调整后自动记录，下次开启调试时**瞬间无跳变恢复**。
- **智能调整**：`<leader>wr` 会根据当前窗口分割方向智能提示尺寸调整，并触发自动保存。

### 3. 🤖 AI 增强与智能补全 (AI & Completion)

- **GitHub Copilot (AI 驱动)**：
    - **Ghost Text 模式**：类似 VSCode 的内联虚文本建议，按 `Tab` 键一键采纳。
    - **交互面板**：按 `<M-CR>` 调出 Copilot 建议面板，支持自动刷新并展示多种方案。
- **高性能补全引擎 (Blink.cmp)**：
    - **极速响应**：基于 Rust 开发，无延迟的补全体验。
    - **自定义补全项**：补全列表支持 CSS 颜色代码和 Tailwind 类名的实时颜色预览。
    - **多源混合排序**：LSP、代码片段 (LuaSnip)、文件路径、Buffer 单词智能混合排序。

### 4. 📄 动态模板系统 (File Templates)

- **一键触发**：按下 `<leader>tn` 调出模板选择器，支持实时预览。
- **丰富预设**：涵盖 Docker (Dockerfile/Compose)、前端 (HTML5/React/Vue)、后端 (FastAPI/Express/CLI) 等。
- **智能变量填充**：自动注入文件名、日期、时间、当前用户、项目名称。

### 5. ⚡️ 统一运行中心 (Runner)

- **异步执行**：自定义后台引擎 (`lua/plugins/runner.lua`)，不阻塞编辑器。
- **日志 Tail**：专用 `runnerlog` 窗口，支持错误高亮、URL 识别和自动滚动。
- **多语言支持**：
    - **C**: 使用 `gcc` 编译后自动运行，输出文件与源文件同名。
    - **HTML**: 自动启动 `browser-sync` 并打开浏览器预览。
    - **Python**: 自动检测 VirtualEnv 并执行，支持无缓存运行。
    - **JavaScript**: 使用 Node.js 直接执行。
- **资源管理**：`<leader>rs` 强力终止所有相关后台任务，并自动清理占用端口。

### 6. 🔖 简单书签系统 (Bookmarks)

- **持久化记录**：书签保存至 `~/bookmarks.json`。
- **视觉反馈**：SignColumn 显示 `🔖` 图标，支持 `[` / `]` + `m` 快速跳转。
- **快速搜索**：`'`（单引号）一键搜索并预览所有书签。

## 🌐 语言支持矩阵 (Languages & Tools)

本配置为核心开发语言提供了完整的**LSP (智能提示)**、**Linter (代码检查)**、**Formatter (代码格式化)** 和 **DAP (调试)** 支持。

| 语言/文件 | LSP Server | Linter (检查) | Formatter (格式化) | Debugger (调试) | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Python** | `pyright` | `ruff` | `isort` + `black` | `debugpy` | 虚拟环境自动检测 |
| **TypeScript** | `vtsls` | `eslint` | `prettier` | `js-debug` | 支持 organize imports |
| **JavaScript** | `ts_ls` | `eslint` | `prettier` | `js-debug` | |
| **Vue** | `vtsls` | `eslint` | `prettier` | `js-debug` | 混合模式支持 |
| **HTML** | `html` | `htmlhint` | `prettier` | `browser-sync` | 保存时自动刷新 |
| **Django Tpl**| `djlsp` | `djlint` | `djlint` | - | 强力模板语法检查 |
| **CSS/SCSS** | `cssls` | `stylelint` | `stylelint` + `prettier` | - | 颜色实时预览 |
| **JSON/YAML**| `jsonls`... | - | `prettier` | - | |
| **Markdown** | `marksman` | `markdownlint` | `prettier` | - | |
| **Docker** | `dockerls` | `hadolint` | `docker_uppercase` | - | 指令强制大写 |
| **SQL** | - | - | `sql_formatter` | - | 关键字大写 |
| **Lua** | `lua_ls` | - | `stylua` | - | 配置开发专用 |
| **Shell** | `bashls` | - | `shfmt` | - | |

> **格式化说明**：所有语言默认强制使用 **Tab 缩进 (宽度 4)**，并在保存时自动触发格式化。

## 🔌 核心功能详细介绍

### 🐞 智能调试 (DAP)
- **核心组件**：`nvim-dap` + `nvim-dap-ui`。
- **持久化布局**：调试面板（控制台、堆栈、变量）的尺寸调整后会自动保存，下次启动时瞬间恢复，无视觉跳变。
- **断点管理**：使用 `persistent-breakpoints.nvim`，断点在关闭编辑器后依然保留。
- **快捷键**：
    - `<leader>dt`: 切换调试界面
    - `<leader>db`: 切换断点
    - `<leader>dc`: 开始/继续
    - `<leader>di/o/u`: 步入/步过/步出

### 🛠 代码质量与格式化
- **实时诊断**：使用 `nvim-lint` 提供毫秒级的代码检查，配合 `tiny-inline-diagnostic` 在行内显示美观的错误提示。
- **统一格式化**：使用 `conform.nvim` 接管所有格式化请求。
    - **Python**: 优先使用 `brew` 安装的 `black` 以获得极致速度。
    - **Docker**: 自定义 Perl 脚本将 `FROM`, `RUN` 等指令强制转为大写。
    - **SQL**: 强制关键字大写，保持 SQL 风格统一。
- **自动创建配置文件**：打开文件时自动创建缺失的项目配置文件。
    - **HTML**: 自动创建 `tailwind.config.js` 和 `.prettierrc`
    - **JS/TS/Vue**: 自动创建 `eslint.config.js`（旧版 `.eslintrc.js` 会自动转换）
    - 使用 `brew` 安装的 `eslint`，无需 `node_modules` 依赖

### 📂 增强型文件管理 (Explorer)
- **Snacks Explorer**：采用现代化的侧边栏布局。
- **智能操作**：
    - `x` / `y` / `p`: 支持 Windows 风格的剪切/复制/粘贴。
    - **冲突处理**：粘贴时若文件名冲突，自动重命名（如 `file~1.txt`）。
    - **宽度记忆**：侧边栏宽度调整后自动保存。

---

## ⌨️ 快捷键大全 (Keymaps)

> **Leader Key** 设置为 `<Space>` (空格键)

### 📂 文件、查找与历史 (File & Search & History)

| 快捷键 | 描述 | 分组/备注 |
| :--- | :--- | :--- |
| `<leader><space>` | **查找文件** (根目录) | `<leader>f` |
| `<leader>fe` | **文件浏览器** (根目录) | `<leader>e` |
| `<leader>fE` | **文件浏览器** (当前目录) | |
| `<leader>e` | **切换文件浏览器** | |
| `<leader>H` | **显示/隐藏隐藏文件** | |
| `<leader>ff` | **查找文件** (根目录) | |
| `<leader>fF` | **查找文件** (当前目录) | |
| `<leader>fg` | **查找 Git 文件** | |
| `<leader>fr` | **最近文件** (根目录) | |
| `<leader>fR` | **最近文件** (当前目录) | |
| `<leader>fc` | **查找配置文件** | |
| `<leader>fn` | **新建文件** | |
| `<leader>fp` | **项目列表** | |
| `<leader>sg` | **全局搜索 (Grep)** (根目录) | `<leader>s` |
| `<leader>sG` | **全局搜索 (Grep)** (当前目录) | |
| `<leader>sw` | **搜索单词** (项目) | |
| `<leader>sW` | **搜索单词** (当前目录) | |
| `<leader>sr` | **查找并替换** | |
| `<leader>su` | **撤销历史** | |
| `<leader>sm` | **标记管理** | |
| `<leader>ss` | **文档符号** | |
| `<leader>sS` | **项目符号** | |
| `<leader>hn` | **通知历史** | `<leader>h` |
| `<leader>hl` | **最后一条通知** | |
| `<leader>ha` | **所有通知** | |
| `<leader>hx` | **清除所有通知** | |
| `<leader>hc` | **命令历史** | |
| `<leader>hs` | **搜索历史** | |

### 🗂️ 缓冲区与书签 (Buffers & Marks)

| 快捷键 | 描述 | 分组/备注 |
| :--- | :--- | :--- |
| `<leader>bb` | **切换到上一个 Buffer** | `<leader>b` |
| `<leader>bd` | **关闭当前 Buffer** (不关窗口) | |
| `<leader>bh` | **上一个 Buffer** | |
| `<leader>bl` | **下一个 Buffer** | |
| `<leader>bo` | **关闭其他 Buffer** (跳过固定) | |
| `<leader>bp` | **切换固定 (Pin)** | |
| `<leader>bH` | **关闭左侧所有 Buffer** | |
| `<leader>bL` | **关闭右侧所有 Buffer** | |
| `<leader>bP` | **清理所有非固定 Buffer** (保护布局) | |
| `m` | **切换书签** (添加/移除) | `util.marks` |
| `]m` | **下一个书签** | |
| `[m` | **上一个书签** | |
| `'` (单引号) | **搜索书签** (Picker 视图) | |
| `<leader>bs` | **搜索书签** (Picker 视图) | |
| `<leader>bc` | **清空当前文件书签** | |
| `<leader>bC` | **清空所有书签** (带确认) | |

### 🚀 运行、调试与模板 (Run & Debug & Template)

| 快捷键 | 描述 | 分组/备注 |
| :--- | :--- | :--- |
| `<leader>rr` | **运行当前文件** (识别 C/HTML/JS/Py) | `<leader>r` |
| `<leader>rp` | **运行项目** (根据配置执行) | |
| `<leader>rl` | **查看运行日志** (实时 Tail) | |
| `<leader>rs` | **停止所有后台任务** | |
| `<leader>rc` | **配置当前文件运行命令** | |
| `<leader>rC` | **配置项目运行命令** | |
| `<leader>rb` | **配置文件浏览器关联 URL** | |
| `<leader>rB` | **配置项目浏览器关联 URL** | |
| `<leader>ro` | **打开浏览器** (关联预览 URL) | |
| `<leader>rv` | **选择 Python 虚拟环境** | |
| `<leader>rV` | **选择 TypeScript 工作区版本** | |
| `<leader>tn` | **根据模板新建文件** 📄 | `<leader>t` |
| `<leader>dt` | **切换调试面板 (UI)** | `<leader>d` |
| `<leader>dc` | **调试：开始 / 继续** (Continue) | |
| `<leader>di` | **调试：步入** (Step Into) | |
| `<leader>do` | **调试：步过** (Step Over) | |
| `<leader>du` | **调试：步出** (Step Out) | |
| `<leader>db` | **切换断点** (持久化) | |
| `<leader>dB` | **设置条件断点** (持久化) | |
| `<leader>dX` | **清除所有断点** (持久化) | |
| `<leader>dM` | **调试 Python 方法 (Method)** | |
| `<leader>dC` | **调试 Python 类 (Class)** | |
| `<leader>dp` | **切换性能分析器** | |
| `<leader>dh` | **性能分析高亮** | |
| `<leader>dd` | **文档诊断列表** | |
| `<leader>dD` | **项目诊断列表** | |

### 🛠 代码与 LSP (Code & Refactor)

| 快捷键 | 描述 | 分组/备注 |
| :--- | :--- | :--- |
| `<leader>ca` | **代码操作 (Code Action)** | `<leader>c` |
| `<leader>cA` | **项目操作 (Source Action)** | |
| `<leader>cr` | **重命名 (Rename)** | |
| `<leader>cf` | **格式化代码** (强制 Tab) | |
| `<leader>cl` | **LSP 信息** | |
| `<leader>cm` | **Mason 插件管理** | |
| `<leader>cd` | **显示行诊断浮窗** | |
| `<leader>cn` | **跳转到指定行** (输入行号) | |
| `<leader>c/` | **切换行注释** | |
| `<leader>co` | **整理导入** (TS/Vue) | |
| `<leader>cu` | **删除未使用导入** (TS/Vue) | |
| `<leader>ci` | **添加缺失导入** (TS/Vue) | |
| `<leader>cx` | **修复所有诊断** (TS/Vue) | |
| `<leader>cs` | **显示符号结构 (Outline)** | |
| `<leader>r` | **智能重构** (Visual 模式选中操作) | `util.refactor` |

### 🧡 Git 集成 (Git Integration)

| 快捷键 | 描述 | 分组/备注 |
| :--- | :--- | :--- |
| `<leader>gc` | **Git 面板 (Fugitive 悬浮)** | `<leader>g` |
| `<leader>gl` | **Git 日志 (自定义宽布局)** | |
| `<leader>gs` | **Git 状态 (Picker)** | |
| `<leader>gg` | **Git 提交图 (Floating)** | |
| `<leader>gb` | **Git Blame / 行追溯** | |
| `<leader>gd` | **查看本地差异 (LazyGit)** | |
| `<leader>gD` | **查看远程差异 (LazyGit)** | |
| `<leader>gp` | **Git 推送 (先 Fetch)** | |
| `<leader>gP` | **Git 拉取 (Pull)** | |
| `<leader>ga` | **Git 暂存当前目录下所有更改** | |
| `<leader>gC` | **Git 切换分支 (LazyGit)** | |
| `<leader>gS` | **Git Stash (LazyGit)** | |
| `<leader>gro` | **浏览器打开远程仓库** | |
| `<leader>gq` | **关闭 Diffview 视图** | |

### 🍱 窗口、标签页与界面 (Windows & Tabs & UI)

| 快捷键 | 描述 | 分组/备注 |
| :--- | :--- | :--- |
| `<leader>w-` | **向下分割窗口** | `<leader>w` |
| `<leader>w\|` | **向右分割窗口** | |
| `<leader>wd` | **关闭当前窗口** | |
| `<leader>wh/j/k/l` | **切换窗口** (左/下/上/右) | |
| `<leader>wH/J/K/L` | **移动窗口位置** (左/下/上/右) | |
| `<leader>w=` | **均衡所有窗口大小** | |
| `<leader>wm` | **最大化/恢复窗口 (Zoom)** | |
| `<leader>wr` | **调整窗口大小** (触发持久化) | |
| `<leader><tab><tab>`| **新建标签页** | `<leader><tab>` |
| `<leader><tab>d` | **关闭标签页** | |
| `<leader><tab>n/p` | **下一个/上一个标签页** | |
| `<leader><tab>o` | **关闭其他标签页** | |
| `<leader>ut` | **切换透明模式** | `<leader>u` |
| `<leader>ua` | **切换动画** | |
| `<leader>uz` | **切换禅模式 (Zen)** | |
| `<leader>uZ` | **切换缩放模式** | |
| `<leader>ul` | **切换行号显示** | |
| `<leader>ud` | **切换诊断显示** | |
| `<leader>uf` | **切换自动格式化** | |
| `<leader>uT` | **切换标签栏 (Tabline)** | |

### 🤖 AI 与补全 (AI & Completion)

| 快捷键 | 描述 | 模式/备注 |
| :--- | :--- | :--- |
| `Tab` | **采纳 Copilot 建议** / **确认补全** | 插入模式 |
| `<M-]>` / `<M-[>` | **下/上一个 AI 建议** | 插入模式 |
| `<C-]>` | **忽略当前 AI 建议** | 插入模式 |
| `<M-CR>` | **打开 Copilot 建议面板** | 普通模式 |
| `gr` | **刷新建议方案** | Copilot 面板 |
| `<CR>` | **采纳选中的建议** | Copilot 面板 |

### 💻 终端与临时 Buffer (Terminal & Scratch)

| 快捷键 | 描述 | 模式/备注 |
| :--- | :--- | :--- |
| `<leader>tf` | **浮窗终端** 💎 | `<leader>t` |
| `<leader>th` | **竖直终端 (上下分割)** | |
| `<leader>tv` | **水平终端 (左右分割)** | |
| `<leader>tt` | **标签页终端** | |
| `<C-\>` | **切换/呼出上次使用的终端** | 全局 (含终端) |
| `<Esc>` | **退出终端模式返回普通模式** | 终端模式 |
| `<leader>Ss` | **打开默认临时 Buffer** | `<leader>S` |
| `<leader>Sn` | **新建命名临时 Buffer** | |
| `<leader>S.` | **切换/找回临时 Buffer** | |
| `<leader>SS` | **选择/管理所有临时 Buffer** | |

### ⌨️ 通用编辑增强 (General)

| 快捷键 | 描述 | 模式/备注 |
| :--- | :--- | :--- |
| `s` | **Flash 快速跳转** (屏幕搜索) | 普通/可视/操作 |
| `gl` | **行诊断切换** (智能浮窗) | 普通模式 |
| `<M-v>` | **竖向块选择** (Mac 兼容) | 普通/可视 |
| `<A-j>` / `<A-k>` | **向下/向上移动当前行或选区** | 普通/可视 |
| `ciq` / `cie` / `cib` | **快速修改 "" / '' / () 内部内容** | 普通模式 |
| `<M-z>` | **跳转到文件末尾并居中** | 普通/插入 |
| `<M-h>` / `<M-l>` | **跳转到行首 / 行尾** | 普通/操作/可视 |
| `q` | **关闭当前 Buffer** (保护侧边栏布局) | 普通模式 |
| `<M-q>` | **切换文件浏览器 (Explorer)** | 普通模式 |
| `<M-=>` / `<M-->` | **下一个 / 上一个 Buffer** | 普通模式 |
| `<leader>k` / `<leader>K` | **DevDocs 文档查询** (词/输入) | 普通模式 |

---
**配置维护者**: Dyx | **基于**: LazyVim | **更新日期**: 2026-02-08