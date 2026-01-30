--==============================================================================
-- Flash 快速跳转配置
--==============================================================================
-- 类似 easymotion 的快速跳转功能

return {
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {
		modes = {
			-- 字符跳转模式（支持连续输入多个字符）
			char = {
				enabled = true,
				-- 支持多行搜索
				multi_line = true,
				-- 动态标签
				jump_labels = true,
			},
		},
	},
	-- 键映射
	keys = {
		{
			"s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Flash 单字符跳转",
		},
	},
}
