--==============================================================================
-- Neovim 键位映射配置
--==============================================================================
-- 这些键位映射会在 VeryLazy 事件时自动加载
--
-- LazyVim 已经预配置了大量实用的键位映射
-- 完整列表: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- 使用 :LazyKeys 命令或 <leader>sk 查看所有键位映射

--==============================================================================
-- 禁用 K 键 hover 功能
--==============================================================================
vim.keymap.set("n", "K", "<nop>", { desc = "禁用 K 键" })

--==============================================================================
-- gl 切换诊断浮窗（复用同一个窗口，减少遮挡）
--==============================================================================
local diag_float = nil

vim.keymap.set("n", "gl", function()
	if diag_float and vim.api.nvim_win_is_valid(diag_float) then
		vim.api.nvim_win_close(diag_float, true)
		diag_float = nil
		return
	end
	diag_float = vim.diagnostic.open_float(nil, {
		focus = false,
		focusable = false,
		scope = "cursor",
		border = "rounded",
		source = "if_many",
		header = "",
		prefix = "",
	})
end, { desc = "行诊断（切换浮窗）" })

--==============================================================================
-- DevDocs 文档搜索
--==============================================================================
local function open_url(url)
	-- 使用全局定义的浏览器路径打开 URL
	local browser = vim.g.browser_path or "open"
	vim.fn.jobstart({ "open", "-a", browser, url }, { detach = true })
end

local function devdocs_search(q)
	q = (q or vim.fn.expand("<cword>")):gsub(" ", "%%20")
	open_url("https://devdocs.io/#q=" .. q)
end

-- leader+k: 搜索当前单词
vim.keymap.set("n", "<leader>k", function()
	devdocs_search()
end, { desc = "查询DevDocs（当前关键词）" })

-- leader+K: 输入查询
vim.keymap.set("n", "<leader>K", function()
	vim.ui.input({ prompt = "DevDocs查询：" }, function(q)
		if q and #q > 0 then
			devdocs_search(q)
		end
	end)
end, { desc = "搜索DevDocs（输入查询）" })

--==============================================================================
-- 历史记录键位重新组织到 <leader>h 组
--==============================================================================
vim.api.nvim_create_autocmd("User", {
	pattern = "LazyVimKeymaps",
	callback = function()
		-- 安全删除旧的历史相关键位
		local safe_del = function(mode, lhs)
			pcall(vim.keymap.del, mode, lhs)
		end
		safe_del("n", "<leader>n")
		safe_del("n", "<leader>:")
		safe_del("n", "<leader>s/")
		safe_del("n", "<leader>sc")
		-- 删除 LazyVim 默认的通知键位，我们将它们移到顶层 <leader>
		safe_del("n", "<leader>sn")
		safe_del("n", "<leader>snl")
		safe_del("n", "<leader>snh")
		safe_del("n", "<leader>sna")
		safe_del("n", "<leader>snd")
	end,
})

local Snacks = require("snacks")

-- leader+hn: 通知历史记录
vim.keymap.set("n", "<leader>hn", function()
	Snacks.picker.notifications()
end, { desc = "通知历史记录" })

-- leader+hl: 最后一条通知
vim.keymap.set("n", "<leader>hl", function()
	require("noice").cmd("last")
end, { desc = "最后一条通知" })

-- leader+ha: 所有通知
vim.keymap.set("n", "<leader>ha", function()
	require("noice").cmd("all")
end, { desc = "所有通知" })

-- leader+hx: 清除所有通知
vim.keymap.set("n", "<leader>hx", function()
	require("noice").cmd("dismiss")
end, { desc = "清除所有通知" })

-- leader+hc: 命令历史
vim.keymap.set("n", "<leader>hc", function()
	Snacks.picker.command_history()
end, { desc = "命令历史" })

-- leader+hs: 搜索历史
vim.keymap.set("n", "<leader>hs", function()
	Snacks.picker.search_history()
end, { desc = "搜索历史" })

-- leader+H: 切换显示隐藏文件
vim.keymap.set("n", "<leader>H", function()
	local ok, pickers = pcall(function()
		return require("snacks.picker").get({ source = "explorer" })
	end)
	if ok and pickers and #pickers > 0 then
		local picker = pickers[1]
		if not picker.closed then
			picker.opts.hidden = not picker.opts.hidden
			picker.list:set_target()
			picker:find()
			return
		end
	end
	local LazyVim = require("lazyvim.util")
	Snacks.explorer({ cwd = LazyVim.root() })
end, { desc = "切换显示隐藏文件" })

--==============================================================================
-- TS 版本切换 (全局映射，非 TS 文件给出提示)
--==============================================================================
vim.keymap.set("n", "<leader>rV", function()
	local ft = vim.bo.filetype
	if ft == "typescript" or ft == "typescriptreact" or ft == "vue" then
		-- 只有在 TS/Vue 文件中才尝试调用 vtsls 命令
		local ok, vtsls = pcall(require, "vtsls")
		if ok and vtsls.commands and vtsls.commands.select_ts_version then
			vtsls.commands.select_ts_version()
		else
			vim.notify("TS 服务未就绪", vim.log.levels.WARN, { title = "LSP" })
		end
	else
		vim.notify("非 TS 文件，无法切换版本", vim.log.levels.WARN, { title = "LSP" })
	end
end, { desc = "选择 TS 工作区版本" })

--==============================================================================
-- 代码重构 (Visual 模式)
--==============================================================================
vim.keymap.set("v", "<leader>r", function()
	require("util.refactor_smart").smart_visual_refactor()
end, { desc = "智能重构 (选中)" })

--==============================================================================
-- 移动当前行/选中区域 (光标跟随)
--==============================================================================
-- Normal 模式下移动当前行
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "向下移动行" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "向上移动行" })

-- Visual 模式下移动选中区域
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "向下移动选中区域" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "向上移动选中区域" })
