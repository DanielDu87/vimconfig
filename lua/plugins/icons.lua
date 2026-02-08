--==============================================================================
-- mini.icons 图标配置
--==============================================================================
-- 为特定文件名自定义图标（覆盖默认图标）
-- 解决某些 Nerd Font 字体中特定图标字符不显示的问题

return {
	{
		"nvim-mini/mini.icons",
		opts = function()
			return {
				-- 为特定文件名覆盖图标
				file = {
					-- init.lua: 使用 Lua 图标（与 .lua 扩展名一致）
					["init.lua"] = { glyph = "󰢱", hl = "MiniIconsAzure" },
					-- stylua.toml: 使用 JSON 配置图标（更通用）
					["stylua.toml"] = { glyph = "󰘦", hl = "MiniIconsYellow" },
					[".stylua.toml"] = { glyph = "󰘦", hl = "MiniIconsYellow" },
				},
			}
		end,
		config = function(_, opts)
			local MiniIcons = require("mini.icons")
			MiniIcons.setup(opts)

			-- 拦截 get 函数以支持动态文件名图标匹配（包含 docker 或 dk）
			local old_get = MiniIcons.get
			MiniIcons.get = function(category, name)
				if category == "file" and name then
					-- 只提取文件名部分，避免匹配到路径中的目录名
					local filename = vim.fn.fnamemodify(name, ":t"):lower()
					if filename:find("docker") or filename:find("dk") then
						-- 返回默认的 dockerfile 图标定义
						return old_get("filetype", "dockerfile")
					end
				end
				return old_get(category, name)
			end
		end,
	},
}
