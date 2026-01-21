local M = {}

-- 模块内状态变量（替代全局变量），用于记录是否为剪切模式
local cut_mode = false

---@param Actions table Snacks explorer actions module
---@param Snacks table Snacks global object
function M.setup(Actions, Snacks)
	local uv = vim.uv or vim.loop
	local util = require("snacks.picker.util")

	--==============================================================================
	-- 辅助函数：计算副本文件名 (自动追加 ~1, ~2)
	--==============================================================================
	function util.get_backup_name(to)
		if not uv.fs_stat(to) then
			return to
		end
		local counter = 1
		local base, ext = to:match("^(.-)(%.[^.]+)$")
		if not base then
			base, ext = to, ""
		end
		local new_to = to
		while uv.fs_stat(new_to) do
			new_to = base .. "~" .. counter .. ext
			counter = counter + 1
		end
		return new_to
	end

	--==============================================================================
	-- 辅助函数：系统级文件操作封装
	--==============================================================================
	function util.copy_path(from, to)
		if not uv.fs_stat(from) then
			Snacks.notify.error(("文件不存在：`%s`"):format(from))
			return false
		end
		if Snacks.util.path_type(from) == "directory" then
			util.copy_dir(from, to)
		else
			util.copy_file(from, to)
		end
		return true
	end

	function util.copy_file(from, to)
		if vim.fn.filereadable(from) == 0 then
			Snacks.notify.error(("文件不可读：`%s`"):format(from))
			return
		end
		local dir = vim.fs.dirname(to)
		vim.fn.mkdir(dir, "p")
		local ok, err = uv.fs_copyfile(from, to, { excl = true, ficlone = true })
		if not ok then
			Snacks.notify.error(("复制文件失败：\n- 从：`%s`\n- 到：`%s`\n%s"):format(from, to, err))
		end
	end

	--==============================================================================
	-- 辅助函数：生成详细提示信息
	--==============================================================================
	local function notify_files(action, files, dirs, extra_msg)
		local msg_parts = {}

		-- 目录统计
		if #dirs > 0 then
			table.insert(msg_parts, action .. " " .. #dirs .. " 个目录：")
			if #dirs <= 10 then
				for _, d in ipairs(dirs) do
					table.insert(msg_parts, "- " .. d)
				end
			else
				for i = 1, 10 do
					table.insert(msg_parts, "- " .. dirs[i])
				end
				table.insert(msg_parts, "... 等 " .. (#dirs - 10) .. " 个")
			end
		end

		-- 文件统计
		if #files > 0 then
			table.insert(msg_parts, action .. " " .. #files .. " 个文件：")
			if #files <= 10 then
				for _, f in ipairs(files) do
					table.insert(msg_parts, "- " .. f)
				end
			else
				for i = 1, 10 do
					table.insert(msg_parts, "- " .. files[i])
				end
				table.insert(msg_parts, "... 等 " .. (#files - 10) .. " 个")
			end
		end

		-- 额外信息
		if extra_msg then
			table.insert(msg_parts, extra_msg)
		end

		if #msg_parts > 0 then
			Snacks.notify.info(table.concat(msg_parts, "\n"))
		end
	end

	--==============================================================================
	-- Action: 剪切 (Cut)
	--==============================================================================
	function Actions.actions.explorer_cut(picker)
		local files = {}
		if vim.fn.mode():find("^[vV]") then
			picker.list:select()
		end
		for _, item in ipairs(picker:selected({ fallback = true })) do
			table.insert(files, Snacks.picker.util.path(item))
		end
		if #files == 0 then
			return Snacks.notify.warn("未选择文件")
		end

		picker.list:set_selected()
		local value = table.concat(files, "\n")
		vim.fn.setreg(vim.v.register or "+", value, "l")
		cut_mode = true

		local dirs, file_list = {}, {}
		for _, path in ipairs(files) do
			local stat = uv.fs_stat(path)
			if stat and stat.type == "directory" then
				table.insert(dirs, path)
			else
				table.insert(file_list, path)
			end
		end

		notify_files("已剪切", file_list, dirs, "\n（粘贴后将移动原文件）")
	end

	--==============================================================================
	-- Action: 复制 (Yank)
	--==============================================================================
	function Actions.actions.explorer_yank(picker)
		local files = {}
		if vim.fn.mode():find("^[vV]") then
			picker.list:select()
		end
		for _, item in ipairs(picker:selected({ fallback = true })) do
			table.insert(files, Snacks.picker.util.path(item))
		end
		if #files == 0 then
			return Snacks.notify.warn("未选择文件")
		end

		picker.list:set_selected()
		local value = table.concat(files, "\n")
		vim.fn.setreg(vim.v.register or "+", value, "l")
		cut_mode = false

		local dirs, file_list = {}, {}
		for _, path in ipairs(files) do
			local stat = uv.fs_stat(path)
			if stat and stat.type == "directory" then
				table.insert(dirs, path)
			else
				table.insert(file_list, path)
			end
		end
		notify_files("已复制", file_list, dirs)
	end

	--==============================================================================
	-- Action: 粘贴 (Paste) - 优化冲突处理
	--==============================================================================
	function Actions.actions.explorer_paste(picker)
		local reg_content = vim.fn.getreg(vim.v.register or "+") or ""
		local files = vim.split(reg_content, "\n", { plain = true })
		files = vim.tbl_filter(function(f)
			return f ~= "" and (vim.fn.filereadable(f) == 1 or vim.fn.isdirectory(f) == 1)
		end, files)

		if #files == 0 then
			return Snacks.notify.warn("剪贴板中没有有效文件")
		end

		local dir = picker:dir()
		local is_move = cut_mode
		local processed_files = {}
		local processed_dirs = {}
		local renamed_items = {}

		for _, file in ipairs(files) do
			local filename = vim.fn.fnamemodify(file, ":t")
			local target = vim.fs.normalize(dir .. "/" .. filename)
			local stat = uv.fs_stat(file)
			local is_dir = stat and stat.type == "directory"
			local ok = false

			-- 原地操作：强制转为复制副本模式
			if file == target then
				if is_move then
					-- 剪切到原位置：无效操作，跳过
				else
					local backup = util.get_backup_name(target)
					util.copy_path(file, backup)
					table.insert(renamed_items, vim.fn.fnamemodify(backup, ":t"))
					ok = true
					target = backup -- 更新目标以便统计
				end
			else
				-- 异地操作
				if uv.fs_stat(target) then
					local new_target = util.get_backup_name(target)
					table.insert(
						renamed_items,
						vim.fn.fnamemodify(filename, ":t") .. " -> " .. vim.fn.fnamemodify(new_target, ":t")
					)
					target = new_target
				end

				if is_move then
					local res = vim.fn.rename(file, target)
					if res == 0 then
						ok = true
					end
				else
					util.copy_path(file, target)
					ok = true
				end
			end

			if ok then
				if is_dir then
					table.insert(processed_dirs, target)
				else
					table.insert(processed_files, target)
				end
			end
		end

		if is_move then
			cut_mode = false
			vim.fn.setreg(vim.v.register or "+", "", "l")
		end

		local Tree = require("snacks.explorer.tree")
		Tree:refresh(dir)
		Actions.update(picker, { target = dir })

		-- 构建结果提示
		local extra_msg = nil
		if #renamed_items > 0 then
			extra_msg = "\n以下文件已自动重命名："
			if #renamed_items <= 5 then
				for _, r in ipairs(renamed_items) do
					extra_msg = extra_msg .. "\n- " .. r
				end
			else
				extra_msg = extra_msg .. "\n- " .. renamed_items[1] .. "\n... 等 " .. #renamed_items .. " 个"
			end
		end

		local action_name = is_move and "已移动" or "已粘贴"
		notify_files(action_name, processed_files, processed_dirs, extra_msg)
	end

	--==============================================================================
	-- Action: 删除 (Delete) - 带预览和居中
	--==============================================================================
	function Actions.actions.explorer_del(picker)
		local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
		if #paths == 0 then
			return
		end

		local init_dir = vim.fn.getcwd()
		for _, path in ipairs(paths) do
			if vim.fs.normalize(path) == vim.fs.normalize(init_dir) then
				return Snacks.notify.warn("不能删除项目根目录")
			end
		end

		-- 统计信息
		local dir_count = 0
		local file_count = 0
		local display_paths = {}
		for _, path in ipairs(paths) do
			local stat = uv.fs_stat(path)
			if stat and stat.type == "directory" then
				dir_count = dir_count + 1
			else
				file_count = file_count + 1
			end
			table.insert(display_paths, (path:gsub("@$", "")))
		end

		local function get_confirm_text()
			if dir_count > 0 and file_count > 0 then
				return "是否删除 " .. dir_count .. " 个目录、" .. file_count .. " 个文件？"
			elseif dir_count > 0 then
				return "是否删除 " .. dir_count .. " 个目录？"
			else
				return "是否删除 " .. file_count .. " 个文件？"
			end
		end

		-- 预览列表逻辑
		local function center_text(text, width)
			local padding = math.floor((width - vim.api.nvim_strwidth(text)) / 2)
			return string.rep(" ", math.max(0, padding)) .. text
		end

		local max_len = 0
		for _, p in ipairs(display_paths) do
			max_len = math.max(max_len, vim.api.nvim_strwidth(p))
		end
		local win_width = math.max(30, math.min(max_len + 10, 80)) -- 增加最大宽度

		local list_lines = {}
		for _, p in ipairs(display_paths) do
			table.insert(list_lines, center_text(p, win_width))
		end

		local max_h = 15 -- 增加预览高度
		if #list_lines > max_h then
			local count = #list_lines
			list_lines = { unpack(list_lines, 1, max_h - 1) }
			table.insert(list_lines, center_text("...（还有 " .. (count - max_h + 1) .. " 项）", win_width))
		end

		-- 创建浮动窗口
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, list_lines)
		vim.bo[buf].modifiable = false

		local row = math.floor(vim.o.lines / 2) + 2
		local preview_win = vim.api.nvim_open_win(buf, false, {
			relative = "editor",
			row = row,
			col = math.floor((vim.o.columns - win_width) / 2),
			width = win_width,
			height = #list_lines,
			style = "minimal",
			border = "rounded",
			zindex = 50,
		})
		vim.wo[preview_win].winblend = 0
		vim.wo[preview_win].winhl = "Normal:NormalFloat,NormalNC:NormalFloat"

		-- 执行删除
		local function do_delete()
			local deleted_files = {}
			local deleted_dirs = {}
			for _, path in ipairs(paths) do
				local stat = uv.fs_stat(path)
				local is_dir = stat and stat.type == "directory"
				local ok, err = Actions.trash(path)
				if ok then
					Snacks.bufdelete({ file = path, force = true })
					if is_dir then
						table.insert(deleted_dirs, path)
					else
						table.insert(deleted_files, path)
					end
				else
					Snacks.notify.error("删除失败：\n" .. (err or "未知错误"))
				end
			end
			local Tree = require("snacks.explorer.tree")
			Tree:refresh(picker:dir())
			Actions.update(picker)
			notify_files("已删除", deleted_files, deleted_dirs)
		end

		Snacks.picker.select({ "取消", "删除" }, {
			prompt = get_confirm_text(),
			layout = { preset = "select", layout = { max_width = 60 } },
		}, function(_, idx)
			if preview_win and vim.api.nvim_win_is_valid(preview_win) then
				vim.api.nvim_win_close(preview_win, true)
			end
			if idx == 2 then
				do_delete()
			end
		end)
	end

	--==============================================================================
	-- Action: 新建文件/目录 (Add)
	--==============================================================================
	function Actions.actions.explorer_add(picker)
		Snacks.input({
			prompt = "新建文件或目录（目录以 / 结尾）：",
		}, function(value)
			if not value or value:find("^%s$") then
				return
			end
			local path = vim.fs.normalize(picker:dir() .. "/" .. value)
			local is_file = value:sub(-1) ~= "/"
			local dir = is_file and vim.fs.dirname(path) or path

			if is_file and uv.fs_stat(path) then
				return Snacks.notify.warn("文件已存在：\n" .. path)
			end

			local ok, err = pcall(vim.fn.mkdir, dir, "p")
			if not ok then
				return Snacks.notify.error("创建失败：" .. err)
			end

			if is_file then
				local f = io.open(path, "w")
				if f then
					f:close()
				end
			end

			local Tree = require("snacks.explorer.tree")
			Tree:open(dir)
			Tree:refresh(dir)
			Actions.update(picker, { target = path })
			Snacks.notify.info("已创建：\n" .. path)
		end)
	end

	--==============================================================================
	-- Action: 重命名 (Rename)
	--==============================================================================
	function Actions.actions.explorer_rename(picker, item)
		if not item then
			return Snacks.notify.warn("未选择文件")
		end
		local old_name = vim.fn.fnamemodify(item.file, ":t")
		Snacks.input({
			prompt = "重命名：",
			default = old_name,
		}, function(new_name)
			if not new_name or new_name == "" or new_name == old_name then
				return
			end
			local new_path = vim.fs.normalize(vim.fs.dirname(item.file) .. "/" .. new_name)
			if uv.fs_stat(new_path) then
				return Snacks.notify.warn("目标已存在")
			end

			Snacks.rename.rename_file({
				from = item.file,
				to = new_path,
				on_rename = function(new, old)
					local Tree = require("snacks.explorer.tree")
					Tree:refresh(vim.fs.dirname(old))
					Tree:refresh(vim.fs.dirname(new))
					Actions.update(picker, { target = new })
					Snacks.notify.info("已重命名为：\n" .. new_name)
				end,
			})
		end)
	end

	--==============================================================================
	-- Action: 复制副本 (Copy)
	--==============================================================================
	function Actions.actions.explorer_copy(picker, item)
		local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
		-- 如果有选中项，批量复制副本到当前目录
		if #paths > 0 then
			local dir = picker:dir()
			local files, dirs = {}, {}
			for _, path in ipairs(paths) do
				local dest = util.get_backup_name(dir .. "/" .. vim.fn.fnamemodify(path, ":t"))
				util.copy_path(path, dest)
				local stat = uv.fs_stat(dest)
				if stat and stat.type == "directory" then
					table.insert(dirs, dest)
				else
					table.insert(files, dest)
				end
			end
			local Tree = require("snacks.explorer.tree")
			Tree:refresh(dir)
			Actions.update(picker, { target = dir })
			notify_files("已创建副本", files, dirs)
			return
		end

		-- 单个文件复制副本
		if not item then
			return
		end
		Snacks.input({
			prompt = "复制副本为：",
			default = vim.fn.fnamemodify(item.file, ":t"),
		}, function(value)
			if not value or value == "" then
				return
			end
			local dir = vim.fs.dirname(item.file)
			local to = vim.fs.normalize(dir .. "/" .. value)
			local actual_to = util.get_backup_name(to)

			if actual_to ~= to then
				Snacks.notify.warn("自动重命名为：\n" .. vim.fn.fnamemodify(actual_to, ":t"))
			end

			util.copy_path(item.file, actual_to)
			local Tree = require("snacks.explorer.tree")
			Tree:refresh(dir)
			Actions.update(picker, { target = actual_to })
			Snacks.notify.info("已复制副本：\n" .. actual_to)
		end)
	end

	--==============================================================================
	-- Action: 移动 (Move)
	--==============================================================================
	function Actions.actions.explorer_move(picker)
		local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
		if #paths == 0 then
			return
		end

		-- 单个文件移动
		if #paths == 1 then
			local from = paths[1]
			local current_dir = picker:dir()
			Snacks.input({
				prompt = "移动/重命名到：",
				default = current_dir .. "/" .. vim.fn.fnamemodify(from, ":t"),
			}, function(to)
				if not to or to == "" or to == from then
					return
				end
				to = vim.fs.normalize(to)
				if uv.fs_stat(to) then
					return Snacks.notify.warn("目标已存在")
				end

				Snacks.rename.rename_file({
					from = from,
					to = to,
					on_rename = function(new, old)
						local Tree = require("snacks.explorer.tree")
						Tree:refresh(vim.fs.dirname(old))
						Tree:refresh(vim.fs.dirname(new))
						Actions.update(picker, { target = new })
						Snacks.notify.info("已移动：\n" .. from .. "\n到：\n" .. to)
					end,
				})
			end)
			return
		end

		-- 批量移动
		local target = picker:dir()
		Snacks.picker.util.confirm("移动 " .. #paths .. " 个文件到当前目录？", function()
			local Tree = require("snacks.explorer.tree")
			local moved = {}
			for _, from in ipairs(paths) do
				local to = target .. "/" .. vim.fn.fnamemodify(from, ":t")
				if not uv.fs_stat(to) then
					pcall(Snacks.rename.rename_file, { from = from, to = to })
					table.insert(moved, to)
					Tree:refresh(vim.fs.dirname(from))
				end
			end
			Tree:refresh(target)
			Actions.update(picker, { target = target })
			notify_files("已移动", moved, {})
		end)
	end

	function Actions.actions.explorer_open(_, item)
		if item then
			vim.ui.open(item.file)
		end
	end
end

return M
