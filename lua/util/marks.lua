-- ============================================================================
-- 简单书签系统 (完全参照备份重构并优化)
-- ============================================================================

local M = {}

-- 书签存储
M.bookmarks = {}

-- 配置
M.config = {
    sign_name = "SimpleBookmark",
    sign_text = "🔖",
    save_file = vim.fn.expand("~/bookmarks.json"),
}

-- 初始化符号定义 (强制高亮颜色以确保可见性)
local function setup_signs()
    vim.cmd([[
        highlight SimpleBookmarkSign guifg=#ff6b6b guibg=NONE gui=bold
        highlight SimpleBookmarkNum guifg=#ff6b6b guibg=NONE gui=bold
    ]])
    
    vim.fn.sign_define(M.config.sign_name, {
        text = M.config.sign_text,
        texthl = "SimpleBookmarkSign",
        numhl = "SimpleBookmarkNum",
    })
end

-- 添加/移除 Sign
local function place_sign(bufnr, line)
    local sign_id = bufnr * 1000 + line
    pcall(vim.fn.sign_place, sign_id, "SimpleBookmarkGroup", M.config.sign_name, bufnr, {
        lnum = line,
        priority = 100
    })
end

local function remove_sign(bufnr, line)
    local sign_id = bufnr * 1000 + line
    pcall(vim.fn.sign_unplace, "SimpleBookmarkGroup", { buffer = bufnr, id = sign_id })
end

-- 保存/加载逻辑
function M.save_bookmarks()
    local clean_data = {}
    for file, marks in pairs(M.bookmarks) do
        if not vim.tbl_isempty(marks) then
            local rel_path = vim.fn.fnamemodify(file, ":.")
            local str_keys = {}
            for line, val in pairs(marks) do str_keys[tostring(line)] = val end
            clean_data[rel_path] = str_keys
        end
    end
    local f = io.open(M.config.save_file, "w")
    if f then
        f:write(vim.json.encode(clean_data))
        f:close()
    end
end

function M.load_bookmarks()
    local f = io.open(M.config.save_file, "r")
    if not f then return end
    local content = f:read("*all")
    f:close()
    if content == "" then return end
    local ok, data = pcall(vim.json.decode, content)
    if not ok then return end
    M.bookmarks = {}
    for rel_path, marks in pairs(data) do
        local abs_path = vim.fn.fnamemodify(rel_path, ":p")
        M.bookmarks[abs_path] = {}
        for line_str, _ in pairs(marks) do
            local line = tonumber(line_str)
            if line then M.bookmarks[abs_path][line] = true end
        end
    end
end

-- 恢复当前Buffer的Sign
local function restore_signs(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local marks = M.bookmarks[file_path]
    if marks then
        for line, _ in pairs(marks) do
            place_sign(bufnr, line)
        end
    end
end

-- 核心功能 API
function M.toggle()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.fn.line(".")
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" then return end
    if not M.bookmarks[file] then M.bookmarks[file] = {} end
    if M.bookmarks[file][line] then
        M.bookmarks[file][line] = nil
        remove_sign(bufnr, line)
        vim.notify("已移除书签", vim.log.levels.INFO)
    else
        M.bookmarks[file][line] = true
        place_sign(bufnr, line)
        vim.notify("已添加书签", vim.log.levels.INFO)
    end
    M.save_bookmarks()
end

function M.nav_next()
    local file = vim.api.nvim_buf_get_name(0)
    local marks = M.bookmarks[file] or {}
    local cur_line = vim.fn.line(".")
    local lines = {}
    for l, _ in pairs(marks) do table.insert(lines, l) end
    table.sort(lines)
    for _, l in ipairs(lines) do
        if l > cur_line then
            vim.api.nvim_win_set_cursor(0, {l, 0})
            return
        end
    end
    if #lines > 0 then vim.api.nvim_win_set_cursor(0, {lines[1], 0}) end
end

function M.nav_prev()
    local file = vim.api.nvim_buf_get_name(0)
    local marks = M.bookmarks[file] or {}
    local cur_line = vim.fn.line(".")
    local lines = {}
    for l, _ in pairs(marks) do table.insert(lines, l) end
    table.sort(lines, function(a,b) return a > b end)
    for _, l in ipairs(lines) do
        if l < cur_line then
            vim.api.nvim_win_set_cursor(0, {l, 0})
            return
        end
    end
    if #lines > 0 then vim.api.nvim_win_set_cursor(0, {lines[1], 0}) end
end

function M.clear_buf()
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    if M.bookmarks[file] then
        for l, _ in pairs(M.bookmarks[file]) do remove_sign(bufnr, l) end
        M.bookmarks[file] = nil
        M.save_bookmarks()
        vim.notify("已清空当前文件书签", vim.log.levels.INFO)
    end
end

function M.clear_all()
    vim.ui.select({"确认清空", "取消"}, {prompt="⚠️ 删除所有书签?"}, function(choice)
        if choice == "确认清空" then
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local file = vim.api.nvim_buf_get_name(buf)
                if M.bookmarks[file] then
                    for l, _ in pairs(M.bookmarks[file]) do remove_sign(buf, l) end
                end
            end
            M.bookmarks = {}
            M.save_bookmarks()
            vim.notify("已清空所有书签", vim.log.levels.INFO)
        end
    end)
end

-- 列表显示 (优化后的 Snacks Picker)
function M.list()
	-- 清理不存在文件的书签
	local cleaned = false
	for file, marks in pairs(M.bookmarks) do
		if vim.fn.filereadable(file) == 0 then
			-- 文件不存在，删除该书签
			M.bookmarks[file] = nil
			cleaned = true
		end
	end
	if cleaned then
		M.save_bookmarks()
	end

	local has_any = false
	for _, marks in pairs(M.bookmarks) do
		if not vim.tbl_isempty(marks) then has_any = true; break end
	end
	if not has_any then
		vim.notify("目前没有保存的书签", vim.log.levels.INFO)
		return
	end

	local items = {}
	for file, marks in pairs(M.bookmarks) do
		for line, _ in pairs(marks) do
			table.insert(items, {
				file = file,
				pos = { line, 0 },
				line = line,
			})
		end
	end

	-- 用于预览窗口书签行高亮的 namespace
	local preview_ns = vim.api.nvim_create_namespace("marks_preview_hl")

	require("snacks").picker.pick({
		title = "书签列表",
		items = items,
		layout = "default",
		preview = "file",
		-- 当选择改变时高亮书签行
		on_change = function(picker, item)
			if not picker.preview_win or not picker.preview_buf then
				return
			end

			local buf = picker.preview_buf
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end

			-- 清除之前的高亮
			vim.api.nvim_buf_clear_namespace(buf, preview_ns, 0, -1)

			if not item or not item.line then
				return
			end

			-- 添加行高亮
			vim.api.nvim_buf_add_highlight(buf, preview_ns, "CursorLine", item.line - 1, 0, -1)
		end,
		format = function(item, picker)
			local file_name = vim.fn.fnamemodify(item.file, ":t")
			local icon, hl = require("nvim-web-devicons").get_icon(item.file)
			return {
				{ (icon or "📄") .. " ", hl or "Comment" },
				{ file_name, "String" },
				{ ":", "Comment" },
				{ tostring(item.line), "Number" },
			}
		end,
	})
end

-- Setup
function M.setup()
    setup_signs()
    vim.opt.signcolumn = "yes"
    M.load_bookmarks()
    
    local grp = vim.api.nvim_create_augroup("SimpleBookmarks", {clear=true})
    vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile", "BufEnter"}, {
        group = grp,
        callback = function(args)
            vim.defer_fn(function() restore_signs(args.buf) end, 50)
        end
    })
end

return M
