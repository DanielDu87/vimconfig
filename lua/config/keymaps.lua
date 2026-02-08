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

--==============================================================================
-- 单引号打开书签菜单
--==============================================================================
vim.keymap.set("n", "'", function()
	local bookmarks = require("util.marks")
	bookmarks.list()
end, { desc = "打开书签菜单" })

--==============================================================================
-- 跳转到指定行
--==============================================================================
vim.keymap.set("n", "<leader>cn", function()
	vim.ui.input({ prompt = "跳转到第n行：" }, function(input)
		if not input or #input == 0 then
			return
		end
		local line_num = tonumber(input)
		if line_num then
			-- 验证行号是否在有效范围内
			local line_count = vim.api.nvim_buf_line_count(0)
			if line_num < 1 then
				line_num = 1
			elseif line_num > line_count then
				line_num = line_count
			end
			-- 跳转并居中
			vim.api.nvim_win_set_cursor(0, { line_num, 0 })
			vim.cmd("normal! zz")
			vim.notify(string.format("已跳转到第 %d 行", line_num), vim.log.levels.INFO, { title = "跳转" })
		else
			vim.notify("无效的行号", vim.log.levels.ERROR, { title = "跳转" })
		end
	end)
end, { desc = "跳转到指定行" })

--==============================================================================
-- 竖向块选择 (Option + v)
--==============================================================================
vim.keymap.set({ "n", "v" }, "<M-v>", "<C-v>", { desc = "竖向块选择" })
-- 兼容 Mac 终端未开启 "Option as Meta" 的情况 (Option+v 默认输出 √)
vim.keymap.set({ "n", "v" }, "√", "<C-v>", { desc = "竖向块选择 (Mac兼容)" })
vim.keymap.set({ "n", "v" }, "<A-v>", "<C-v>", { desc = "竖向块选择 (Alt兼容)" })

--==============================================================================
-- 快捷修改括号/引号内容 (ciq -> ci", cie -> ci', cib -> ci()
--==============================================================================
vim.keymap.set("n", "ciq", 'ci"', { desc = "修改双引号内容" })
vim.keymap.set("n", "cie", "ci'", { desc = "修改单引号内容" })
vim.keymap.set("n", "cib", "ci(", { desc = "修改小括号内容" })

--==============================================================================
-- 终端模式快捷键
--==============================================================================
-- 终端模式下按 ESC 返回普通模式
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "终端返回普通模式" })

--==============================================================================
-- 通用映射
--==============================================================================
-- 全选 (在 which-key 中隐藏)
vim.keymap.set("n", "<leader>a", "ggVG", { desc = "which_key_ignore" })

-- leader+fa: 另存为 (保留原路径)
vim.keymap.set("n", "<leader>fa", function()
	local buf_name = vim.api.nvim_buf_get_name(0)

	-- 获取当前文件的目录和文件名
	local dir, filename
	if buf_name == "" then
		-- 如果是 [No Name] buffer，使用当前目录
		dir = vim.fn.getcwd() .. "/"
		filename = ""
	else
		dir = vim.fn.fnamemodify(buf_name, ":p:h") .. "/"
		filename = vim.fn.fnamemodify(buf_name, ":t")
	end

	-- 弹出输入框，保留原路径和文件名
	vim.ui.input({
		prompt = "另存为: ",
		default = dir .. filename,
		completion = "file",
	}, function(input)
		if not input or input == "" or input == dir then
			vim.notify("已取消保存", vim.log.levels.WARN)
			return
		end

		-- 确保目录存在
		local new_dir = vim.fn.fnamemodify(input, ":p:h")
		if vim.fn.isdirectory(new_dir) == 0 then
			vim.fn.mkdir(new_dir, "p")
		end

		-- 保存到新文件
		vim.cmd("write " .. vim.fn.fnameescape(input))
		vim.notify("已保存到: " .. input, vim.log.levels.INFO)
	end)
end, { desc = "另存为" })
