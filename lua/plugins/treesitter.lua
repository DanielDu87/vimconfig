--==============================================================================
-- Treesitter 配置
--==============================================================================
-- Neovim 0.12 起 treesitter 高亮/注入由核心运行时提供，nvim-treesitter 必须使用
-- main 分支。旧的 master 分支（曾 pin 在 310f0925）与 0.12 不兼容，会在注入
-- 解析时报 "attempt to call method 'range' (a nil value)"。
-- 其余配置（高亮/缩进/折叠/自动安装）沿用 LazyVim 默认 spec，这里只补充
-- ensure_installed。

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"javascript",
				"jsdoc",
				"json",
				"jsonc",
				"lua",
				"luadoc",
				"luap",
				"markdown",
				"markdown_inline",
				"printf",
				"python",
				"query",
				"regex",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			},
		},
	},
}
