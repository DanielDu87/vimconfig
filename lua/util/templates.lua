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
		FILENAME = filename or "new_file",
	}
end

-- 预处理模板：将 ${USER} 等变量转为纯文本
local function pre_process_template(content, vars)
	local result = content
	for k, v in pairs(vars) do
		result = result:gsub("%%${" .. k .. "}", v)
	end
	return result
end

--==============================================================================
-- 专业模板定义
--==============================================================================
M.templates = {
	{
		name = "Python: 基础标准模板",
		filename = "main.py",
		text = "python python3 main.py",
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
	{
		name = "Node.js: Express 服务器",
		filename = "server.js",
		text = "nodejs express server web",
		content = [[/**
 * @File    : ${FILENAME}
 * @Time    : ${DATE} ${TIME}
 * @Author  : ${USER}
 * @.claude/PROJECT_CONTEXT.md : ${PROJECT}
 */

'use strict';

const express = require('express');
const app = express();

// 中间件
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 路由
app.get('/', (req, res) => {
    res.json({ message: 'Hello World!' });
});

${0}

// 启动服务器
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
]],
	},
	{
		name = "Node.js: TypeScript Express",
		filename = "server.ts",
		text = "nodejs typescript express server web",
		content = [[/**
 * @File    : ${FILENAME}
 * @Time    : ${DATE} ${TIME}
 * @Author  : ${USER}
 * @.claude/PROJECT_CONTEXT.md : ${PROJECT}
 */

import express, { Request, Response } from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 路由
app.get('/', (req: Request, res: Response) => {
    res.json({ message: 'Hello World!' });
});

${0}

// 启动服务器
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
]],
	},
	{
		name = "Node.js: CLI 工具模板",
		filename = "cli.js",
		text = "nodejs cli command tool",
		content = [[#!/usr/bin/env node
/**
 * @File    : ${FILENAME}
 * @Time    : ${DATE} ${TIME}
 * @Author  : ${USER}
 * @.claude/PROJECT_CONTEXT.md : ${PROJECT}
 */

'use strict';

const fs = require('fs');
const path = require('path');

// 主函数
async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.log('Usage: node cli.js <command>');
        process.exit(1);
    }

    const [command, ...options] = args;

    switch (command) {
        case 'build':
            console.log('Building...');
            ${0}
            break;
        case 'dev':
            console.log('Development mode...');
            break;
        default:
            console.error(`Unknown command: ${command}`);
            process.exit(1);
    }
}

main().catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
]],
	},
	{
		name = "Node.js: package.json",
		filename = "package.json",
		text = "nodejs npm package config",
		content = [[{
  "name": "${PROJECT}",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "type": "module",
  "scripts": {
    "start": "node index.js",
    "dev": "node --watch index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "${USER}",
  "license": "MIT"
}
]],
	},
	{
		name = "Docker: Node.js 应用",
		filename = "Dockerfile",
		text = "docker nodejs container",
		content = [[# @File    : ${FILENAME}
# @Time    : ${DATE} ${TIME}
# @Author  : ${USER}
# @.claude/PROJECT_CONTEXT.md : ${PROJECT}

FROM node:20-alpine

WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["npm", "start"]
]],
	},
	{
		name = "Docker: Python 应用",
		filename = "Dockerfile",
		text = "docker python container",
		content = [[# @File    : ${FILENAME}
# @Time    : ${DATE} ${TIME}
# @Author  : ${USER}
# @.claude/PROJECT_CONTEXT.md : ${PROJECT}

FROM python:3.12-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["python", "app.py"]
]],
	},
	{
		name = "React: 函数组件",
		filename = "Component.tsx",
		text = "react typescript component",
		content = [[/**
 * @File    : ${FILENAME}
 * @Time    : ${DATE} ${TIME}
 * @Author  : ${USER}
 * @.claude/PROJECT_CONTEXT.md : ${PROJECT}
 */

import React from 'react';

interface Props {
    title: string;
}

export const Component: React.FC<Props> = ({ title }) => {
    return (
        <div className="component">
            <h1>{title}</h1>
            ${0}
        </div>
    );
};

export default Component;
]],
	},
	{
		name = "Vue 3: 组合式 API",
		filename = "Component.vue",
		text = "vue composition component",
		content = [[<!--
  @File    : ${FILENAME}
  @Time    : ${DATE} ${TIME}
  @Author  : ${USER}
  @.claude/PROJECT_CONTEXT.md : ${PROJECT}
-->

<template>
  <div class="component">
    <h1>{{ title }}</h1>
    ${0}
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

interface Props {
  title: string;
}

const props = defineProps<Props>();
const count = ref(0);
</script>

<style scoped>
.component {
  padding: 20px;
}
</style>
]],
	},
	{
		name = "Config: .gitignore 通用版",
		filename = ".gitignore",
		text = "gitignore config template",
		content = [[# @File    : ${FILENAME}
# @Time    : ${DATE} ${TIME}
# @Author  : ${USER}
# @.claude/PROJECT_CONTEXT.md : ${PROJECT}

# Dependencies
node_modules/
__pycache__/
*.py[cod]
*$py.class
*.so
.Python

# Build
dist/
build/
*.egg-info/
.eggs/
*.egg

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS
.DS_Store
Thumbs.db

# Testing
.coverage
htmlcov/
.pytest_cache/
.tox/

# Misc
${0}
]],
	},
	{
		name = "Docker: Compose 配置",
		filename = "docker-compose.yml",
		text = "docker compose services",
		content = [[# @File    : ${FILENAME}
# @Time    : ${DATE} ${TIME}
# @Author  : ${USER}
# @.claude/PROJECT_CONTEXT.md : ${PROJECT}

version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${PROJECT}
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - db_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

  ${0}

volumes:
  db_data:
  redis_data:
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

	Snacks.picker.pick({
		title = " 选择文件模板 ",
		items = M.templates,
		-- 使用自定义布局以确保文本不被截断
		layout = {
			preset = "default",
			layout = {
				box = "horizontal",
				width = 0.75,
				min_width = 80,
				height = 0.8,
				{
					box = "vertical",
					border = "rounded",
					title = "{title} {live} {flags}",
					width = 0.45,
					{ win = "input", height = 1, border = "bottom" },
					{ win = "list", border = "none" },
				},
				{
					win = "preview",
					title = "{preview}",
					border = "rounded",
					width = 0.65,
				},
			},
		},
		win = {
			list = {
				-- 禁用列对齐
				align = "left",
			},
		},
		-- 自定义预览逻辑：将模板字符串渲染到预览窗口
		preview = function(ctx)
			local item = ctx.item
			if not item or not item.content then return end
			
			-- 模拟预填充后的内容
			local vars = get_vars(item.filename)
			local preview_content = pre_process_template(item.content, vars)
			preview_content = preview_content:gsub("${0}", "󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 󰚩 ") -- 在预览中显示更多机器人图标
			
			local lines = vim.split(preview_content, "\n")
			ctx.preview:set_lines(lines)
			
			-- 设置语法高亮
			local ft = item.filename:match("%.(%w+)$")
			ctx.preview:highlight({ ft = ft })
		end,
		format = function(item)
			return {
				{ item.name, "SnacksPicker" },
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
