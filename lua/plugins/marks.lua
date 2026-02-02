--==============================================================================
-- 简单书签配置 (完全参考备份逻辑)
--==============================================================================
return {
	{
		"folke/which-key.nvim",
		optional = true,
		opts = function(_, opts)
			local bookmarks = require("util.marks")
			bookmarks.setup()

			-- 快捷键映射 (完全匹配备份习惯)
			vim.keymap.set("n", "m", bookmarks.toggle, { desc = "🔖 切换书签" })
			vim.keymap.set("n", "]m", bookmarks.nav_next, { desc = "🔖 下一个书签" })
			vim.keymap.set("n", "[m", bookmarks.nav_prev, { desc = "🔖 上一个书签" })
			
			-- 缓冲区和书签 菜单
			vim.keymap.set("n", "<leader>bs", bookmarks.list, { desc = "搜索书签" })
			vim.keymap.set("n", "<leader>bc", bookmarks.clear_buf, { desc = "清空当前文件书签" })
			vim.keymap.set("n", "<leader>bC", bookmarks.clear_all, { desc = "清空所有书签" })
		end,
	},
}
