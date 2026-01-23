--==============================================================================
-- OneDarkPro：真正的独立的 Atom One Dark 还原版
--==============================================================================

return {
	{
		"olimorris/onedarkpro.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			options = {
				transparency = true, -- 开启透明
				cursorline = true,
			},
			styles = {
				types = "NONE",
				methods = "bold",
				numbers = "NONE",
				strings = "NONE",
				comments = "italic",
				keywords = "italic",
				variables = "NONE",
				functions = "bold",
				operators = "NONE",
				parameters = "NONE",
				conditionals = "italic",
				virtual_text = "NONE",
			},
		},
	},
}
