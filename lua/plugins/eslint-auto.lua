--==============================================================================
-- 自动创建项目配置文件
--==============================================================================
-- 根据文件类型自动创建必要的配置文件

-- 获取项目根目录
local function get_project_root()
	local buf_dir = vim.fn.expand("%:p:h")
	local project_root = vim.fn.finddir(".git/..", buf_dir .. ";")
	if project_root == "" then
		project_root = buf_dir
	end
	return project_root
end

-- 自动创建 ESLint 配置
local function setup_eslint_config()
	local project_root = get_project_root()
	local old_config = project_root .. "/.eslintrc.js"
	local new_config = project_root .. "/eslint.config.js"

	-- 如果存在旧的 .eslintrc.js，先删除
	if vim.fn.filereadable(old_config) == 1 then
		vim.fn.delete(old_config)
		vim.notify("✓ 已删除旧版 .eslintrc.js", vim.log.levels.INFO)
	end

	-- 如果不存在新的 eslint.config.js，则创建
	if vim.fn.filereadable(new_config) == 0 then
		local config_content = [[export default [
	{
		rules: {
			"no-unused-vars": "warn",
			"no-console": "off",
		},
	},
];
]]

		local file = io.open(new_config, "w")
		if file then
			file:write(config_content)
			file:close()
			vim.notify("✓ 已自动创建 eslint.config.js", vim.log.levels.INFO)
		end
	end
end

-- 自动创建 Tailwind CSS 配置
local function setup_tailwind_config()
	local project_root = get_project_root()
	local config_file = project_root .. "/tailwind.config.js"

	if vim.fn.filereadable(config_file) == 0 then
		local config_content = [[/** @type {import('tailwindcss').Config} */
module.exports = {
	content: ["./**/*.{html,js,ts,jsx,tsx,vue}"],
	theme: {
		extend: {},
	},
	plugins: [],
};
]]

		local file = io.open(config_file, "w")
		if file then
			file:write(config_content)
			file:close()
			vim.notify("✓ 已自动创建 tailwind.config.js", vim.log.levels.INFO)
		end
	end
end

-- 自动创建 Prettier 配置
local function setup_prettier_config()
	local project_root = get_project_root()
	local config_file = project_root .. "/.prettierrc"

	if vim.fn.filereadable(config_file) == 0 then
		local config_content = [[{
	"useTabs": true,
	"tabWidth": 4,
	"printWidth": 120,
	"bracketSameLine": true,
	"plugins": ["prettier-plugin-tailwindcss"]
}
]]

		local file = io.open(config_file, "w")
		if file then
			file:write(config_content)
			file:close()
			vim.notify("✓ 已自动创建 .prettierrc", vim.log.levels.INFO)
		end
	end
end

return {
	{
		"nvim-lua/plenary.nvim",
		event = "VeryLazy",
		config = function()
			local augroup = vim.api.nvim_create_augroup("AutoConfigSetup", { clear = true })

			-- HTML 文件：自动创建 Tailwind 和 Prettier 配置
			vim.api.nvim_create_autocmd({ "FileType" }, {
				pattern = { "html" },
				group = augroup,
				callback = function()
					setup_tailwind_config()
					setup_prettier_config()
				end,
				once = false,
			})

			-- 保存 HTML 文件时也检查
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				pattern = "*.html",
				group = augroup,
				callback = function()
					setup_tailwind_config()
					setup_prettier_config()
				end,
			})

			-- JS/TS 文件：自动创建 ESLint 配置
			vim.api.nvim_create_autocmd({ "FileType" }, {
				pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" },
				group = augroup,
				callback = function()
					setup_eslint_config()
					setup_tailwind_config()
					setup_prettier_config()
				end,
				once = false,
			})

			-- 保存 JS/TS 文件时也检查
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				pattern = { "*.js", "*.ts", "*.jsx", "*.tsx", "*.vue" },
				group = augroup,
				callback = function()
					setup_eslint_config()
					setup_tailwind_config()
					setup_prettier_config()
				end,
			})
		end,
	},
}
