# Neovim Configuration (LazyVim Based)

This directory contains a highly customized **Neovim configuration** built on top of [LazyVim](https://www.lazyvim.org/). It is tailored for full-stack development (TypeScript, Vue, Python, Docker) with a focus on performance, visual transparency, and a localized Chinese user experience.

## ✨ Project Overview

- **Base Framework:** LazyVim
- **Package Manager:** `lazy.nvim`
- **Key Technologies:** Lua, Neovim API, Tree-sitter, LSP, Mason, Snacks.nvim.
- **Core Philosophy:** Performance-first, fully localized (Chinese), and visually transparent.

### 🚀 Key Features

*   **Transparency:** Global transparency for editor, floating windows, and sidebars (managed via `lua/plugins/theme.lua`).
*   **Localization:** Comprehensive Chinese translations for `which-key` menus, `lazy.nvim` UI, and file explorer actions.
*   **Intelligent Explorer:** Enhanced file operations (Cut/Copy/Paste/Delete) with automatic conflict detection, renaming, and directory support. Powered by `Snacks.picker` and custom logic (`lua/util/explorer_actions.lua`).
*   **Strict Formatting:** Enforced **Tab indentation (width 4)** for all files, controlled by a custom synchronous pipeline in `lua/util/format.lua`.
*   **Advanced Debugging:**
    *   **Layout Persistence:** Automatically saves and precisely restores manual window adjustments for the DAP UI.
    *   **Silent Restoration:** Restores layouts instantly without visual shifts or notification noise.
    *   **Shortcuts:** Integrated keys for Breakpoints, Stepping, and Panel toggling.

## 📂 Project Structure

```text
~/.config/nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/                 # Core configuration
│   │   ├── autocmds.lua        # Autocommands (triggers formatting, resize events)
│   │   ├── keymaps.lua         # General keybindings
│   │   ├── lazy.lua            # Plugin manager setup
│   │   ├── NOTES.lua           # Scratchpad
│   │   └── options.lua         # Vim options (tabs, UI settings)
│   ├── plugins/                # Plugin specifications
│   │   ├── editor.lua          # WhichKey & Snacks setup (Translations)
│   │   ├── explorer.lua        # File Explorer configuration
│   │   ├── formatting.lua      # Conform.nvim setup
│   │   ├── dap.lua             # Debug Adapter Protocol & Layout Management
│   │   ├── theme.lua           # UI styling & Transparency
│   │   └── ...                 # Language support (Python, JS/TS, etc.)
│   └── util/                   # Custom Utility Modules
│       ├── explorer_actions.lua # Core logic for file manipulation
│       └── format.lua          # Centralized formatting controller
├── stylua.toml                 # Lua formatting rules (Tabs, 4 spaces)
└── lazy-lock.json              # Plugin lockfile
```

## ⌨️ Key Commands & Workflows

### 🛠️ Management
- **Start:** `nvim`
- **Update Plugins:** `:Lazy sync`
- **Manage Tools (LSP/Formatters):** `:Mason`
- **Check Health:** `:checkhealth`

### 💻 Development
- **Format Code:** `<leader>cf` (Sync formatting via `lua/util/format.lua`)
- **File Explorer:** `<leader>e` or `<leader>fe`
- **Global Search:** `<leader>sg` or `<leader>/`
- **Command Palette:** `<leader><space>`

### 🐞 Debugging (DAP)
- **Toggle UI:** `<leader>dt` (Auto-saves & restores layout)
- **Start/Continue:** `<leader>dc`
- **Step Into/Over/Out:** `<leader>di` / `<leader>do` / `<leader>du`
- **Breakpoints:**
    - Toggle: `<leader>db`
    - Conditional: `<leader>dB`
    - Clear All: `<leader>dC`

## 📏 Development Conventions

### Coding Style
- **Indentation:** **Hard Tabs** (Width: 4 spaces).
- **Lua Style:** Governed by `stylua.toml`.
- **Prettier:** Governed by `.prettierrc` (uses tabs).

### Configuration Guidelines
1.  **Plugin Isolation:** Keep settings specific to a plugin within `lua/plugins/`. Avoid monolithic files.
2.  **Logic Separation:** Complex logic (e.g., file manipulation, layout calculation) **MUST** reside in `lua/util/`.
3.  **Localization:** All new keymaps and menus must have Chinese descriptions in `lua/plugins/editor.lua`.
4.  **DAP Layout:** Layout logic is centralized in `lua/plugins/dap.lua`. It uses a `apply_saved_sizes` strategy for instant, jump-free restoration.
5.  **Performance:** Prioritize startup time and runtime responsiveness. Avoid heavy operations in the main thread unless necessary.

### Critical Modules
- **`lua/util/explorer_actions.lua`**: Implements the state machine for Cut/Copy/Paste. Uses `v` (character-wise) register mode for path copying to prevent trailing newlines.
- **`lua/plugins/dap.lua`**: Manages debug sessions and persistence. It features a custom debounce mechanism and synchronous layout application to ensure a smooth UX.