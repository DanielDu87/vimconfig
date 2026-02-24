--==============================================================================
-- 自动创建项目配置文件
--==============================================================================
-- 统一策略：
--   1. 优先使用非隐藏的 .js 格式（eslint.config.js / prettier.config.js 等）
--   2. 自动清理旧格式隐藏文件
--   3. 文件不存在 → 按模板创建；文件存在 → 检测内容并补充缺失配置
--   4. 不检查 package.json，无条件执行

-------------------------------------------------------------------------------
-- 工具函数
-------------------------------------------------------------------------------

-- 获取项目根目录
local function get_project_root()
	local buf_dir = vim.fn.expand("%:p:h")
	local project_root = vim.fn.finddir(".git/..", buf_dir .. ";")
	if project_root == "" then
		project_root = buf_dir
	end
	return project_root
end

-- 检查文件是否存在
local function file_exists(path)
	return vim.fn.filereadable(path) == 1
end

-- 读取文件内容
local function read_file(path)
	if not file_exists(path) then return nil end
	return table.concat(vim.fn.readfile(path), "\n")
end

-- 写入文件
local function write_file(path, content)
	local file = io.open(path, "w")
	if file then
		file:write(content)
		file:close()
		return true
	end
	return false
end

-- 清理旧格式配置文件
local function cleanup_old_formats(root, old_names, new_name)
	for _, name in ipairs(old_names) do
		local old_path = root .. "/" .. name
		if file_exists(old_path) then
			vim.fn.delete(old_path)
			vim.notify("✓ 已清理旧版 " .. name .. " → " .. new_name, vim.log.levels.INFO)
		end
	end
end

-------------------------------------------------------------------------------
-- ESLint 配置 → eslint.config.js
-------------------------------------------------------------------------------
local function setup_eslint_config()
	local root = get_project_root()
	local target = root .. "/eslint.config.js"

	cleanup_old_formats(root, {
		".eslintrc",
		".eslintrc.js",
		".eslintrc.cjs",
		".eslintrc.json",
		".eslintrc.yml",
		".eslintrc.yaml",
		"eslint.config.cjs",
		"eslint.config.mjs",
	}, "eslint.config.js")

	if not file_exists(target) then
		write_file(target, [[export default [
	{
		rules: {
			"no-unused-vars": "warn",
			"no-console": "off",
		},
	},
];
]])
		vim.notify("✓ 已自动创建 eslint.config.js", vim.log.levels.INFO)
	else
		local content = read_file(target)
		if content and not content:find("rules") then
			local patched = content:gsub(
				"(export%s+default%s+%[)",
				"%1\n\t{\n\t\trules: {\n\t\t\t\"no-unused-vars\": \"warn\",\n\t\t\t\"no-console\": \"off\",\n\t\t},\n\t},"
			)
			if patched ~= content then
				write_file(target, patched)
				vim.notify("✓ 已补充 eslint.config.js 默认规则", vim.log.levels.INFO)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Tailwind CSS 配置 → tailwind.config.js
-------------------------------------------------------------------------------
local function setup_tailwind_config()
	local root = get_project_root()
	local target = root .. "/tailwind.config.js"

	cleanup_old_formats(root, {
		".tailwindrc",
		"tailwind.config.cjs",
		"tailwind.config.mjs",
		"tailwind.config.ts",
	}, "tailwind.config.js")

	if not file_exists(target) then
		write_file(target, [[/** @type {import('tailwindcss').Config} */
module.exports = {
	content: ["./**/*.{html,js,ts,jsx,tsx,vue}"],
	theme: {
		extend: {},
	},
	plugins: [],
};
]])
		vim.notify("✓ 已自动创建 tailwind.config.js", vim.log.levels.INFO)
		-- 创建后重启 Tailwind LSP
		vim.defer_fn(function()
			vim.cmd("LspRestart tailwindcss")
		end, 500)
	else
		local content = read_file(target)
		if content and not content:find("content") then
			local patched = content:gsub(
				"(module%.exports%s*=%s*{)",
				'%1\n\tcontent: ["./**/*.{html,js,ts,jsx,tsx,vue}"],'
			)
			if patched ~= content then
				write_file(target, patched)
				vim.notify("✓ 已补充 tailwind.config.js content 配置", vim.log.levels.INFO)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Prettier 配置 → prettier.config.js
-------------------------------------------------------------------------------
local function setup_prettier_config()
	local root = get_project_root()
	local target = root .. "/prettier.config.js"

	cleanup_old_formats(root, {
		".prettierrc",
		".prettierrc.json",
		".prettierrc.yml",
		".prettierrc.yaml",
		".prettierrc.js",
		".prettierrc.cjs",
		".prettierrc.mjs",
		".prettierrc.toml",
		"prettier.config.cjs",
		"prettier.config.mjs",
	}, "prettier.config.js")

	if not file_exists(target) then
		write_file(target, [[/** @type {import("prettier").Config} */
export default {
	useTabs: true,
	tabWidth: 4,
	printWidth: 120,
	bracketSameLine: true,
	plugins: ["prettier-plugin-tailwindcss"],
};
]])
		vim.notify("✓ 已自动创建 prettier.config.js", vim.log.levels.INFO)
	else
		local content = read_file(target)
		if not content then return end
		local modified = false

		if not content:find("useTabs") then
			content = content:gsub(
				"(export%s+default%s+{)",
				"%1\n\tuseTabs: true,\n\ttabWidth: 4,"
			)
			modified = true
		end

		if not content:find("prettier%-plugin%-tailwindcss") then
			if content:find("plugins") then
				content = content:gsub(
					"(plugins:%s*%[)",
					'%1"prettier-plugin-tailwindcss", '
				)
			else
				content = content:gsub(
					"(};)",
					'\tplugins: ["prettier-plugin-tailwindcss"],\n%1'
				)
			end
			modified = true
		end

		if modified then
			write_file(target, content)
			vim.notify("✓ 已补充 prettier.config.js 默认配置", vim.log.levels.INFO)
		end
	end
end

-------------------------------------------------------------------------------
-- Stylelint 配置 → stylelint.config.js
-------------------------------------------------------------------------------
local function setup_stylelint_config()
	local root = get_project_root()
	local target = root .. "/stylelint.config.js"

	cleanup_old_formats(root, {
		".stylelintrc",
		".stylelintrc.json",
		".stylelintrc.yml",
		".stylelintrc.yaml",
		".stylelintrc.js",
		".stylelintrc.cjs",
		".stylelintrc.mjs",
		"stylelint.config.cjs",
		"stylelint.config.mjs",
	}, "stylelint.config.js")

	if not file_exists(target) then
		write_file(target, [[/** @type {import("stylelint").Config} */
export default {
	extends: [
		"stylelint-config-standard",
		"stylelint-config-recess-order",
	],
};
]])
		vim.notify("✓ 已自动创建 stylelint.config.js", vim.log.levels.INFO)
	else
		local content = read_file(target)
		if not content then return end
		local modified = false

		if not content:find("stylelint%-config%-standard") then
			if content:find("extends") then
				content = content:gsub(
					"(extends:%s*%[)",
					'%1\n\t\t"stylelint-config-standard",'
				)
			else
				content = content:gsub(
					"(export%s+default%s+{)",
					'%1\n\textends: [\n\t\t"stylelint-config-standard",\n\t],'
				)
			end
			modified = true
		end

		if not content:find("stylelint%-config%-recess%-order") then
			if content:find("extends") then
				content = content:gsub(
					"(extends:%s*%[)",
					'%1\n\t\t"stylelint-config-recess-order",'
				)
			end
			modified = true
		end

		if modified then
			write_file(target, content)
			vim.notify("✓ 已补充 stylelint.config.js 默认预设", vim.log.levels.INFO)
		end
	end
end

-------------------------------------------------------------------------------
-- 自动命令注册
-------------------------------------------------------------------------------
return {
	{
		"nvim-lua/plenary.nvim",
		event = "VeryLazy",
		config = function()
			local augroup = vim.api.nvim_create_augroup("AutoConfigSetup", { clear = true })

			-- HTML/Django/模板文件：Tailwind + Prettier
			vim.api.nvim_create_autocmd({ "FileType" }, {
				pattern = { "html", "htmldjango" },
				group = augroup,
				callback = function()
					setup_tailwind_config()
					setup_prettier_config()
				end,
			})
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				pattern = { "*.html", "*.htm", "*.djhtml" },
				group = augroup,
				callback = function()
					setup_tailwind_config()
					setup_prettier_config()
				end,
			})

			-- JS/TS/Vue/JSX/TSX 文件：ESLint + Tailwind + Prettier
			vim.api.nvim_create_autocmd({ "FileType" }, {
				pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" },
				group = augroup,
				callback = function()
					setup_eslint_config()
					setup_tailwind_config()
					setup_prettier_config()
				end,
			})
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				pattern = { "*.js", "*.ts", "*.jsx", "*.tsx", "*.vue" },
				group = augroup,
				callback = function()
					setup_eslint_config()
					setup_tailwind_config()
					setup_prettier_config()
				end,
			})

			-- CSS/SCSS/LESS 文件：Stylelint + Prettier
			vim.api.nvim_create_autocmd({ "FileType" }, {
				pattern = { "css", "scss", "less" },
				group = augroup,
				callback = function()
					setup_stylelint_config()
					setup_prettier_config()
				end,
			})
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				pattern = { "*.css", "*.scss", "*.less" },
				group = augroup,
				callback = function()
					setup_stylelint_config()
					setup_prettier_config()
				end,
			})
		end,
	},
}
