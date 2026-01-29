return {
	"lewis6991/gitsigns.nvim",
	event = "LazyFile",
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		current_line_blame = true, -- 开启当前行 Blame
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol", -- 显示在行尾
			delay = 300,
			ignore_whitespace = false,
		},
		current_line_blame_formatter = " <author> • <author_time:%Y-%m-%d> • <summary>",
		preview_config = {
			border = "rounded", -- 为预览窗口添加圆角边框
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		on_attach = function(buffer)
			local gs = package.loaded.gitsigns

			local function map(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = buffer, desc = l .. ": " .. desc })
			end

			-- 跳转与操作
			map("n", "]h", gs.next_hunk, "下一个变更")
			map("n", "[h", gs.prev_hunk, "上一个变更")
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "选择变更块")
		end,
	},
	config = function(_, opts)
		require("gitsigns").setup(opts)
		-- 设置 Blame 虚拟文本的颜色 (浅灰色)
		vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = "#5c6370", italic = true })
	end,
}