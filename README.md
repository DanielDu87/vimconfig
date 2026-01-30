# Neovim 深度定制配置 (基于 LazyVim)

本仓库包含一份基于 [LazyVim](https://www.lazyvim.org/) 构建的高级 **Neovim 配置文件**。它专为全栈开发（TypeScript, Vue, Python, Docker）量身定制，核心理念是**高性能**、**视觉透明化**以及**极致的中文本地化体验**。

## ✨ 核心特性

### 1. 🎨 极致 UI 与主题

- **全局透明化**：编辑器背景、浮动窗口、侧边栏、补全菜单等均已配置为透明，完美融入终端背景（配置位于 `lua/plugins/theme.lua`）
- **主题持久化**：主题选择会自动保存到 `~/.local/state/nvim/colorscheme`，重启后自动恢复
- **主题配置**：默认使用 Tokyo Night 主题，支持透明背景和自定义高亮
- **深度中文本地化**：
    - `Which-Key` 快捷键菜单全中文注释，覆盖所有主要功能菜单
    - `Lazy.nvim` 插件管理器界面中文化
    - 文件资源管理器操作菜单中文化
    - 统一的中文括号格式：`功能（说明）`，如 `查找文件（根目录）`、`查找文件（当前目录）`
    - Snacks Picker 通知自动汉化（未找到结果、通知历史等）
- **界面美化**：集成 `Snacks.nvim` 提供现代化的 UI 组件（Picker、Notifier、Terminal、Scratch、Explorer）
- **Buffer 栏增强**：
    - 当前选中的 buffer 显示蓝色下划线（`#2b85b7`），清晰标识当前编辑位置
    - 即使在有错误/警告的 buffer 上，下划线也始终显示，不会被诊断颜色覆盖
    - 固定的 buffer 显示 📌 图标
- **Git Log 视图增强**：
    - `<leader>gl` 命令提供高度可视化的 Git 提交详情视图
    - 通过自定义高亮，清晰区分 HEAD 指针（亮紫色）、本地分支（亮绿色）、远程分支（灰色）和标签（青色）
    - 所有文本（包括括号）均显示为非斜体，哈希值后带有空格，提升阅读体验
    - 支持按 Tab 键在历史列表和差异预览之间切换焦点
    - 确认提交后自动打开 Diffview 查看详细差异

### 2. ⚡️ 高效文件管理 (Explorer)

- **增强型操作**：重写了文件操作逻辑 (`lua/util/explorer_actions.lua`)，支持 Windows 风格的**剪切/复制/粘贴**
- **智能冲突处理**：粘贴时自动检测文件名冲突，并提供重命名或自动备份策略（`foo.txt` → `foo~1.txt`）
- **路径修复**：复制路径到剪贴板时自动去除多余换行符，方便终端使用
- **目录保护**：防止误删项目根目录
- **宽度持久化**：Explorer 宽度自动保存到 `~/.config/nvim/.explorer_width`，重启后恢复
- **快捷键优化**：
    - `<M-=>` / `<M-->` - 下一个/上一个缓冲区
    - `<M-h>` / `<M-l>` - 行首/行尾跳转
    - `<M-z>` - 跳转到文件末尾并居中
    - `<M-q>` - 切换文件资源管理器
    - `q` - 关闭缓冲区（不关闭窗口，保留布局）
    - `x` - 剪切文件/目录
    - `y` - 复制文件/路径
    - `p` - 粘贴（支持自动重命名/移动）
    - `d` - 删除（带确认对话框）
    - `a` - 新建文件/目录
    - `r` - 重命名

### 3. 🧡 Git 集成

本配置采用 Fugitive + Diffview + Snacks.nvim 的组合，提供流畅的 Git 工作流：

#### 3.1 Git 插件分工

| Git 功能 | 快捷键 | 使用插件 | 功能说明 |
|---------|--------|---------|---------|
| **面板（悬浮）** | `<leader>gc` | **vim-fugitive** | 浮动窗口显示当前 Git 状态 |
| **日志（宽布局）** | `<leader>gl` | **snacks.picker.git_log** | 提交历史 + 差异预览 + Diffview 联动 |
| **提交图** | `<leader>gg` | **snacks.terminal** | 显示 Git 树状提交图（浮动） |
| **状态选择器** | `<leader>gs` | **snacks.picker.git_status** | Picker 界面快速选择/跳转文件 |
| **行追溯** | `<leader>gb` | **snacks.git.blame_line** | 显示当前行的 Git Blame 详情 |
| **差异查看** | `<leader>gd` | **LazyGit** | 本地代码差异查看（TUI 浮动） |
| **远程差异** | `<leader>gD` | **LazyGit** | 远程代码差异查看（先自动 fetch） |
| **分支管理** | `<leader>gC` | **LazyGit** | TUI 界面切换/创建/管理分支 |
| **Stash 管理** | `<leader>gS` | **LazyGit** | TUI 界面管理 Git Stash |
| **从远程拉取** | `<leader>gP` | **snacks.terminal** | 浮动终端执行 git pull |
| **暂存当前** | `<leader>ga` | **shell** | 快速执行 git add -A (当前目录) |
| **推送到远程** | `<leader>gp` | **snacks.terminal** | Fetch 所有远程并执行 Push |
| **关闭 Diffview** | `<leader>gq` | **diffview.nvim** | 关闭全屏差异对比视图 |

#### 3.2 Git 工作流详解

**状态面板** (`<leader>gc`)：
  - 浮动窗口显示当前 Git 状态
  - 一键快捷操作：`c` 规范化提交、`C` 一键备份、`a` 全部暂存
  - `d` 打开全屏 Diffview 查看差异
  - 回车键展开/折叠差异详情

**Git 日志** (`<leader>gl`)：
  - 纵向布局，上方显示提交历史（40%高度）
  - 下方显示差异预览（60%高度）
  - 自定义高亮：HEAD（紫色）、本地分支（绿色）、远程分支（灰色）、标签（青色）
  - 按 Tab 键在历史列表和差异预览之间切换焦点
  - 确认提交后自动打开 Diffview

**提交流程**：
  1. 按 `<leader>gc` 打开 Git 状态面板
  2. 按文件查看差异，按 `s` 暂存文件
  3. 按 `c` 启动 Conventional Commits 规范化提交
     - 选择提交类型（feat、fix、docs、style、refactor、test、chore）
     - 输入提交描述（支持中文）
  4. 或者直接按 `C` 一键备份（格式：`+YYYY-MM-DD HH:MM 备份`）

**差异查看流程**：
  1. 在 Git 状态面板中按 `d` 打开 Diffview
  2. 或直接按 `<leader>gd` 打开 LazyGit
  3. 在 Diffview 中查看详细差异
  4. 按 `q` 关闭 Diffview 并返回 Git 状态面板

### 4. 🛠 代码规范与工具链

#### 4.1 强制 Tab 缩进

- 全项目强制使用 **Tab** 进行缩进（宽度 4 空格）。
- 通过 `lua/util/format.lua` 自定义管道确保保存时同步格式化。
- 支持多语言格式化（Prettier, Black, Stylus 等）。

#### 4.2 LSP (语言服务)

- **预配置语言支持**：
    - **TypeScript/JavaScript**: ts_ls (用于 JS), vtsls (用于 TS/Vue)
    - **Python**: Pyright + Ruff
    - **Vue**: vtsls + Vue LSP
    - **HTML/CSS**: html LSP + emmet_ls + stylelint_lsp
    - **Docker**: dockerfile LSP
    - **Markdown**: marksman
- **Inlay Hints (内联提示)**：
    - TypeScript: 参数名、参数类型、变量类型、返回值类型
    - JavaScript: 参数名、变量类型、返回值类型
- **代码补全**：基于 `blink.cmp` 的高性能补全引擎。
- **自动导入整理**：`<leader>co` 整理导入，`<leader>cu` 删除未使用导入。

#### 4.3 实时代码检查 (Lint & Diagnostics)

本配置使用 **nvim-lint** 提供实时代码检查，配合 **tiny-inline-diagnostic** 提供美观的多行诊断显示。

- **多 Linter 支持详情**：

  | 文件类型 | Linter | 检查功能 | 插件 |
  |---------|--------|---------|------|
  | HTML/HTM | **markuplint** | HTML 标记验证、结构检查 | nvim-lint |
  | HTMldjango | **markuplint** | Django 模板标记验证 | nvim-lint |
  | CSS/SCSS/LESS | **stylelint** | CSS 语法、规范检查 | nvim-lint |
  | JavaScript/JSX | **eslint** | JS 代码规范、潜在错误 | nvim-lint |
  | TypeScript/TSX | **eslint** | TS 代码规范、类型检查 | nvim-lint |
  | Vue | **eslint** | Vue 模板、脚本、样式检查 | nvim-lint |
  | Python | **ruff** | Python 语法、规范、类型检查 | nvim-lint |
  | Dockerfile | **hadolint** | Dockerfile 最佳实践、语法检查 | nvim-lint |

- **诊断显示方式**：
    1. **行内多行显示**：使用 `tiny-inline-diagnostic` 插件，自动换行
    2. **光标悬浮窗**：光标停留时自动弹出详细诊断（支持换行）
    3. **波浪下划线**：所有诊断级别（Error/Warning/Info/Hint）显示下划线
    4. **符号列**：左侧显示诊断图标

- **实时触发机制**：
    - ✅ **编辑时触发**：普通模式和插入模式文本改变时（500ms 防抖）
    - ✅ **保存时触发**：文件保存后立即检查
    - ✅ **打开时触发**：读取文件时自动检查
    - ✅ **退出插入模式**：退出插入模式时立即检查

- **插入模式支持**：
    - 行内诊断在插入模式下实时显示
    - `update_in_insert = true` 允许插入模式更新诊断
    - `enable_on_insert = true` 允许插入模式显示行内提示
    - `throttle = 0` 确保无延迟显示

#### 4.4 代码格式化 (Formatting)

本配置使用 **Conform.nvim** 提供统一的代码格式化，强制使用 Tab 缩进（宽度 4）。

- **格式化工具详情**：

  | 文件类型 | 主格式化器 | 辅助格式化器 | 功能 | 插件 |
  |---------|-----------|-------------|------|------|
  | JavaScript | **eslint_d** → **prettier** | - | 代码规范修复 + 美化 | Conform.nvim |
  | JSX | **eslint_d** → **prettier** | - | React 代码规范 + 美化 | Conform.nvim |
  | TypeScript | **eslint_d** → **prettier** | - | TS 代码规范 + 美化 | Conform.nvim |
  | TSX | **eslint_d** → **prettier** | - | React TS 代码规范 + 美化 | Conform.nvim |
  | Vue | **eslint_d** → **prettier** | - | Vue 代码规范 + 美化 | Conform.nvim |
  | HTML | **prettier** | - | HTML 结构美化 | Conform.nvim |
  | HTMldjango | **prettier** | - | Django 模板美化 | Conform.nvim |
  | CSS | **stylelint** → **prettier** | - | CSS 规范 + 美化 | Conform.nvim |
  | SCSS | **stylelint** → **prettier** | - | SCSS 规范 + 美化 | Conform.nvim |
  | LESS | **stylelint** → **prettier** | - | LESS 规范 + 美化 | Conform.nvim |
  | JSON | **prettier** | - | JSON 格式化 | Conform.nvim |
  | YAML | **prettier** | - | YAML 格式化 | Conform.nvim |
  | Markdown | **prettier** | - | Markdown 格式化 | Conform.nvim |
  | Python | **isort** → **black** | - | 导入排序 + 代码格式化（空格） | Conform.nvim |
  | Lua | **stylua** | - | Lua 格式化（Tab） | Conform.nvim |
  | Go | **goimports** → **gofumpt** | - | 导入整理 + 严格格式化 | Conform.nvim |
  | Rust | **rustfmt** | - | Rust 格式化 | Conform.nvim |
  | Shell | **shfmt** | - | Shell 脚本格式化（Tab） | Conform.nvim |
  | SQL | **prettier** (sql-formatter) | - | SQL 格式化（4 空格，关键字大写） | Conform.nvim |
  | Dockerfile | **docker_uppercase** (自定义) | **trim_whitespace** | 指令大写 + 去除尾随空格 | Conform.nvim |

- **格式化器配置说明**：
  - **Tab 缩进**：除 Python（社区强制空格）外，所有语言均使用 Tab 缩进（宽度 4）
  - **路径自动检测**：使用 `vim.fn.exepath()` 自动检测工具路径，支持：
    - Homebrew 安装（`/opt/homebrew/bin/`）
    - Mason 安装（`~/.local/share/nvim/mason/bin/`）
    - 系统全局路径
  - **Prettier 配置**：
    - `--use-tabs` - 使用 Tab
    - `--tab-width 4` - Tab 宽度为 4
    - `--print-width 120` - 每行最大 120 字符
    - `--bracket-same-line true` - `>` 与标签同行
    - `--plugin prettier-plugin-tailwindcss` - Tailwind CSS 类名排序
  - **Dockerfile 自定义格式化器**：使用 Perl 将指令（FROM、RUN、CMD 等）转换为大写，并压缩多余空格

#### 4.5 代码重构 (Refactoring)

- **Visual 模式智能重构** (`<leader>cr`)：
    - ✨ 提取函数
    - 🧱 提取代码块
    - 📦 提取变量
    - 📥 内联函数
    - 🗑️ 内联变量
    - 📄 提取函数到文件
    - 📁 提取代码块到文件

- **重构特性**：
    - 中文菜单界面
    - 自动选区精修（去除空行、括号匹配、引号处理）
    - 自动进入插入模式
    - 聚焦定时器确保输入框获得焦点

- **LSP 重命名** (`<leader>cn`)：
    - 实时预览所有引用处
    - 青蓝色高亮显示
    - 中文提示信息

### 5. 🐞 智能调试 (DAP)

本配置采用 nvim-dap + nvim-dap-ui，提供专业级的调试体验：

- **布局持久化**：
    - 自动记录您手动调整的调试窗口（变量、堆栈、控制台）尺寸
    - 保存到 `~/.config/nvim/.dapui_layout`
    - 下次打开调试时**立即同步恢复**，无视觉跳变

- **断点管理**：
    - 使用 persistent-breakpoints.nvim 自动保存断点到项目目录（`.nvim/breakpoints.json`）
    - 断点在关闭 Neovim 后依然保留
    - 支持条件断点

- **调试器支持**：
    - **Python**: DebugPy 调试器（自动安装）
    - **JavaScript/TypeScript**: js-debug-adapter（自动安装）

- **视觉优化**：
    - 调试窗口分割线使用青蓝色高亮（`#2b85b7`），提升视觉辨识度
    - 断点图标：🔴（已启用）、▶️（运行位置）
    - 虚拟文本显示变量值

- **自动控制**：
    - 调试会话开始时自动打开 UI
    - 调试会话结束时自动关闭 UI
    - 断点命中时自动聚焦到调试窗口

### 6. ⚡ 快速跳转 (Flash)

- **Flash.nvim** 提供类似 easymotion 的快速跳转功能
- **多字符搜索**：按 `s` 后可连续输入多个字符精确匹配
- **实时标签**：所有匹配位置显示标签，快速跳转
- **多模式支持**：支持普通模式、可视模式、操作符模式

### 7. ⚡ 性能优化

本配置在多个方面进行了性能优化：

- **格式化器路径检测**：使用 `vim.fn.exepath()` 自动检测工具路径，支持多种安装方式（Homebrew、Mason、系统全局）
- **防抖机制**：
    - Explorer 宽度保存使用 500ms 防抖
    - DAP 布局保存使用 500ms 防抖
    - 避免频繁 I/O 操作
- **延迟加载**：所有插件均使用懒加载，仅在需要时加载
- **异步执行**：文件操作使用异步系统调用，避免阻塞
- **智能缓存**：LSP 和诊断结果智能缓存，减少重复计算

### 7. 🎯 其他增强功能

- **历史记录管理**：
    - `<leader>hn` - 通知历史记录
    - `<leader>hl` - 最后一条通知
    - `<leader>ha` - 所有通知
    - `<leader>hx` - 清除所有通知
    - `<leader>hc` - 命令历史
    - `<leader>hs` - 搜索历史

- **Buffer 管理**：
    - `<leader>bp` - 切换固定（Pinned）
    - `<leader>bh` / `<leader>bl` - 上一个/下一个 Buffer
    - `<leader>bH` - 关闭左侧所有 Buffer
    - `<leader>bL` - 关闭右侧所有 Buffer
    - `<leader>bo` - 关闭其他 Buffer
    - `<leader>bP` - 清理所有非固定 Buffer（保护侧边栏布局）

- **临时 Buffer（Scratch）**：
    - `<leader>Ss` - 打开默认临时 Buffer
    - `<leader>Sn` - 新建命名临时 Buffer
    - `<leader>S.` - 切换临时 Buffer
    - `<leader>SS` - 选择/管理临时 Buffer

- **终端管理**：
    - `<leader>tf` - 浮窗终端
    - `<leader>th` - 竖直终端（上下）
    - `<leader>tv` - 水平终端（左右）
    - `<leader>tt` - 标签页终端

- **文档查询**：
    - `<leader>k` - 查询 DevDocs（当前关键词）
    - `<leader>K` - 搜索 DevDocs（输入查询）

- **TS 版本切换**：
    - `<leader>rV` - 选择 TypeScript 工作区版本（仅 TS/Vue 文件）

- **运行配置**：
    - 本配置支持 Runner 插件，提供项目运行和调试功能
    - 支持多种项目类型的运行配置
    - 详细的日志输出和语法高亮（`runnerlog` 文件类型）

## 📂 项目结构说明

```text
~/.config/nvim/
├── init.lua                    # 🚀 入口文件
├── lua/
│   ├── config/                 # ⚙️ 核心配置
│   │   ├── autocmds.lua        # 自动命令 (格式化触发、窗口事件)
│   │   ├── keymaps.lua         # 通用快捷键定义
│   │   ├── lazy.lua            # 插件管理器引导
│   │   └── options.lua         # Vim 选项 (Tab设置、UI细节)
│   ├── plugins/                # 🧩 插件定义 (按功能分类)
│   │   ├── editor.lua          # 编辑器增强 (Snacks, WhichKey, 中文翻译)
│   │   ├── explorer.lua        # 文件浏览器配置 (Snacks.nvim)
│   │   ├── terminal.lua        # 终端管理配置 (ToggleTerm.nvim)
│   │   ├── formatting.lua      # 格式化核心配置 (Conform.nvim)
│   │   ├── lsp.lua             # LSP 配置 + nvim-lint 实时检查
│   │   ├── diagnostics.lua     # 诊断显示 (tiny-inline-diagnostic + 重构键位)
│   │   ├── dap.lua             # 调试功能与布局管理核心
│   │   ├── theme.lua           # 主题与透明度设置
│   │   ├── highlight.lua       # 语法高亮 (Treesitter, Rainbow, Color)
│   │   ├── refactoring.lua     # 代码重构插件配置
│   │   └── extras.lua          # LazyVim extras 管理中心
│   └── util/                   # 🔧 自定义工具库 (核心逻辑)
│       ├── explorer_actions.lua # 文件操作状态机 (剪切/复制/粘贴)
│       ├── format.lua          # 格式化控制中心
│       └── refactor_smart.lua  # 智能重构菜单 (中文界面)
├── stylua.toml                 # Lua 代码风格配置
└── lazy-lock.json              # 插件版本锁定文件
```

## ⌨️ 常用快捷键速查

### 🚀 常用操作

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader><space>` | **命令面板** (查找文件、命令、符号) |
| `<leader>e` / `<leader>fe` | 打开/切换 **文件资源管理器（根目录）** |
| `<leader>cf` | **格式化代码** (强制 Tab 缩进) |
| `<leader>sg` / `<leader>/` | **全局搜索** (Grep) |
| `<leader>ff` | **查找文件（根目录）** |
| `<leader>fF` | **查找文件（当前目录）** |
| `<leader>fg` | **查找Git文件** |
| `<leader>fb` | **查找Buffer** |
| `<leader>fB` | **查找Buffer（所有）** |
| `<leader>fr` | **最近文件（根目录）** |
| `<leader>fR` | **最近文件（当前目录）** |
| `<leader>fc` | **查找配置文件** |
| `<leader>bd` | 关闭当前缓冲区 (Buffer) |
| `<M-=>` / `<M-->` | 下一个/上一个缓冲区 |
| `<M-q>` | 切换文件资源管理器 |
| `q` | 关闭当前缓冲区 (不关闭窗口，保护布局) |

### 🚀 运行与预览 (Runner)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>rr` | **运行当前文件** (HTML/JS/Python) |
| `<leader>rp` | **运行项目** |
| `<leader>rl` | **查看运行日志** |
| `<leader>rs` | **停止后台任务** |
| `<leader>rc` | **配置当前文件运行命令** |
| `<leader>rC` | **配置项目运行命令** |
| `<leader>ro` | **在浏览器打开** |
| `<leader>rb` | **配置文件浏览器URL** |
| `<leader>rB` | **配置项目浏览器URL** |
| `<leader>rv` | **选择 Python 虚拟环境** |
| `<leader>rV` | **选择 TS 工作区版本** |

### 💻 终端操作 (Terminal)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>tf` | **浮窗终端** 💎 |
| `<leader>th` | **竖直终端（上下）** ↕️ |
| `<leader>tv` | **水平终端（左右）** ↔️ |
| `<leader>tt` | **标签页终端** 📑 |

### 🐞 调试 (DAP)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>dt` | **切换调试界面** (自动恢复布局) |
| `<leader>db` | 切换 **断点**（持久化） |
| `<leader>dB` | 设置 **条件断点**（持久化） |
| `<leader>dX` | **清除所有断点**（持久化） |
| `<leader>dc` | **开始 / 继续** (Continue) |
| `<leader>di` | **步入** (Step Into) |
| `<leader>do` | **步过** (Step Over) |
| `<leader>du` | **步出** (Step Out) |
| `<leader>dM` | **调试方法**（Python） |
| `<leader>dC` | **调试类**（Python） |
| `<leader>dp` | **切换性能分析器** |
| `<leader>dh` | **性能分析高亮** |

### 🔨 代码重构与诊断

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>c/` | **切换行注释** |
| `<leader>cr` | **重命名** (LSP) |
| `<leader>ca` | **代码操作** (Code Action) |
| `<leader>cA` | **项目操作** (Source Action) |
| `<leader>r` | **智能重构** (Visual 模式对选区操作) |
| `<leader>cn` | **跳转到指定行** |
| `gl` | **行诊断** (切换浮窗) |
| `<leader>co` | **整理导入** (TypeScript/Vue) |
| `<leader>cu` | **删除未使用的导入** (TypeScript/Vue) |
| `<leader>ci` | **添加缺失导入** |
| `<leader>cx` | **修复所有诊断** |
| `<leader>cl` | **LSP信息** |
| `<leader>cm" | **Mason插件管理** |

### 🧡 Git 操作

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>gc` | **Git 面板**（Fugitive 悬浮） |
| `<leader>gl` | **Git 日志**（自定义宽布局） |
| `<leader>gg` | **Git 提交图** |
| `<leader>gs` | **Git 状态** (Picker) |
| `<leader>gb` | **Git Blame** (行追溯/选区追溯) |
| `<leader>gd` | **本地差异** (LazyGit) |
| `<leader>gD` | **远程差异** (LazyGit) |
| `<leader>ga` | **Git 暂存** (当前目录全部) |
| `<leader>gC` | **Git 切换分支** (LazyGit) |
| `<leader>gS` | **Git Stash** (LazyGit) |
| `<leader>gp` | **Git 推送** (先 fetch) |
| `<leader>gP` | **Git 拉取** |

### 📂 文件资源管理器 (Explorer)

> 在 Explorer 窗口中生效

| 快捷键 | 描述 |
| :--- | :--- |
| `y` | **复制** 文件/路径 (到剪贴板) |
| `x` | **剪切** 文件 |
| `p` | **粘贴** 文件 (支持自动重命名/移动) |
| `d` | **删除** 文件 (带确认) |
| `a` | **新建** 文件/目录 |
| `r` | **重命名** |
| `q` | 关闭缓冲区（不关闭窗口） |
| `<leader>H` | **切换显示隐藏文件** |
| `<Esc>` | **取消多选/清除选择** |

### 🎨 光标移动与编辑增强

| 快捷键 | 描述 |
| :--- | :--- |
| `s` | **Flash 快速跳转**（连续输入字符精确匹配） |
| `<M-h>` | 跳转到 **行首** |
| `<M-l>` | 跳转到 **行尾** |
| `<M-z>` | 跳转到 **文件末尾并居中** |
| `<A-j>` | **向下移动** 当前行/选中区域 |
| `<A-k>` | **向上移动** 当前行/选中区域 |
| `<leader>k` | **DevDocs 查询** (当前单词) |
| `<leader>K` | **DevDocs 搜索** (手动输入) |

### 🗂️ Buffer 管理

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>bb` | 切换到 **上一个/其他 Buffer** |
| `<leader>bd` | 关闭当前 Buffer |
| `<leader>bh` | **上一个** Buffer |
| `<leader>bl` | **下一个** Buffer |
| `<leader>bo` | **关闭其他** Buffer (跳过固定) |
| `<leader>bH` | **关闭左侧** 所有 Buffer (跳过固定) |
| `<leader>bL` | **关闭右侧** 所有 Buffer (跳过固定) |
| `<leader>bP` | **清理所有** 非固定 Buffer (保护侧边栏) |
| `<leader>bp` | **切换固定** (Pinned) |

### 📜 历史记录

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>hn` | **通知历史记录** |
| `<leader>hl` | **最后一条通知** |
| `<leader>ha` | **所有通知** |
| `<leader>hx` | **清除所有通知** |
| `<leader>hc` | **命令历史** |
| `<leader>hs` | **搜索历史** |

### 📝 临时 Buffer（Scratch）

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>Ss` | 打开 **默认临时 Buffer** |
| `<leader>Sn` | 新建 **命名临时 Buffer** |
| `<leader>S.` | 切换 **默认临时 Buffer** |
| `<leader>SS` | **选择/管理** 临时 Buffer |

### 🔍 搜索与查找

| 快捷键 | 描述 |
| :--- | :--- |
| `/` / `?` | **当前文件搜索** (精确匹配/列表导航) |
| `<leader>sb` | 查找当前文件行 |
| `<leader>sw` | 搜索单词（项目） |
| `<leader>sW` | 搜索单词（当前目录） |
| `<leader>sr` | 查找并替换 |
| `<leader>su` | 撤销历史 |
| `<leader>sm` | 标记管理 |
| `<leader>sk` | 快捷键映射查看 |
| `<leader>ss` | 文档符号 |
| `<leader>sS` | 项目符号 |

### 🍱 窗口管理

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>w-` | **向下分割** 窗口 |
| `<leader>w|` | **向右分割** 窗口 |
| `<leader>wd` | **关闭当前** 窗口 |
| `<leader>wh` | 切换到 **左侧** 窗口 |
| `<leader>wj` | 切换到 **下方** 窗口 |
| `<leader>wk` | 切换到 **上方** 窗口 |
| `<leader>wl` | 切换到 **右侧** 窗口 |
| `<leader>wH` | **向左移动** 窗口 |
| `<leader>wJ` | **向下移动** 窗口 |
| `<leader>wK` | **向上移动** 窗口 |
| `<leader>wL` | **向右移动** 窗口 |
| `<leader>w=` | **均衡窗口大小** |
| `<leader>wm` | **最大化/恢复** 窗口 |

### 🎨 界面开关 (Toggles)

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>ut` | **切换透明模式** |
| `<leader>ua` | **切换动画** |
| `<leader>uT` | **切换标签栏** |
| `<leader>ub` | **切换背景模式** |
| `<leader>ud` | **切换诊断显示** |
| `<leader>uf` | **切换自动格式化** |
| `<leader>ug` | **切换缩进引导线** |
| `<leader>ul` | **切换行号模式** |
| `<leader>uz` | **切换禅模式** |
| `<leader>uZ` | **切换缩放模式** |
| `<leader>us` | **切换拼写检查** |
| `<leader>uw` | **切换自动换行** |

### 🖥️ 外部工具增强 (BetterTouchTool)

本配置配合本地 **BetterTouchTool** 映射，实现了更加符合 macOS 习惯的全局快捷键支持：

| 外部快捷键 (BTT) | 映射到 Neovim 序列 | 功能说明 |
| :--- | :--- | :--- |
| `⌃ J` (Ctrl+J) | `⌃⇧ D` | **向下翻页** (Half Page Down) |
| `⌃ K` (Ctrl+K) | `⌃⇧ U` | **向上翻页** (Half Page Up) |
| `⌃ D` (Ctrl+D) | `Esc c c` | **修改当前行** (清除并进入插入模式) |
| `⇧⌃ J` (Ctrl+Shift+J) | `⌃ X` | **数字减** 1 |
| `⇧⌃ K` (Ctrl+Shift+K) | `⌃ A` | **数字加** 1 |
| `⌘ A` (Cmd+A) | `gg 0^vG$` | **全选** 文本 |
| `⌘ S` (Cmd+S) | `Esc :w <CR>` | **保存文件** |
| `⌘ /` (Cmd+/) | `Esc <leader>c/` | **切换行注释** |
| `⌘ Z` (Cmd+Z) | `Esc u` | **撤销** (Undo) |
| `⌘ C` (Cmd+C) | `Y` | **复制** 选区/行 (到寄存器) |

## 🔌 主要插件列表

### 核心插件

- **lazy.nvim** - 插件管理器（自动安装、更新、清理）
- **Snacks.nvim** - 现代化 UI 组件库（核心组件）
  - Explorer - 文件浏览器（替代 nvim-tree）
  - Picker - 模糊查找器（替代 Telescope）
  - Notifier - 通知系统（替代 nvim-notify）
  - Terminal - 终端管理器（内置）
  - Scratch - 临时 Buffer 管理
  - Toggle - UI 选项切换（动画、透明、zen 模式等）
- **toggleterm.nvim** - 终端管理器（浮窗、水平、垂直、标签页终端）
- **blink.cmp** - 高性能代码补全引擎
- **flash.nvim** - 快速跳转（类似 easymotion，支持多字符搜索）
- **nvim-lspconfig** - LSP 客户端配置
- **nvim-lint** - 非 LSP 代码检查（实时）
- **tiny-inline-diagnostic** - 行内多行诊断显示
- **Conform.nvim** - 代码格式化
- **which-key.nvim** - 快捷键菜单（全中文）

### Git 插件

- **vim-fugitive** - Git 命令集成（状态面板）
- **diffview.nvim** - Git 差异查看器
- **snacks.nvim** - Git 集成（blame、status、log）
- **LazyGit** - Git TUI（浮动窗口）
- **gitsigns.nvim** - Git 标记显示

### 语言支持

- **TypeScript/JavaScript**:
  - ts_ls (tsserver) - 用于 JS 文件
  - vtsls - 用于 TS/Vue 文件（支持工作区版本切换）
  - typescript.nvim - TypeScript 增强功能
  - eslint - 代码规范检查
  - nvim-vtsls - vtsls 辅助插件

- **Python**:
  - Pyright - 类型检查
  - Ruff - 快速 Linter 和格式化
  - DebugPy - 调试器

- **Vue**:
  - vtsls - Vue LSP 支持
  - eslint - Vue 代码规范

- **HTML/CSS**:
  - html LSP - HTML 语言服务
  - emmet_ls - Emmet 缩写展开
  - stylelint_lsp - CSS 样式检查
  - markuplint - HTML 标记验证

- **Docker**:
  - dockerfile LSP - Dockerfile 语言服务
  - hadolint - Dockerfile 最佳实践检查

- **Markdown**:
  - marksman - Markdown LSP

### 代码质量

- **refactoring.nvim** - 代码重构（提取、内联等）
- **inc-rename.nvim** - 带实时预览的重命名
- **nvim-treesitter** - 语法高亮和解析
- **rainbow-delimiters** - 彩虹括号
- **nvim-colorizer** - 颜色代码高亮（支持 Tailwind）

### 调试

- **nvim-dap** - 调试适配器协议核心
- **nvim-dap-python** - Python 调试集成
- **nvim-dap-ui** - 调试 UI 界面
- **persistent-breakpoints.nvim** - 断点持久化
- **nvim-dap-virtual-text** - 虚拟文本显示变量值

### UI 增强

- **tokyonight.nvim** - 主题（默认）
- **bufferline.nvim** - Buffer 标签栏
- **lualine.nvim** - 状态栏
- **indent-blankline.nvim** - 缩进指示线

### 其他工具

- **conventional-commits.nvim** - 规范化提交
- **neo-tree.nvim** - 备用文件浏览器（已禁用，使用 Snacks Explorer）
- **telescope.nvim** - 备用查找器（advanced-git-search 使用）

### 格式化工具

- **Prettier** - HTML/CSS/JS/TS 格式化
- **Black** - Python 格式化（优先 Homebrew 版本）
- **Stylua** - Lua 格式化
- **Shfmt** - Shell 格式化
- **SQL Formatter** - SQL 格式化
- **Stylelint** - CSS/SCSS/LESS 格式化（优先 Homebrew 版本）
- **Isort** - Python 导入排序
- **Docker Uppercase** - Dockerfile 指令大写转换（自定义）

## 🛠️ 安装与维护

### 首次安装

1. 确保已安装 **Neovim >= 0.9.0**。
2. 克隆本仓库到配置目录：
    ```bash
    git clone <repo-url> ~/.config/nvim
    ```
3. 启动 `nvim`，Lazy 会自动安装所有插件。

### 工具链管理

- **更新插件**：运行 `:Lazy sync`
- **查看插件状态**：运行 `:Lazy`
- **安装/管理 LSP & Tools**：运行 `:Mason`
    - 在弹出的菜单中，使用 `i` 安装，`u` 更新 LSP Server、Linter 或 Formatter
- **健康检查**：运行 `:checkhealth lazy`

### 推荐工具安装

通过 Mason 安装以下工具以获得完整体验：

**Linter (代码检查)**：

- `eslint` - JavaScript/TypeScript/Vue 代码规范
- `ruff` - Python 快速 Linter
- `hadolint` - Dockerfile 最佳实践
- `stylelint` - CSS/SCSS/LESS 样式检查
- `markuplint` - HTML 标记验证

**Formatter (代码格式化)**：

- `prettier` - HTML/CSS/JS/TS 格式化
- `black` - Python 格式化
- `stylus` - CSS/SCSS 格式化
- `stylua` - Lua 格式化

**Debugger (调试器)**：

- `debugpy` - Python 调试器

## 📝 开发规范

1. **代码风格**：
   - 所有文件必须使用 **Tab 缩进**，宽度设置为 **4 空格**
   - Lua 代码需符合 `stylua.toml` 规范

2. **插件配置**：
   - 尽量将特定插件的配置放在 `lua/plugins/` 下的独立文件中
   - 复杂的业务逻辑（如文件操作、自定义格式化）必须提取到 `lua/util/` 模块中，保持配置文件的整洁
   - 使用 LazyVim 的 `opts` 机制扩展默认配置，不要完全覆盖

3. **性能优化**：
   - 使用 `vim.fn.exepath()` 检测工具路径，支持多种安装方式
   - 使用防抖机制避免频繁 I/O 操作
   - 所有插件均使用懒加载，仅在需要时加载

4. **提交规范**：
   - 提交信息必须使用中文
   - 格式：`+YYYY-MM-DD HH:MM 内容`
   - 示例：`+2026-01-26 01:03 完善Lint诊断系统与实时检查`
   - 每次提交前更新 README

## 🔧 高级配置

### 修改诊断延迟

编辑 `lua/plugins/lsp.lua`，修改防抖时间：

```lua
local debounce_ms = 500  -- 默认 500ms，可改为 300（更快）或 1000（更省性能）
```

### 禁用插入模式诊断

编辑 `lua/plugins/diagnostics.lua`，修改：

```lua
opts.diagnostics.update_in_insert = false  -- 禁用插入模式更新
options.enable_on_insert = false           -- 禁用插入模式显示
```

### 切换主题

编辑 `lua/plugins/theme.lua`，修改主题名称：

```lua
opts.colorscheme = "tokyonight"  -- 可改为其他主题
```

### 添加新的 Linter

在 `lua/plugins/lsp.lua` 中添加：

```lua
lint.linters_by_ft.你的文件类型 = { "linter名称" }
```

## 📚 常见问题

### Q: 为什么诊断在插入模式不显示？

A: 检查 `lua/plugins/diagnostics.lua` 中的 `update_in_insert` 和 `enable_on_insert` 是否为 `true`。

### Q: Linter 没有运行？

A:

1. 检查 Linter 是否已安装（通过 Mason 或系统包管理器）
2. 运行 `:Mason` 确认 Linter 已安装
3. 运行 `:lua require('lint').try_lint()` 手动触发测试

### Q: 如何查看当前文件的诊断？

A: 运行 `:lua vim.print(vim.diagnostic.get(0))` 查看诊断列表。

### Q: 重构菜单不弹出？

A:

1. 确保在 Visual 模式下选中了代码
2. 运行 `:map <leader>cr` 检查键位绑定
3. 运行 `:Lazy` 检查 refactoring.nvim 是否已加载

---

**配置维护者**: Dyx
**基于**: LazyVim
**Neovim 版本要求**: >= 0.9.0
**最后更新**: 2026-01-29
