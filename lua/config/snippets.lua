local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

--==============================================================================
-- 基础配置
--==============================================================================
ls.setup({
	history = true,
	update_events = "TextChanged,TextChangedI",
})
require("luasnip.loaders.from_vscode").lazy_load()

-- 【配置助手函数】
local function add(fts, trig, content, nodes)
	local snip = s({ trig = trig, wordTrig = false }, fmt(content, nodes or {}))
	for _, ft in ipairs(type(fts) == "table" and fts or { fts }) do
		ls.add_snippets(ft, { snip })
	end
end

--==============================================================================
-- 自定义模板区域
--==============================================================================

-- 1. HTML5 基础模板 (! 触发)
add(
	{ "html", "vue", "javascriptreact", "typescriptreact", "htmldjango" },
	"!",
	[[
<!doctype html>
<html lang="zh-CN">
	<head>
		<meta charset="UTF-8" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />
		<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
		<title>{}</title>
	</head>
	<body>
		{}
	</body>
</html>
]],
	{ i(1, "Document"), i(0) }
)