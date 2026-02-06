local M = {}

--==============================================================================
-- 助手函数：获取动态信息
--==============================================================================
local function get_vars(filename)
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	local user = vim.env.USER or "Developer"
	local date = os.date("%Y/%m/%d")
	local time = os.date("%H:%M")
	
	return {
		DATE = date,
		TIME = time,
		USER = user,
		PROJECT = project_name,
		FILENAME = filename,
	}
end

-- 预处理模板：将 ${USER} 等变量转为纯文本
local function pre_process_template(content, vars)
	for k, v in pairs(vars) do
		-- 修复：使用 % 来转义 $ 符号
		content = content:gsub("%%${" .. k .. "}", v)
	end
	return content
end

--==============================================================================
-- 专业模板定义 (添加 JavaScript 模板)
--==============================================================================
M.templates = {
	{
		name = "Python: 基础标准模板",
		filename = "main.py",
		text = "python python3 main.py", -- 用于搜索匹配
		content = [[
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# @File    : ${FILENAME}
# @Time    : ${DATE} ${TIME}
# @Author  : ${USER}
# @.claude/PROJECT_CONTEXT.md : ${PROJECT}


${0}

if __name__ == "__main__":
	pass
]],
	},
	{
		name = "JavaScript: 标准基础模板",
		filename = "index.js",
		text = "javascript js node index.js",
		content = [[
/**
 * @File    : ${FILENAME}
 * @Time    : ${DATE} ${TIME}
 * @Author  : ${USER}
 * @.claude/PROJECT_CONTEXT.md : ${PROJECT}
 */

'use strict';

${0}
]],
	},
	{
		name = "Python: FastAPI 基础结构",
		filename = "app.py",
		text = "python fastapi app.py web",
		content = [[
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# @File    : ${FILENAME}
# @Time    : ${DATE} ${TIME}
# @Author  : ${USER}
# @.claude/PROJECT_CONTEXT.md : ${PROJECT}

from fastapi import FastAPI
import uvicorn

app = FastAPI(title="API项目")


${0}

if __name__ == "__main__":
	uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
]],
	},
}

--==============================================================================
-- 生成逻辑
--==============================================================================
function M.generate_file()
	local ok_snacks, Snacks = pcall(require, "snacks")
	local ok_ls, ls = pcall(require, "luasnip")
	
	if not ok_snacks then
		return vim.notify("未找到 snacks.nvim", vim.log.levels.ERROR)
	end

	-- 修复 "Item has no file" 报错：显式关闭预览并指定为简单选择列表
	Snacks.picker.pick({
		title = " 选择文件模板 ",
		items = M.templates,
		preview = false, -- 禁用预览，解决 "Item has no file" 报错
		layout = "select", -- 使用简单的下拉布局
		format = function(item)
			return {
				{ item.name, "String" },
				{ " [" .. item.filename .. "]", "Comment" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if not item then return end

			vim.ui.input({
				prompt = "确认文件名: ",
				default = item.filename,
			}, function(input)
				if not input or input == "" then return end

				if vim.fn.filereadable(input) == 1 then
					vim.notify("文件已存在: " .. input, vim.log.levels.WARN)
					return
				end

				-- 1. 获取变量并执行预处理
				local vars = get_vars(input)
				local final_content = pre_process_template(item.content, vars)

				-- 2. 创建文件并打开
				local f = io.open(input, "w")
				if f then
					f:close()
					vim.cmd("edit " .. vim.fn.fnameescape(input))
					
					-- 3. 使用 Snippet 展开
					if ok_ls then
						vim.cmd("startinsert")
						vim.schedule(function()
							ls.lsp_expand(final_content)
						end)
					else
						local f_write = io.open(input, "w")
						f_write:write(final_content:gsub("${0}", ""))
						f_write:close()
						vim.cmd("edit!")
					end
					
					vim.notify("文件已生成", vim.log.levels.INFO)
				else
					vim.notify("无法创建文件", vim.log.levels.ERROR)
				end
			end)
		end,
	})
end

return M