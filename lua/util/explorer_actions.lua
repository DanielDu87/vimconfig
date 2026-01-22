local M = {}

-- 模块级状态变量：记录是否处于剪切模式（跨函数持久化）
local cut_mode = false

---@param Actions table Snacks explorer actions module
---@param Snacks table Snacks global object
function M.setup(Actions, Snacks)
	local uv = vim.uv or vim.loop
	local util = require("snacks.picker.util")

	--==============================================================================
	-- 辅助函数：获取选中的路径
	-- 处理 Visual 模式选择，如果没有选择则回退到当前光标项
	--==============================================================================
	local function get_selected_paths(picker)
		local paths = {}
		-- 如果处于 Visual 模式，强制同步选区
		if vim.fn.mode():find("^[vV]") then
			picker.list:select()
		end
		-- 获取所有选中项，如果未选中则使用当前项 (fallback=true)
		for _, item in ipairs(picker:selected({ fallback = true })) do
			table.insert(paths, Snacks.picker.util.path(item))
		end
		return paths
	end

	--==============================================================================
	-- 辅助函数：生成备份文件名
	-- 示例: foo.txt -> foo~1.txt -> foo~2.txt
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
		local new_to
		repeat
			new_to = ("%s~%d%s"):format(base, counter, ext)
			counter = counter + 1
		until not uv.fs_stat(new_to)
		return new_to
	end

	--==============================================================================
	-- 辅助函数：强健的复制功能 (文件与目录)
	-- 使用系统 `cp` 命令以获得最佳性能和递归支持
	--==============================================================================
	function util.copy_path(from, to)
		if not uv.fs_stat(from) then
			Snacks.notify.error(("源文件不存在：`%s`"):format(from))
			return false
		end

		-- 使用系统 `cp` 命令
		-- -R: 递归复制目录
		-- -p: 保留文件属性 (时间戳、权限等)
		local cmd = { "cp", "-R", "-p", from, to }

		-- 同步执行
		local result = vim.system(cmd, { text = true }):wait()

		if result.code ~= 0 then
			Snacks.notify.error(("复制失败：\n- 从：`%s`\n- 到：`%s`\n\n%s"):format(from, to, result.stderr))
			return false
		end
		return true
	end

	--==============================================================================
	-- 辅助函数：操作结果通知
	--==============================================================================
	local function notify_files(action, files, dirs, extra_msg)
		local msg_parts = {}
		local function add_list(label, list)
			if #list > 0 then
				table.insert(msg_parts, ("%s %d 个%s："):format(action, #list, label))
				for i = 1, math.min(#list, 10) do
					-- 使用完整路径，不再使用 :t 截取文件名
					table.insert(msg_parts, "- " .. list[i])
				end
				if #list > 10 then
					table.insert(msg_parts, ("... 等 %d 项"):format(#list - 10))
				end
			end
		end

		add_list("文件", files)
		add_list("目录", dirs)

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
		local paths = get_selected_paths(picker)
		if #paths == 0 then
			return Snacks.notify.warn("未选择文件")
		end

		picker.list:set_selected() -- 清除 UI 上的选择状态
		vim.fn.setreg(vim.v.register or "+", table.concat(paths, "\n"), "l")
		cut_mode = true

		local files, dirs = {}, {}
		for _, path in ipairs(paths) do
			local stat = uv.fs_stat(path)
			if stat and stat.type == "directory" then
				table.insert(dirs, path)
			else
				table.insert(files, path)
			end
		end

		notify_files("已剪切", files, dirs, "(将在粘贴时移动原文件)")
	end

	--==============================================================================
	-- Action: 复制 (Yank)
	--==============================================================================
	function Actions.actions.explorer_yank(picker)
		local paths = get_selected_paths(picker)
		if #paths == 0 then
			return Snacks.notify.warn("未选择文件")
		end

		picker.list:set_selected() -- 清除 UI 上的选择状态
		vim.fn.setreg(vim.v.register or "+", table.concat(paths, "\n"), "l")
		cut_mode = false

		local files, dirs = {}, {}
		for _, path in ipairs(paths) do
			local stat = uv.fs_stat(path)
			if stat and stat.type == "directory" then
				table.insert(dirs, path)
			else
				table.insert(files, path)
			end
		end

		notify_files("已复制", files, dirs)
	end

	--==============================================================================
	-- Action: 粘贴 (Paste)
	--==============================================================================
	function Actions.actions.explorer_paste(picker)
		local reg_content = vim.fn.getreg(vim.v.register or "+") or ""
		local sources = vim.split(reg_content, "\n", { plain = true })
		-- 过滤无效路径
		sources = vim.tbl_filter(function(f)
			return f ~= "" and (vim.fn.filereadable(f) == 1 or vim.fn.isdirectory(f) == 1)
		end, sources)

		if #sources == 0 then
			return Snacks.notify.warn("剪贴板为空或包含无效路径")
		end

		local dest_dir = picker:dir()
		local is_move = cut_mode
		local processed_files, processed_dirs = {}, {}
		local renamed_items = {}

		for _, from in ipairs(sources) do
			local basename = vim.fn.fnamemodify(from, ":t")
			local to = vim.fs.normalize(dest_dir .. "/" .. basename)

			-- 特殊处理：如果尝试将目录粘贴到自己里面（例如光标聚焦在目录上时）
			-- 强制视为在当前位置创建副本（触发下面的 Case 1 逻辑）
			if vim.fs.normalize(from) == vim.fs.normalize(dest_dir) then
				to = from
			end

			local stat = uv.fs_stat(from)
			local is_dir = stat and stat.type == "directory"
			local success = false

			-- 情况 1: 源路径和目标路径相同
			if from == to then
				if is_move then
					-- 剪切到原位置：无效操作，跳过
					success = false
				else
					-- 复制到原位置：创建副本
					local backup = util.get_backup_name(to)
					if util.copy_path(from, backup) then
						table.insert(
							renamed_items,
							vim.fn.fnamemodify(from, ":t") .. " -> " .. vim.fn.fnamemodify(backup, ":t")
						)
						to = backup -- 更新目标以便统计
						success = true
					end
				end
			else
				-- 情况 2: 异地操作
				-- 如果目标已存在，则重命名目标 (备份策略)
				if uv.fs_stat(to) then
					local new_to = util.get_backup_name(to)
					table.insert(
						renamed_items,
						vim.fn.fnamemodify(from, ":t") .. " -> " .. vim.fn.fnamemodify(new_to, ":t")
					)
					to = new_to
				end

				if is_move then
					local res = vim.fn.rename(from, to)
					if res == 0 then
						success = true
					else
						Snacks.notify.error(("移动失败：\n%s -> %s"):format(from, to))
					end
				else
					if util.copy_path(from, to) then
						success = true
					end
				end
			end

			if success then
				if is_dir then
					table.insert(processed_dirs, to)
				else
					table.insert(processed_files, to)
				end
			end
		end

		if is_move then
			cut_mode = false
			vim.fn.setreg(vim.v.register or "+", "", "l") -- 移动后清空剪贴板
		end

		-- 刷新并通知
		local Tree = require("snacks.explorer.tree")
		Tree:refresh(dest_dir)
		Actions.update(picker, { target = dest_dir })

		local extra_msg
		if #renamed_items > 0 then
			extra_msg = "\n已自动重命名：\n- " .. table.concat(renamed_items, "\n- ")
		end

		notify_files(is_move and "已移动" or "已粘贴", processed_files, processed_dirs, extra_msg)
	end

	--==============================================================================
	-- Action: 删除 (Delete)
	--==============================================================================
	function Actions.actions.explorer_del(picker)
		local paths = get_selected_paths(picker)
		if #paths == 0 then
			return
		end

		local init_dir = vim.fn.getcwd()
		for _, path in ipairs(paths) do
			if vim.fs.normalize(path) == vim.fs.normalize(init_dir) then
				return Snacks.notify.warn("不能删除项目根目录")
			end
		end

		-- 分别收集文件和目录以便统计和排序显示
		local dirs, files = {}, {}
		local temp_files, temp_dirs = {}, {}

		for _, path in ipairs(paths) do
			local name = path -- 使用完整路径
			local stat = uv.fs_stat(path)
			if stat and stat.type == "directory" then
				table.insert(dirs, path)
				table.insert(temp_dirs, name .. " [目录]")
			else
				table.insert(files, path)
				table.insert(temp_files, name)
			end
		end

		-- 合并预览行：先文件后目录
		local preview_lines = {}
		for _, f in ipairs(temp_files) do
			table.insert(preview_lines, f)
		end
		for _, d in ipairs(temp_dirs) do
			table.insert(preview_lines, d)
		end

		local function get_confirm_text()
			local parts = {}
			if #dirs > 0 then
				table.insert(parts, #dirs .. " 个目录")
			end
			if #files > 0 then
				table.insert(parts, #files .. " 个文件")
			end
			return "确认删除 " .. table.concat(parts, " 和 ") .. "？"
		end

		-- 统一的对话框宽度，确保预览框和确认框对齐且足够显示路径
		local dialog_width = 60

		-- 创建预览窗口
		local max_h = 15
		-- 如果列表太长则截断
		if #preview_lines > max_h then
			local total = #preview_lines
			preview_lines = { unpack(preview_lines, 1, max_h) }
			table.insert(preview_lines, ("... 还有 %d 项"):format(total - max_h))
		end

		-- 左对齐并添加少量边距，不再居中（完整路径居中不好看）
		for i, line in ipairs(preview_lines) do
			preview_lines[i] = "  " .. line
		end

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, preview_lines)
		vim.bo[buf].modifiable = false

		-- 计算浮动窗口位置 (居中显示)
		local ui = vim.api.nvim_list_uis()[1]
		local screen_w = ui and ui.width or vim.o.columns
		local screen_h = ui and ui.height or vim.o.lines
		local win_height = #preview_lines
		local confirm_height = 7 -- 确认框高度
		local confirm_start_row = math.floor((screen_h - confirm_height) / 2)
		local row = confirm_start_row + confirm_height + 2 -- 偏移到确认框下方
		local col = math.floor((screen_w - dialog_width) / 2)

		local preview_win = vim.api.nvim_open_win(buf, false, {
			relative = "editor",
			row = row,
			col = col,
			width = dialog_width,
			height = win_height,
			style = "minimal",
			border = "rounded",
			zindex = 50,
		})
		-- 设置预览窗口背景透明，避免遮挡
		vim.wo[preview_win].winblend = 0
		vim.wo[preview_win].winhl = "Normal:NormalFloat,NormalNC:NormalFloat"

		-- 确认对话框
		Snacks.picker.select({ "取消", "删除" }, {
			prompt = get_confirm_text(),
			snacks = {
				layout = {
					preview = false,
					layout = {
						box = "vertical",
						width = dialog_width,
						min_width = dialog_width,
						height = 7,
						title = get_confirm_text(), -- 标题放在这里
						title_pos = "center",
						{ win = "input", height = 1, border = "rounded" },
						{ win = "list", border = "rounded" },
					},
				},
			},
		}, function(_, idx)
			-- 关闭预览窗口
			if preview_win and vim.api.nvim_win_is_valid(preview_win) then
				vim.api.nvim_win_close(preview_win, true)
			end

			if idx == 2 then
				-- 执行删除
				local deleted_files, deleted_dirs = {}, {}
				for _, path in ipairs(paths) do
					-- 检查文件是否存在，避免对不存在的文件调用 trash
					local stat = uv.fs_stat(path)
					if not stat then
						Snacks.notify.warn("文件已不存在，跳过删除：" .. path)
					else
						local is_dir = (stat.type == "directory")
						-- 尝试使用 Actions.trash，如果失败可能需要回退逻辑(此处假设 Snacks 已配置 trash)
						local ok, err = Actions.trash(path)

						-- 强制关闭相关 buffer
						Snacks.bufdelete({ file = path, force = true })

						if ok then
							if is_dir then
								table.insert(deleted_dirs, path)
							else
								table.insert(deleted_files, path)
							end
						else
							Snacks.notify.error("删除失败：" .. (err or path))
						end
					end
				end

				local Tree = require("snacks.explorer.tree")
				Tree:refresh(picker:dir())
				Actions.update(picker)
				notify_files("已删除", deleted_files, deleted_dirs)
			end
		end)
	end

	--==============================================================================
	-- Action: 新建文件/目录 (Add)
	--==============================================================================
	function Actions.actions.explorer_add(picker)
		Snacks.input({
			prompt = "新建文件/目录 (目录以 / 结尾)：",
		}, function(value)
			if not value or value:match("^%s*$") then
				return
			end

			local dir = picker:dir()
			local path = vim.fs.normalize(dir .. "/" .. value)
			local is_dir = value:sub(-1) == "/"

			if uv.fs_stat(path) then
				return Snacks.notify.warn("路径已存在：\n" .. path)
			end

			-- 创建父目录 (如果需要)
			local target_dir = is_dir and path or vim.fs.dirname(path)
			vim.fn.mkdir(target_dir, "p")

			if not is_dir then
				local f = io.open(path, "w")
				if f then
					f:close()
				end
			end

			-- 刷新并展开
			local Tree = require("snacks.explorer.tree")
			Tree:open(target_dir) -- 展开到目标目录
			Tree:refresh(target_dir)
			Actions.update(picker, { target = path })

			Snacks.notify.info("已创建：" .. path)

			-- 自动在编辑器中打开新文件
			if not is_dir then
				vim.schedule(function()
					local explorer_win = vim.api.nvim_get_current_win()

					-- 查找合适的编辑器窗口（非 Explorer）
					local function find_editor_window()
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							if win ~= explorer_win then
								local buf = vim.api.nvim_win_get_buf(win)
								local ft = vim.bo[buf].filetype
								-- 排除 Explorer 和其他特殊窗口
								if ft ~= "snacks_explorer" and ft ~= "snacks_picker" and ft ~= "snacks_input" then
									return win
								end
							end
						end
						return nil
					end

					local target_win = find_editor_window()

					if target_win then
						-- 在现有编辑器窗口中打开文件
						vim.api.nvim_set_current_win(target_win)
						vim.cmd.edit(vim.fn.fnameescape(path))
						vim.cmd("startinsert")
					else
						-- 没有合适的编辑器窗口，临时禁用 equalalways 避免布局抖动
						local old_ea = vim.o.equalalways
						vim.o.equalalways = false
						-- 从 Explorer 窗口创建一个垂直分割
						vim.api.nvim_set_current_win(explorer_win)
						vim.cmd("vsplit")
						vim.cmd.edit(vim.fn.fnameescape(path))
						vim.cmd("startinsert")
						-- 恢复 equalalways
						vim.o.equalalways = old_ea
					end
				end)
			end
		end)
	end

	--==============================================================================
	-- Action: 重命名 (Rename)
	--==============================================================================
	function Actions.actions.explorer_rename(picker, item)
		if not item then
			return
		end
		local old_name = vim.fn.fnamemodify(item.file, ":t")
		Snacks.input({
			prompt = "重命名：",
			default = old_name,
		}, function(new_name)
			if not new_name or new_name == "" or new_name == old_name then
				return
			end

			local dir = vim.fs.dirname(item.file)
			local new_path = vim.fs.normalize(dir .. "/" .. new_name)

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
					Snacks.notify.info("已重命名为：" .. new_name)
				end,
			})
		end)
	end

	--==============================================================================
	-- Action: 创建副本 (Duplicate)
	--==============================================================================
	function Actions.actions.explorer_copy(picker, item)
		-- 支持多选
		local paths = get_selected_paths(picker)

		-- 如果没有多选，则使用当前光标下的项
		if #paths == 0 and item then
			table.insert(paths, item.file)
		end

		if #paths == 0 then
			return
		end

		-- 如果是单个文件，询问新名称
		if #paths == 1 then
			local from = paths[1]
			Snacks.input({
				prompt = "创建副本为：",
				default = vim.fn.fnamemodify(from, ":t"),
			}, function(value)
				if not value or value == "" then
					return
				end
				local dir = vim.fs.dirname(from)
				local to = vim.fs.normalize(dir .. "/" .. value)
				local final_to = util.get_backup_name(to)

				if util.copy_path(from, final_to) then
					local Tree = require("snacks.explorer.tree")
					Tree:refresh(dir)
					Actions.update(picker, { target = final_to })
					Snacks.notify.info("已创建副本：" .. vim.fn.fnamemodify(final_to, ":t"))
				end
			end)
			return
		end

		-- 批量创建副本 (自动命名)
		local dir = picker:dir()
		local processed = {}
		for _, path in ipairs(paths) do
			local name = vim.fn.fnamemodify(path, ":t")
			local to = util.get_backup_name(dir .. "/" .. name)
			if util.copy_path(path, to) then
				table.insert(processed, to)
			end
		end

		local Tree = require("snacks.explorer.tree")
		Tree:refresh(dir)
		Actions.update(picker, { target = dir })
		notify_files("已创建副本", processed, {}, nil)
	end

	--==============================================================================
	-- Action: 移动 (Move)
	--==============================================================================
	function Actions.actions.explorer_move(picker)
		local paths = get_selected_paths(picker)
		if #paths == 0 then
			return
		end

		if #paths == 1 then
			local from = paths[1]
			Snacks.input({
				prompt = "移动/重命名到：",
				default = picker:dir() .. "/" .. vim.fn.fnamemodify(from, ":t"),
			}, function(to)
				if not to or to == "" or to == from then
					return
				end
				o = vim.fs.normalize(to)
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
						Snacks.notify.info("已移动到：" .. to)
					end,
				})
			end)
			return
		end

		-- 批量移动到当前目录
		local target_dir = picker:dir()
		Snacks.picker.util.confirm("移动 " .. #paths .. " 项到 " .. target_dir .. "？", function()
			local moved = {}
			for _, from in ipairs(paths) do
				local to = target_dir .. "/" .. vim.fn.fnamemodify(from, ":t")
				if not uv.fs_stat(to) then
					if vim.fn.rename(from, to) == 0 then
						table.insert(moved, to)
					end
				end
			end
			local Tree = require("snacks.explorer.tree")
			-- 刷新目标目录并在 UI 上更新
			Tree:refresh(target_dir)
			Actions.update(picker, { target = target_dir })
			notify_files("已移动", moved, {}, nil)
		end)
	end

	function Actions.actions.explorer_open(_, item)
		if item then
			vim.ui.open(item.file)
		end
	end
end

return M
