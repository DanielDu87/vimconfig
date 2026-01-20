return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = { "LspAttach", "BufReadPre", "BufNewFile" },
		config = function()
			require("tiny-inline-diagnostic").setup({
				preset = "ghost",
				options = {
					show_source = false,
					throttle = 80, -- 降低更新频率，减少 redraw 压力
					softwrap = 60,
					multilines = true,
					overflow = {
						mode = "wrap",
					},
				},
			})
		end,
	},
}

