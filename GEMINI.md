# Gemini Instructions for Neovim Configuration

This directory contains a **Neovim configuration** built on top of [LazyVim](https://www.lazyvim.org/). It is customized for frontend (TypeScript, Vue), Python, and Docker development, with a focus on a transparent UI and Chinese localization.

## Project Overview

- **Base Framework:** LazyVim
- **Package Manager:** `lazy.nvim`
- **Key Technologies:** Lua, Neovim API, Tree-sitter, LSP, Mason, Snacks.nvim.
- **Primary Features:**
    - **Transparency:** Global transparency for editor, floating windows, and sidebars (configured in `lua/plugins/theme.lua`).
    - **Localization:** Comprehensive Chinese translations for `which-key` menus, `lazy.nvim` UI, and file explorer actions.
    - **Custom Explorer:** Enhanced file operations (cut/copy/paste with conflict detection and auto-renaming) powered by `Snacks.picker` and custom logic in `lua/util/explorer_actions.lua`.
    - **Formatting:** Enforced Tab indentation (width 4) for all files, controlled by `lua/util/format.lua` and `conform.nvim`.
    - **DAP Layout Persistence:** Intelligent debugging layout management that precisely saves and restores manual adjustments to window sizes, with silent operation and conflict prevention (configured in `lua/plugins/dap.lua`).

## Project Structure

```
~/.config/nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/                 # Core configuration
│   │   ├── autocmds.lua        # Autocommands (triggers formatting)
│   │   ├── keymaps.lua         # General keybindings
│   │   ├── lazy.lua            # Plugin manager setup
│   │   ├── NOTES.lua           # Development notes and scratchpad
│   │   └── options.lua         # Vim options (tabs, UI settings)
│   ├── plugins/                # Plugin specifications
│   │   ├── editor.lua          # WhichKey & Snacks setup (translations here)
│   │   ├── explorer.lua        # File explorer configuration
│   │   ├── formatting.lua      # Conform.nvim setup
│   │   ├── dap.lua             # DAP Debugging & Layout Management
│   │   ├── theme.lua           # UI styling & transparency
│   │   └── ...                 # Other language/tool support
│   └── util/                   # Custom utility modules (Refactored logic)
│       ├── explorer_actions.lua # Logic for file cut/copy/paste/delete
│       └── format.lua          # centralized formatting logic
├── stylua.toml                 # Lua formatting rules (Tabs, 4 spaces)
└── lazy-lock.json              # Plugin lockfile
```

## Key Commands & Workflows

### Management

- **Start:** `nvim`
- **Update Plugins:** `:Lazy sync`
- **Manage Tools (LSP/Formatters):** `:Mason`
- **Check Health:** `:checkhealth`

### Development

- **Format Code:** `<leader>cf` (Calls `lua/util/format.lua`)
- **File Explorer:** `<leader>e` or `<leader>fe`
- **Global Search:** `<leader>sg` or `<leader>/`
- **Command Palette:** `<leader><space>`
- **Debug:**
    - **Toggle UI:** `<leader>dt` (Layout is auto-saved/restored)
    - **Breakpoints:** `<leader>db` (Toggle), `<leader>dB` (Conditional)
    - **Step:** `<leader>dc` (Cont), `<leader>di` (Into), `<leader>do` (Over), `<leader>du` (Out)

## Development Conventions

### Coding Style

- **Indentation:** **Tabs** are strictly used for indentation. Width is set to **4 spaces**.
- **Lua Formatter:** `stylua` configured via `stylua.toml`.
- **Other Files:** `prettier` configured via `.prettierrc` (also uses tabs).

### Configuration Guidelines

1.  **Plugin Configuration:** specific plugin settings should go into `lua/plugins/`. Avoid monolithic files; split by concern (e.g., `theme.lua`, `lsp.lua`).
2.  **Custom Logic:** Complex Lua logic (like file manipulation or custom formatting rules) should be extracted to modules in `lua/util/` rather than inlining them in plugin specs.
3.  **Localization:** When adding new keymaps or menus, ensure Chinese translations are added to `lua/plugins/editor.lua` under `which-key` configuration.
4.  **Formatting:** The project uses a custom formatting pipeline in `lua/util/format.lua` that forces synchronous formatting on save to ensure reliability. Do not rely solely on LazyVim's default auto-formatting.
5.  **DAP Layout:** Layout logic is centralized in `lua/plugins/dap.lua`. It uses `is_restoring` flag to prevent save conflicts during restoration.

### Critical Modules

- **`lua/util/explorer_actions.lua`**: Contains the state machine for cut/copy/paste. Note the use of `M.setup` to inject dependencies (`Actions`, `Snacks`).
- **`lua/plugins/theme.lua`**: Centralized location for all highlight overrides. Do not scatter `vim.api.nvim_set_hl` across multiple files if possible.
- **`lua/plugins/dap.lua`**: Manages debugging sessions and the persistence of UI layouts.

不要主动提交，我告诉你提交的时候再提交,提交时严格使用"+%Y-%m-%d %H:%M 内容"这种格式的提交信息，先通过date "+%Y-%m-%d %H:%M"获取实际时间，然后按照上述提交信息格式进行提交,内容信息要用中文
始终用中文回答，注释也要中文
始终严格遵守Lazyvim官方配置文件格式和规范，符合官方配置文件目录结构
开发优先考虑性能,性能优先
所有编辑的文件，以Tab进行缩进，宽度为4
每次提交前更新README