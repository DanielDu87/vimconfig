--==============================================================================
-- Treesitter 配置（锁定兼容版本）
--==============================================================================
-- 锁定 nvim-treesitter 到兼容 LazyVim 的版本
-- 原因：2023-06-12 的重构版本删除了 configs.lua，导致与 LazyVim 不兼容
--
-- 重要：不要运行 :Lazy update nvim-treesitter，会破坏兼容性
-- 如需更新，请手动测试并更新 pin 版本

return {
	{
		"nvim-treesitter/nvim-treesitter",
		-- 完全覆盖 LazyVim 的配置
		branch = "pinned-310f0925", -- 使用固定分支而非 main
		pin = true, -- 禁止自动更新
		version = false, -- 不使用版本标签
		build = ":TSUpdate", -- 简化的 build 命令
		event = { "LazyFile", "VeryLazy" },
		cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
		opts_extend = { "ensure_installed" },
		opts = {
			indent = { enable = true },
			highlight = { enable = true },
			folds = { enable = true },
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
		-- 提供兼容层，使旧版本符合 LazyVim 的期望
		config = function(_, opts)
			local TS = require("nvim-treesitter")

			-- 为旧版本添加 get_installed 函数（LazyVim 需要）
			if not TS.get_installed then
				TS.get_installed = function()
					local info = require("nvim-treesitter.info")
					return info.installed_parsers()
				end
			end

			TS.setup(opts)
		end,
	},
}
