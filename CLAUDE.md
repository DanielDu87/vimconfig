# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **LazyVim-based** Neovim configuration with extensive customizations. LazyVim serves as the base framework, providing pre-configured defaults for LSP, formatting, keybindings, and more. Custom configurations extend LazyVim through the `lua/plugins/` directory.

## Common Commands

### Plugin Management

```bash
# Sync and update all plugins
nvim  # then run :Lazy sync

# Clean unused plugins
nvim  # then run :Lazy clean

# View plugin status
nvim  # then run :Lazy
```

### Managing LazyVim Extras

```bash
# Enable all commented extras (automation script)
nvim -l ~/.config/nvim/enable_extras.lua

# Manual method: Edit lua/plugins/extras.lua, uncomment desired extras
```

### Health Checks

```bash
# Check LazyVim health
nvim --health lazy

# Check Mason (LSP server manager)
nvim  # then run :Mason
```

## Architecture

### Entry Point and Loading Order

1. **init.lua** - Minimal entry point that only requires `config.lazy`
2. **lua/config/lazy.lua** - Sets up lazy.nvim plugin manager and imports LazyVim
3. **lua/config/options.lua** - Base Neovim options (loaded before plugins)
4. **lua/config/keymaps.lua** - Custom key mappings (loaded on VeryLazy event)
5. **lua/config/autocmds.lua** - Auto commands (loaded on VeryLazy event)
6. **lua/plugins/\*** - All plugin configurations auto-loaded by lazy.nvim

### LazyVim Extras Management

All LazyVim extras are centralized in `lua/plugins/extras.lua`. This is the single source of truth for enabled language and tooling support:

- **Frontend**: TypeScript, Vue, Tailwind
- **Python**: Pyright, Black, Ruff, Debugpy
- **Docker**: Dockerfile support, hadolint
- **Formatting/Linting**: Prettier, ESLint
- **Optional**: AI (Codeium/Copilot), other languages (commented out)

To add support for a new language or framework, add its extra to `lua/plugins/extras.lua`, not as a separate plugin configuration.

### Plugin Configuration Pattern

Each file in `lua/plugins/` returns a table of plugin specs:

```lua
return {
    {
        "author/plugin-name",
        opts = { },  -- or function(_, opts) ... return opts end
        event = "VeryLazy",
        dependencies = { "other/plugin" },
        -- Other lazy.nvim options...
    },
}
```

Key patterns:

- Use `opts` function to merge with existing LazyVim defaults
- For complex plugins, use `keys`, `cmd`, `ft` for lazy loading
- Custom actions override default LazyVim behaviors by extending the module

### File Explorer (Snacks.nvim)

The file explorer is heavily customized in `lua/plugins/explorer.lua`:

- Chinese localization for all file operations
- Smart file operations (copy/move/delete) with auto-renaming on conflicts
- Auto-opens on startup (unless opening a directory)
- Custom key `q` mapped to buffer deletion (preserves window layout)
- Custom diagnostic icon positioning

### Which-Key Configuration

Which-key is centralized in `lua/plugins/editor.lua`:

- Custom window styling with centered title and rounded border
- Chinese labels for all menu groups
- Custom icons for each group
- Keybinding reorganization (windows under `<leader>w`, buffers under `<leader>b`, scratch under `<leader>S`)
- Comprehensive `replace` table for translating English descriptions to Chinese

### Snacks.nvim Integration

Snacks.nvim is heavily used throughout the configuration:

- Explorer (file browser) - configured in `lua/plugins/explorer.lua`
- Scratch buffers - managed via `<leader>S` prefix
- Picker (Telescope replacement) - used for file search, buffers, commands, etc.
- Global picker config in `lua/plugins/editor.lua`:
  - Empty prompt string
  - Centered input box (30% width, at row 0.3)
  - Disabled status/sign columns for cleaner UI
  - Custom keybindings (Esc to clear selection, not close)

### Keybinding Patterns

Custom keybindings are defined in:

- `lua/config/keymaps.lua` - Global custom mappings
- `lua/plugins/explorer.lua` - Explorer-specific mappings including:
  - `<M-=>` / `<M-->` - Next/previous buffer
  - `<M-h>` / `<M-l>` - Line start/end motion
  - `<M-z>` - Jump to file end and center
  - `<M-q>` - Toggle explorer

The `q` key is remapped to close buffers (not windows) to preserve the explorer layout.

### Theme and Transparency

Theme configuration in `lua/plugins/theme.lua`:

- Default: Tokyo Night with transparency enabled
- Theme selection persists across sessions (saved to `~/.local/state/nvim/colorscheme`)
- Transparency highlights are set in `lua/config/options.lua` and re-applied on ColorScheme
- Custom CursorLine color: `#3d4458`
- All backgrounds set to `none` for transparency

### Syntax Highlighting

Configured in `lua/plugins/highlight.lua`:

- Treesitter parsers for: html, css, javascript, typescript, tsx, json, yaml, python, lua, bash, markdown, dockerfile
- Auto-closing tags for HTML/JSX/Vue
- Rainbow delimiters
- Color code highlighting with Tailwind support
- Indent blanklines with scope indicators

## Important Constraints

1. **Do not modify LazyVim core** - All customizations should go through `lua/plugins/`
2. **Keep extras centralized** - Don't create separate plugin configs for things LazyVim extras provide
3. **Preserve Chinese localization** - The explorer and which-key have Chinese UI elements; maintain this when modifying
4. **Theme** - Tokyo Night with transparency; highlight clearing happens on ColorScheme
5. **Code style** - Use tab indentation for Lua files
6. **Performance first** - All configuration prioritizes performance

始终使用中文回答
始终严格遵守Lazyvim官方配置文件格式和规范，符合官方配置文件目录结构
开发优先考虑性能,性能优先
帮我提交时严格使用"+%Y-%m-%d %H:%M 内容"这种格式的提交信息，通过date "+%Y-%m-%d %H:%M"获取最新时间
