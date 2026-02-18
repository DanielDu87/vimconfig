// Prettier 配置文件
// 使用 JavaScript 格式以便使用绝对路径指向全局安装的插件

const globalNodeModules = "/opt/homebrew/lib/node_modules";

module.exports = {
	// 使用 Tab 缩进
	useTabs: true,
	tabWidth: 4,
	printWidth: 120,
	bracketSameLine: true,

	// 在特定文件类型中使用 TailwindCSS 插件
	overrides: [
		{
			files: ["*.html", "*.css", "*.scss", "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue"],
			options: {
				// 使用绝对路径指向全局安装的插件
				plugins: [globalNodeModules + "/prettier-plugin-tailwindcss"],
			},
		},
		{
			// Markdown 等其他文件不使用 TailwindCSS 插件
			files: ["*.md", "*.markdown", "*.json", "*.yaml", "*.yml"],
			options: {
				plugins: [],
			},
		},
	],
};
