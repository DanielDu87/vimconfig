# Neovim Configuration (LazyVim Based)

This directory contains a highly customized **Neovim configuration** built on top of [LazyVim](https://www.lazyvim.org/). It is tailored for full-stack development (TypeScript, Vue, Python, Docker) with a focus on performance, visual transparency, and a localized Chinese user experience.

## ✨ Project Overview

- **Base Framework:** LazyVim
- **Package Manager:** `lazy.nvim`
- **Key Technologies:** Lua, Neovim API, Tree-sitter, LSP, Mason, Snacks.nvim.
- **Core Philosophy:** Performance-first, fully localized (Chinese), and visually transparent.

### 🚀 Key Features

*   **Unified Runner Center:** Custom background execution engine for HTML, JS, and Python. Supports real-time tail logging with specialized `runnerlog` syntax highlighting, smart auto-scrolling, and per-project/file runner configurations.
*   **Simple Bookmark System:** Custom persistent bookmark system. Supports sign column icons (`🔖`), persistence to `~/bookmarks.json`, and searchable lists via `Snacks.picker`.
*   **Transparency:** Global transparency for editor, floating windows, and sidebars (managed via `lua/plugins/theme.lua` and `lua/util/theme.lua`). Theme selection is persisted across restarts.
*   **Localization:** Comprehensive Chinese translations for `which-key` menus, `lazy.nvim` UI, and file explorer actions.
*   **Intelligent Explorer:** Enhanced file operations (Cut/Copy/Paste/Delete) with automatic conflict detection, renaming, and directory support. Powered by `Snacks.picker` and custom logic (`lua/util/explorer_actions.lua`).
*   **Strict Formatting:** Enforced **Tab indentation (width 4)** for all files, controlled by a custom synchronous pipeline in `lua/util/format.lua`.
*   **Advanced Debugging:** Automatically saves and precisely restores manual window adjustments for the DAP UI. Persistent breakpoints across sessions.

## 📂 Project Structure

```text
~/.config/nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/                 # Core configuration
│   │   ├── autocmds.lua        # Autocommands (formatting, Runner highlights, Tailwind auto-init)
│   │   ├── keymaps.lua         # General keybindings (Runner, Marks, History)
│   │   ├── options.lua         # Vim options (tabs, UI settings)
│   ├── plugins/                # Plugin specifications
│   │   ├── runner.lua          # Unified Runner Center
│   │   ├── marks.lua           # Bookmark system integration
│   │   ├── explorer.lua        # Snacks Explorer configuration
│   │   ├── formatting.lua      # Conform.nvim setup
│   │   ├── dap.lua             # Debug Adapter Protocol & Layout Management
│   │   ├── theme.lua           # UI styling & Transparency
│   │   └── ...                 # Language support (Python, JS/TS, etc.)
│   └── util/                   # Custom Utility Modules
│       ├── runner_config.lua   # Runner persistence logic
│       ├── marks.lua           # Bookmark core logic
│       ├── explorer_actions.lua # Core logic for file manipulation
│       └── format.lua          # Centralized formatting controller
├── stylua.toml                 # Lua formatting rules (Tabs, 4 spaces)
└── lazy-lock.json              # Plugin lockfile
```

## ⌨️ Comprehensive Keymap Reference

### 📂 File & Explorer (`<leader>f`, `<leader>e`)
- **Find Files:** `<leader><space>` (Root) | `<leader>ff` (Root) | `<leader>fF` (Cwd)
- **Explorer:** `<leader>e` (Toggle) | `<leader>fe` (Root) | `<leader>fE` (Cwd)
- **Git Files:** `<leader>fg` | **Recent:** `<leader>fr` / `<leader>fR`
- **Config:** `<leader>fc` | **Buffers:** `<leader>fb` / `<leader>fB`
- **In-Explorer:** `x` (Cut), `y` (Copy), `p` (Paste), `d` (Delete), `r` (Rename), `a` (New), `<M-q>` (Toggle)

### 🗂️ Buffers & Marks (`<leader>b`)
- **Navigate:** `<leader>bb` (Other), `<leader>bh` (Prev), `<leader>bl` (Next)
- **Close:** `<leader>bd` (Current), `<leader>bo` (Others), `<leader>bP` (Non-Pinned)
- **Pin:** `<leader>bp`
- **Marks:** `m` (Toggle), `]m` / `[m` (Next/Prev), `'` / `<leader>bs` (Search)

### 🚀 Run & Debug (`<leader>r`, `<leader>d`)
- **Run:** `<leader>rr` (File), `<leader>rp` (Project), `<leader>rl` (Log), `<leader>rs` (Stop)
- **Config:** `<leader>rc` (File Cmd), `<leader>rC` (Project Cmd), `<leader>rb`/`rB` (Browser URL)
- **Browser:** `<leader>ro` (Open) | **Env:** `<leader>rv` (Py Venv), `<leader>rV` (TS Ver)
- **Debug UI:** `<leader>dt` (Toggle) | **Control:** `<leader>dc/di/do/du` (Continue/Into/Over/Out)
- **Breakpoints:** `<leader>db` (Toggle), `<leader>dB` (Conditional), `<leader>dX` (Clear)

### 🛠️ Code & LSP (`<leader>c`)
- **LSP:** `<leader>cl` (Info), `<leader>cm` (Mason), `<leader>cd` (Line Diag), `<leader>cn` (Jump Line)
- **Actions:** `<leader>ca` (Code), `<leader>cA` (Source), `<leader>cr` (Rename), `<leader>cf` (Format)
- **TS/Vue:** `<leader>co` (Organize Imports), `<leader>cu` (Remove Unused), `<leader>ci` (Add Missing)
- **Refactor:** `<leader>r` (Visual Mode - Smart Extract)

### 🧡 Git Integration (`<leader>g`)
- **Panels:** `<leader>gc` (Fugitive), `<leader>gl` (Log), `<leader>gg` (Graph)
- **Status:** `<leader>gs` (Picker) | **Blame:** `<leader>gb` (Line/Select)
- **Diff:** `<leader>gd` (Local), `<leader>gD` (Remote) | **Sync:** `<leader>gp` (Push), `<leader>gP` (Pull)
- **Stash:** `<leader>gS` | **Branch:** `<leader>gC`

### 📜 History (`<leader>h`)
- **Notifications:** `<leader>hn` (List), `<leader>hl` (Last), `<leader>ha` (All), `<leader>hx` (Clear)
- **Commands/Search:** `<leader>hc`, `<leader>hs`

### 🔍 Search (`<leader>s`, `s`, `/`)
- **Global:** `<leader>sg` (Grep), `<leader>sw`/`sW` (Word)
- **Replace:** `<leader>sr` | **Symbols:** `<leader>ss` (Doc), `<leader>sS` (Workspace)
- **Flash:** `s` | **Current File:** `/` or `?`

### 🎨 UI & Windows (`<leader>u`, `<leader>w`)
- **Toggles:** `<leader>ut` (Transparent), `<leader>ua` (Anim), `<leader>uT` (Tabline), `<leader>uz` (Zen)
- **Windows:** `<leader>w-` (Split Below), `<leader>w|` (Split Right), `<leader>wd` (Close), `<leader>wm` (Max)

### 💻 Terminal & Tabs (`<leader>t`, `<leader><tab>`)
- **Term:** `<leader>tf` (Float), `<leader>th` (Horizontal), `<leader>tv` (Vertical)
- **Tabs:** `<leader><tab>n/p` (Next/Prev), `<leader><tab>d` (Close)

### ⌨️ General
- **DevDocs:** `<leader>k` (Word), `<leader>K` (Input)
- **Edit:** `ciq` ("), `cie` ('), `cib` (()), `<M-v>` (Block Select)
- **Move:** `<A-j>`/`<A-k>` (Move Line), `<M-h>`/`<M-l>` (Start/End Line)

---
*Generated by Gemini Agent | Updated: 2026-02-07*