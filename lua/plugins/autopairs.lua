--==============================================================================
-- 自动配对配置 (nvim-autopairs)
--==============================================================================

return {
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = function(_, opts)
			-- 基本配置
			opts.check_ts = true -- 启用 treesitter 检查
			opts.ts_config = {
				lua = { "string" }, -- 不在 lua 字符串中自动配对
				javascript = { "template_string" },
				java = false, -- 禁用 java 的 ts 检查以提高性能
			}

			-- 快速跳过配置
			opts.fast_wrap = {
				map = "<M-e>", -- 使用 Option+e 快速包裹
				chars = { "{", "[", "(", '"', "'" },
				pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
				offset = 0, -- 字符偏移量
				end_key = "$",
				keys = "qwertyuiopzxcvbnmasdfghjkl",
				check_comma = true,
				highlight = "Search",
				highlight_grey = "Comment",
			}

			-- 禁用某些文件类型的自动配对
			opts.disable_filetype = { "TelescopePrompt", "spectre_panel" }

			-- 配对的字符映射
			opts.map_bs = true -- 退格键删除配对
			opts.map_c_h = false -- 禁用 Ctrl-H
			opts.map_c_w = false -- 禁用 Ctrl-W

			return opts
		end,
		config = function(_, opts)
			local autopairs = require("nvim-autopairs")
			local Rule = require("nvim-autopairs.rule")

			-- 辅助函数：检查是否在引号内
			local function inside_quote()
				local line = vim.api.nvim_get_current_line()
				local col = vim.api.nvim_win_get_cursor(0)[2]
				local line_before = line:sub(1, col)
				local single_quote = 0
				local double_quote = 0

				for i = 1, #line_before do
					local char = line_before:sub(i, i)
					if char == "'" and line_before:sub(i - 1, i - 1) ~= "\\" then
						single_quote = single_quote + 1
					end
					if char == '"' and line_before:sub(i - 1, i - 1) ~= "\\" then
						double_quote = double_quote + 1
					end
				end

				return single_quote % 2 == 1 or double_quote % 2 == 1
			end

			-- 加载配置
			autopairs.setup(opts)

			-- 添加自定义规则 - 括号在引号内不自动配对
			autopairs.add_rule(Rule("(", ")")
				:with_pair(function()
					return not inside_quote()
				end))

			-- 单引号配对规则 - 在 Lua 注释中不配对
			autopairs.add_rule(Rule("'", "'")
				:with_pair(function()
					local line = vim.api.nvim_get_current_line()
					local col = vim.api.nvim_win_get_cursor(0)[2]
					-- 检查是否在注释中
					return not (line:sub(1, col):match("%-%-"))
				end))

			-- 双引号配对规则 - 在 Lua 注释中不配对
			autopairs.add_rule(Rule('"', '"')
				:with_pair(function()
					local line = vim.api.nvim_get_current_line()
					local col = vim.api.nvim_win_get_cursor(0)[2]
					-- 检查是否在注释中
					return not (line:sub(1, col):match("%-%-"))
				end))
		end,
	},
}
