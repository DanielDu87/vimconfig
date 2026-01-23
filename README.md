# Neovim 旗舰开发环境 (Based on LazyVim)

这是一套深度定制的 Neovim 开发环境，基于 **LazyVim** 框架构建。核心设计理念是：**极致的透明视觉体验、全中文的交互界面、以及高度自动化的开发工作流**。

针对 **前端 (Vue/React/TS)**、**Python (FastAPI/Django)** 和 **DevOps (Docker/Shell)** 进行了深度调优。

---

## 🌟 核心特性 (Core Features)

### 🎨 极致 UI 与视觉体验
- **全局透明化**：
  - 编辑器背景、侧边栏、浮动窗口、补全菜单 (Pumblend) 全面透明 (透明度 20)。
  - 深度定制 `Tokyo Night` 主题，适配透明背景下的高亮逻辑。
- **界面汉化**：
  - `Which-Key` 菜单 100% 中文化，宽度扩展至 `0.65`，重新分组设计。
  - `Snacks` 组件（Explorer、Picker）交互提示汉化。
- **文档渲染**：
  - Markdown 标题采用 **背景色块** 区分层级（H1-H6 渐变色）。
  - 表格采用 **重线条网格** 渲染，代码块带背景保护。
  - 专注模式：Markdown 文件自动关闭 LSP 诊断和内显提示，提供纯净阅读体验。

### 🚀 增强型文件资源管理器 (Snacks Explorer)
基于 `Snacks.explorer` 深度二次开发，打造类似 IDE 的文件操作体验：
- **核心操作逻辑** (`lua/util/explorer_actions.lua`)：
  - **剪切/复制/粘贴**：支持 **多选操作**。粘贴到原处自动创建副本 (如 `file~1.txt`)，粘贴到新目录自动移动/复制。
  - **快捷键**：`x` (剪切), `c` (复制/副本), `p` (粘贴), `d` (删除)。
- **智能设计哲学**：
  - **宽度持久化**：自动记录并恢复上次调整的目录树宽度，宽度锁定，防止其他窗口变动导致抖动。
  - **视觉对齐**：诊断图标（错误/警告）精准显示在 Git 状态图标左侧，快速定位问题。
  - **防误触保护**：`q` 键智能映射为 **关闭 Buffer 但保留窗口布局**，彻底解决关闭文件后目录树占满屏幕的问题。

### 🛠️ 严苛的代码规范与自动化 (Formatting & Linting)
采用 `Conform.nvim` 与自定义工具链 (`lua/util/format.lua`) 实现高度自动化的格式化逻辑：
- **全局标准**：严格强制使用 **Tab** (宽度 4)，保存时触发同步格式化，确保写入即完美。
- **差异化处理**：
  - **HTML 智控**：自动清理冗余空行。仅在 `<body>` 为空时自动撑开 3 行空行并缩进，极大提升编码效率。
  - **Dockerfile 指令优化**：通过 Perl 脚本强制将指令（RUN, COPY 等）转为 **大写**，并压缩多余空格。
  - **Python 专业流**：`isort` 自动整理导入顺序，`black` (Brew 版) 极致格式化。
  - **CSS 逻辑排序**：自动按照属性逻辑顺序重排样式。

### 🏃 统一运行中心 (Unified Runner)
基于 `lua/plugins/runner.lua` 构建的轻量级任务运行引擎：
- **多模式支持**：
  - **HTML 实时预览**：自动启动 `browser-sync` 服务，实现代码改动后浏览器全自动刷新。
  - **Python 脚本运行**：一键执行当前脚本。
  - **项目级运行**：通过 `<leader>rp` 运行整个项目。
- **持久化自定义配置**：
  - **命令自定义**：支持为特定文件 (`<leader>rc`) 或整个项目 (`<leader>rC`) 设置专属运行命令。
  - **浏览器联动**：支持为文件 (`<leader>rb`) 或项目 (`<leader>rB`) 配置浏览器打开 URL。
  - **自动触发**：项目运行成功后可自动打开预设的浏览器页面。
- **直播级日志体验** (`<leader>rl`)：
  - **异步输出**：任务后台运行，不会阻塞编辑器。
  - **智能滚动**：支持 `auto` (接近底部跟随) 和 `on_complete` (运行完置底) 模式。
  - **精细化语法高亮**：对日志内容进行深度解析和着色，提升可读性。
  - **多级别高亮**：为 `ERROR`, `WARN`, `SUCCESS`, `INFO`, `DEBUG` 等不同日志级别提供专属颜色（红、黄、绿、蓝、灰）。
  - **实体识别**：精确高亮 URL、文件路径、`runserver` 命令、非零退出状态码等关键信息。
  - **常规输出纯白化**：确保普通日志文本为纯白色，避免视觉干扰。
- **进程管控**：`<leader>rs` 一键杀死相关联的后台进程及占用的端口。

---

## ⚡️ 技术栈与工具链 (Tech Stack)

| 领域 | 语言/文件 | LSP (智能提示) | Formatter (格式化) | Linter (代码质量) | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Core** | Lua | `lua_ls` | `stylua` | - | 缩进: Tab (4) |
| **Frontend** | TS / JS / JSX | `ts_ls` | `prettier` + `eslint_d` | `eslint` | 禁用 `vtsls`，Inlay Hints 全开 |
| **Frontend** | Vue | `volar` | `prettier` + `eslint_d` | `eslint` | - |
| **Frontend** | HTML | `html-lsp` | `markuplint` + `prettier` | `markuplint` | 强力纠错，闭合标签检测 |
| **Styles** | CSS / SCSS | `cssls` | `stylelint` + `prettier` | `stylelint` | 自动属性重排 |
| **Backend** | Python | `pyright` | `black` + `isort` | `ruff` | 自动识别 `/0.python-venv` |
| **Ops** | Dockerfile | `dockerls` | `perl` (Custom) | `hadolint` | 指令强制大写 |
| **Ops** | Shell | `bashls` | `shfmt` | - | - |
| **Data** | SQL | - | `prettier` (Plugin) | - | 关键字大写 |

---

## ⌨️ 关键快捷键 (Keymaps)

### 📂 文件与运行 (Files & Runner)
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `<leader>e` | **切换资源管理器** | 唤起/聚焦目录树 |
| `<leader>rr` | **运行当前文件** | HTML 实时预览 / Python 运行 |
| `<leader>rp` | **运行项目** | 执行预设的项目启动命令 |
| `<leader>ro` | **打开浏览器** | 快速打开当前文件/项目关联的 URL |
| `<leader>rl` | **查看运行日志** | 开启日志直播窗口 |
| `<leader>rs` | **停止任务** | 杀死后台进程并释放端口 |
| `<leader>rc / rC` | **配置运行命令** | 设置文件/项目级的运行指令 |
| `<leader>rb / rB` | **配置浏览器 URL** | 设置文件/项目级的浏览器跳转地址 |
| `<leader>rv` | **选择虚拟环境** | 切换 Python 解释器 (venv/conda) |
| `<leader>rV` | **选择 TS 版本** | 切换 TypeScript 工作区版本 |
| `<leader>bh/l` | **Buffer 切换** | 替代 `Tab` / `Shift-Tab` |
| `<leader>bP` | **一键清理** | 关闭所有非固定 (Non-Pinned) 文件 |
| `q` | **安全关闭** | 关闭 Buffer 但不破坏 Explorer 布局 |

### 🛠️ 开发辅助 (Coding)
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `<leader>cf` | **手动格式化** | 同步执行全套格式化流程 |
| `<leader>cr` | **符号重命名** | 跨文件重构 |
| `<leader>ca` | **代码操作** | 快速修复、提取函数等 |
| `<leader>cv` | **切换 Python 环境** | 扫描虚拟环境仓库 |
| `<leader>k` | **查阅文档** | DevDocs 在线查询 |
| `gl` | **行诊断详情** | 切换悬浮显示当前行错误 |

---

## 📂 项目结构 (Structure)

```text
~/.config/nvim/
├── init.lua                 # 入口：引导 lazy.nvim
├── lua/
│   ├── config/              # 核心配置 (options, keymaps, autocmds)
│   ├── plugins/             # 插件 spec
│   │   ├── explorer.lua     # 目录树设计与 q 键映射
│   │   ├── formatting.lua   # Conform 规则与自定义格式化器
│   │   ├── runner.lua       # 运行中心逻辑与日志高亮
│   │   └── theme.lua        # 透明背景与高亮覆盖
│   └── util/                # 自定义逻辑
│       ├── explorer_actions.lua # 文件剪切/复制/粘贴/删除核心
│       └── format.lua           # 统一格式化入口 (含 HTML 智控)
```

## 📅 维护指南

1.  **提交规范**：
    使用 Git 提交时，请遵循以下格式：
    `git commit -m "$(date '+%Y-%m-%d %H:%M') 你的提交内容"`
2.  **更新策略**：
    运行 `:Lazy sync` 同步插件，修改 `lua/` 配置文件后重启生效。
