# HANDOFF

本文件记录最近 10 条关键修改，最新记录置顶，历史记录从新到旧排列。

============================================================

## 2. 【2026-11-20 09:12】- 项目格式化配置对齐全局方案

### 修改内容

- 删除 `prettier.config.js`：原配置自定义 `useTabs`、`tabWidth: 4`、`printWidth: 120`、`bracketSameLine` 并注入 `prettier-plugin-tailwindcss`；该文件在 `package.json` 的 `"type": "module"` 下用 `module.exports` 导出，prettier 3 加载即报错，导致 `scripts/format.sh` 无法运行。
- 删除 `.jsbeautifyrc`：js-beautify 不在全局格式化方案内，仓库中已无调用点。
- `.editorconfig`：移除各语言 `indent_style = tab` / `indent_size = 4` 覆盖，缩进样式交回全局格式化器；保留 `charset`、`end_of_line`、`insert_final_newline`、`trim_trailing_whitespace` 和 Markdown 尾空格保护。
- `stylua.toml` 未动：全局方案未登记 Lua 格式化器，不存在与全局方案的冲突。

### 实现方式

- 依据 `coding-format.md` 第 2.4、3 节对齐边界：同工具的自定义样式清空，清空后为空配置的文件按删除边界处理；删除经用户确认后使用系统废纸篓。
- 两个被删文件均保留在 `~/.Trash/`，且此前内容已存在于 git 历史（提交 `42baf53`），可恢复。

### 验证

- `prettier --find-config-path HANDOFF.md` 不再命中项目配置。
- `bash ~/ai_coding_rules/scripts/format.sh HANDOFF.md` 执行成功（此前报 ESM 配置错误），输出 `prettier --write` 且退出码 0。
- `prettier --check HANDOFF.md` 通过；`git diff --check` 通过。

### 潜在或遗留问题

- 编辑器内 conform 仍向 prettier 传 `--use-tabs --tab-width 4 --print-width 120`（`lua/plugins/formatting.lua`），JS/Vue 排版不变，但 Tailwind 类名自动排序随插件注入失效；如需保留需另行配置，属偏离全局默认样式的取舍。
- `package.json` 的 `prettier-plugin-tailwindcss` 依赖已成为孤儿，是否移除待定。
- `lua/plugins/eslint-auto.lua` 仍会在前端项目自动写入含 Tab/120/Tailwind 插件的 `prettier.config.js`，与新策略不一致，尚未改造。

============================================================

## 1. 【2026-11-20 09:08】- 关闭插件自动更新提示、迁移 treesitter 至 main 分支并整理插件配置

### 修改内容

- `lua/config/lazy.lua`：`checker.enabled` 与 `checker.notify` 均设为 `false`，关闭 lazy.nvim 的定期更新检查与更新弹窗；更新改为手动执行 `:Lazy update` 或 `:Lazy sync`。
- `lua/plugins/treesitter.lua`：删除 `master` 分支 `commit = 310f0925` 的版本钉住、`pin = true`、被覆盖的 `opts` 与 `get_installed` 兼容层，改为跟随 nvim-treesitter `main` 分支，仅保留 `ensure_installed` 列表。
- `lua/plugins/copilot.lua`、`lua/plugins/completion.lua`：Copilot 的 `accept` 键不再由 copilot.lua 绑定，改由 blink.cmp 的 `<Tab>` 映射链第一项处理——可见内联建议时接受并返回 `true` 终止后续命令，否则继续补全菜单、片段跳转与缩进回退。
- 新增 `ftdetect/otty.vim`、`syntax/otty.vim`：为 Otty 终端配置（`~/.config/otty/config.toml`）提供 filetype 识别与关键字/字符串/颜色语法高亮；两文件由外部生成器 `resources/editors/generate.py` 生成，不手工修改。
- `lazy-lock.json`：随插件整体升级更新提交锁定版本。
- `CLAUDE.md`、`GEMINI.md`：由普通文件改为指向 `~/AGENTS.md` 的符号链接，与全局规则单一入口设计一致。
- `.gitignore`：补充 `.DS_Store` 与 `.handoff-backups/`。

### 实现方式

- treesitter 需求源于 Neovim 0.12 起由核心运行时负责高亮与注入，旧 `master` 分支的钉住版本在注入解析时报 `attempt to call method 'range' (a nil value)`，因此必须切到 `main` 分支并去掉版本钉住，避免 `:Lazy update` 再被旧注释误导回滚。
- `<Tab>` 采用单一映射链而非两处绑定，消除 copilot.lua 与 blink.cmp 的按键竞争；自定义函数返回 `true` 可阻止 blink.cmp 继续执行后续命令。
- 更新检查关闭只影响定期检查与通知，不改变安装或手动更新语义。

### 验证

- 无头启动读取实际生效配置：`require('lazy.core.config').options.checker` 输出 `{ check_pinned = false, enabled = false, frequency = 3600, notify = false }`。
- 在临时目录创建 `otty/config.toml` 后用无头 Neovim 打开，`&filetype` 为 `otty`；用 `nvim -u NONE` 加载 `syntax/otty.vim` 成功，`ottyKey` 等语法组已定义且无报错。
- `git diff --check` 通过；treesitter 高亮与 Copilot 补全的交互行为未在真实编辑会话中回归验证。

### 潜在或遗留问题

- nvim-treesitter 必须使用 `main` 分支，Neovim 版本低于 0.12 时不兼容；后续不要回退到 `master` 或重新钉住旧 commit。
- `CLAUDE.md`、`GEMINI.md` 依赖本机 `~/AGENTS.md` 存在，其他机器同步该仓库后需自行准备该文件。

============================================================
