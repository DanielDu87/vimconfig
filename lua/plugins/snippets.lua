return {
	--==========================================================================
	-- 自定义代码片段 (Snippets)
	--==========================================================================
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
		event = "VeryLazy",
		config = function()
			-- 加载独立的自定义模板配置文件
			require("config.snippets")
		end,
	},
}

