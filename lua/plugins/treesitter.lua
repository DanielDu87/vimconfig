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
		-- 覆盖 LazyVim 的配置，使用固定的分支
		branch = "pinned-310f0925", -- 使用固定分支而非 main
		pin = true, -- 禁止自动更新
	},
}
