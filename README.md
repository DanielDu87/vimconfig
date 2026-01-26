# Neovim 深度定制配置 (基于 LazyVim)

本仓库包含一份基于 [LazyVim](https://www.lazyvim.org/) 构建的高级 **Neovim 配置文件**。它专为全栈开发（TypeScript, Vue, Python, Docker）量身定制，核心理念是**高性能**、**视觉透明化**以及**极致的中文本地化体验**。

## ✨ 核心特性

### 1. 🎨 极致 UI 与主题
- **全局透明化**：编辑器背景、浮动窗口、侧边栏、补全菜单等均已配置为透明，完美融入终端背景（配置位于 `lua/plugins/theme.lua`）。
- **主题配置**：默认使用 Tokyo Night 主题，支持透明背景和自定义高亮。
- **深度中文本地化**：
  - `Which-Key` 快捷键菜单全中文注释，覆盖所有主要功能菜单。
  - `Lazy.nvim` 插件管理器界面中文化。
  - 文件资源管理器操作菜单中文化。
  - 统一的中文括号格式：`功能（说明）`，如 `查找文件（根目录）`、`查找文件（当前目录）`。
- **界面美化**：集成 `Snacks.nvim` 提供现代化的 UI 组件（Picker、Notifier、Terminal 等）。

### 2. ⚡️ 高效文件管理 (Explorer)
- **增强型操作**：重写了文件操作逻辑 (`lua/util/explorer_actions.lua`)，支持 Windows 风格的**剪切/复制/粘贴**。
- **智能冲突处理**：粘贴时自动检测文件名冲突，并提供重命名或自动备份策略。
- **路径修复**：复制路径到剪贴板时自动去除多余换行符，方便终端使用。
- **目录保护**：防止误删项目根目录。
- **快捷键优化**：
  - `<M-=>` / `<M-->` - 下一个/上一个缓冲区
  - `<M-h>` / `<M-l>` - 行首/行尾跳转
  - `<M-z>` - 跳转到文件末尾并居中
  - `<M-q>` - 切换文件资源管理器
  - `q` - 关闭缓冲区（不关闭窗口，保留布局）

### 3. 🛠 代码规范与工具链

#### 3.1 强制 Tab 缩进
- 全项目强制使用 **Tab** 进行缩进（宽度 4 空格）。
- 通过 `lua/util/format.lua` 自定义管道确保保存时同步格式化。
- 支持多语言格式化（Prettier, Black, Stylus 等）。

#### 3.2 LSP (语言服务)
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

#### 3.3 实时代码检查 (Lint & Diagnostics)
- **多 Linter 支持**：
  | 文件类型 | Linter | 功能 |
  |---------|--------|------|
  | HTML/HTM | markuplint | HTML 标记验证 |
  | CSS/SCSS/LESS | stylelint | 样式检查 |
  | JavaScript/JSX | eslint | JS 代码规范 |
  | TypeScript/TSX | eslint | TS 代码规范 |
  | Vue | eslint | Vue 代码规范 |
  | Python | ruff | Python 快速 Linter |
  | Dockerfile | hadolint | Dockerfile 最佳实践 |

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

#### 3.4 代码重构 (Refactoring)
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

### 4. 🐞 智能调试 (DAP)
- **布局持久化**：自动记录您手动调整的调试窗口（变量、堆栈、控制台）尺寸。
- **无感恢复**：下次打开调试界面时，会**立即同步**恢复到上次的布局，没有任何视觉跳变或通知干扰。
- **自定义配置**：
  - **Python**: DebugPy 调试器
  - **JavaScript/TypeScript**: js-debug-adapter
  - **断点持久化**: 使用 persistent-breakpoints.nvim 自动保存断点到项目目录
- **视觉优化**：调试窗口分割线使用青蓝色高亮（`#2b85b7`），提升视觉辨识度。
- **自动启动**：调试会话开始时自动打开 UI，结束时自动关闭。

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

### 💻 终端操作 (Terminal)
| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>tf` | **浮动终端** |
| `<leader>th` | **水平终端** |
| `<leader>tv` | **垂直终端** |
| `<leader>tt` | **标签页终端** |
| `<leader>ts` | **切换终端** |
| `<leader>tc` | **当前目录终端** |
| `<leader>tl` | **Lazy终端** |

### 🐞 调试 (DAP)
| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>dt` | **切换调试界面** (自动恢复布局) |
| `<leader>db` | 切换 **断点** |
| `<leader>dB` | 设置 **条件断点** |
| `<leader>dC` | **清除所有断点** |
| `<leader>dc` | **开始 / 继续** (Continue) |
| `<leader>di` | **步入** (Step Into) |
| `<leader>do` | **步过** (Step Over) |
| `<leader>du` | **步出** (Step Out) |

### 🔨 代码重构 (Refactoring)
> 需先在 **Visual 模式** 下选中代码

| 快捷键 | 描述 |
| :--- | :--- |
| `<leader>cr` | **智能重构菜单** (提取函数/变量、内联等) |
| `<leader>cn` | 带实时预览的 **重命名** (LSP) |
| `<leader>co` | **整理导入** (TypeScript/Vue) |
| `<leader>cu` | **删除未使用的导入** (TypeScript/Vue) |

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

### 🎨 光标移动增强
| 快捷键 | 描述 |
| :--- | :--- |
| `<M-h>` | 跳转到行首 |
| `<M-l>` | 跳转到行尾 |
| `<M-z>` | 跳转到文件末尾并居中 |

## 🔌 主要插件列表

### 核心插件
- **lazy.nvim** - 插件管理器
- **Snacks.nvim** - 现代 UI 组件（Explorer, Picker, Notifier, Terminal, Scratch）
- **toggleterm.nvim** - 终端管理器（支持浮动、水平、垂直、标签页终端）
- **blink.cmp** - 高性能代码补全
- **nvim-lspconfig** - LSP 客户端配置
- **nvim-lint** - 非LSP 代码检查（实时）
- **tiny-inline-diagnostic** - 行内多行诊断显示
- **Conform.nvim** - 代码格式化

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

### UI 增强
- **tokyonight.nvim** - 主题
- **which-key.nvim** - 快捷键菜单（中文）
- **snacks.nvim** - 现代化 UI 组件
- **lualine.nvim** - 状态栏
- **indent-blankline.nvim** - 缩进指示线

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
   - 所有文件必须使用 **Tab 缩进**，宽度设置为 **4 空格**。
   - Lua 代码需符合 `stylua.toml` 规范。

2. **插件配置**：
   - 尽量将特定插件的配置放在 `lua/plugins/` 下的独立文件中。
   - 复杂的业务逻辑（如文件操作、自定义格式化）必须提取到 `lua/util/` 模块中，保持配置文件的整洁。
   - 使用 LazyVim 的 `opts` 机制扩展默认配置，不要完全覆盖。

3. **提交规范**：
   - 提交信息必须使用中文。
   - 格式：`+YYYY-MM-DD HH:MM 内容`。
   - 示例：`+2026-01-26 01:03 完善Lint诊断系统与实时检查`

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
**最后更新**: 2026-01-26
