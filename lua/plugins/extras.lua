--==============================================================================
-- LazyVim Extras 配置文件
--==============================================================================
-- 这个文件包含所有 LazyVim 官方 extras
-- 符合 LazyVim 导入顺序规范

return {

	-------------------------------------------------------------------------
	-- 前端开发 extras
	-------------------------------------------------------------------------

	-- TypeScript/JavaScript/HTML/CSS 支持（包含 React）
	-- 注意：LazyVim 将 HTML/CSS 支持包含在 typescript extra 中
	{ import = "lazyvim.plugins.extras.lang.typescript" },

	-- Tailwind CSS 支持
	{ import = "lazyvim.plugins.extras.lang.tailwind" },

	-- Vue 框架支持
	{ import = "lazyvim.plugins.extras.lang.vue" },

	-------------------------------------------------------------------------
	-- Docker 支持
	-------------------------------------------------------------------------

	{ import = "lazyvim.plugins.extras.lang.docker" },

	-------------------------------------------------------------------------
	-- Python 开发
	-------------------------------------------------------------------------

	{ import = "lazyvim.plugins.extras.lang.python" },

	-------------------------------------------------------------------------
	-- 基础功能 extras
	-------------------------------------------------------------------------

	-- 代码格式化（Prettier）
	{ import = "lazyvim.plugins.extras.formatting.prettier" },

	-- ESLint 代码检查
	{ import = "lazyvim.plugins.extras.linting.eslint" },

	-- JSON/YAML 配置文件支持
	{ import = "lazyvim.plugins.extras.lang.json" },

	-------------------------------------------------------------------------
	-- 可选 extras（根据需要启用）
	-------------------------------------------------------------------------

	-- Svelte 框架
	-- { import = "lazyvim.plugins.extras.lang.svelte" },

	-- Angular 框架
	-- { import = "lazyvim.plugins.extras.lang.angular" },

	-- Go 语言
	-- { import = "lazyvim.plugins.extras.lang.go" },

	-- Rust 语言
	-- { import = "lazyvim.plugins.extras.lang.rust" },

	-- Markdown
	{ import = "lazyvim.plugins.extras.lang.markdown" },

	-- AI 辅助编程（Codeium - 免费）
	-- { import = "lazyvim.plugins.extras.ai.codeium" },

	-- GitHub Copilot（需要订阅）
	-- { import = "lazyvim.plugins.extras.ai.copilot" },

	-- Git UI（可选）
	-- { import = "lazyvim.plugins.extras.util.gitui" },

	-- 项目管理（可选）
	-- { import = "lazyvim.plugins.extras.util.project" },
}
