local M = {}

-- 模块内状态变量（替代全局变量），用于记录是否为剪切模式
local cut_mode = false

---@param Actions table Snacks explorer actions module
---@param Snacks table Snacks global object
function M.setup(Actions, Snacks)
	local uv = vim.uv or vim.loop
	local util = require("snacks.picker.util")

	--==============================================================================
	-- 辅助函数：计算副本文件名
	--==============================================================================
	-- 如果目标文件已存在，自动追加 ~1, ~2 等后缀
	-- 例如：test.lua -> test~1.lua
	function util.get_backup_name(to)
		if not uv.fs_stat(to) then
			return to
		end
		local counter = 1
		-- 分离文件名和扩展名
		local base, ext = to:match("^(.-)(%.[^.]+)$")
		if not base then
			base, ext = to, ""
		end
		local new_to = to
		-- 循环查找直到找到一个不存在的文件名
		while uv.fs_stat(new_to) do
			new_to = base .. "~" .. counter .. ext
			counter = counter + 1
		end
		return new_to
	end

	--==============================================================================
	-- 覆盖 copy_path：智能复制文件或目录
	--==============================================================================
	function util.copy_path(from, to)
		if not uv.fs_stat(from) then
			Snacks.notify.error(("文件不存在：`%s`"):format(from))
			return
		end
		-- 区分目录和文件调用不同的内部方法
		if Snacks.util.path_type(from) == "directory" then
			util.copy_dir(from, to)
		else
			util.copy_file(from, to)
		end
	end

	--==============================================================================
	-- 覆盖 copy_file：带自动重命名的文件复制
	--==============================================================================
	function util.copy_file(from, to)
		if vim.fn.filereadable(from) == 0 then
			Snacks.notify.error(("文件不可读：`%s`"):format(from))
			return
		end

		-- 如果目标文件已存在，自动计算新名称
		if uv.fs_stat(to) then
			to = util.get_backup_name(to)
		end

		-- 确保父目录存在
		local dir = vim.fs.dirname(to)
		vim.fn.mkdir(dir, "p")

		-- 执行复制
		local ok, err = uv.fs_copyfile(from, to, { excl = true, ficlone = true })
		if not ok then
			Snacks.notify.error(("复制文件失败：\n- 从：`%s`\n- 到：`%s`\n%s"):format(from, to, err))
		end
	end

	--==============================================================================
	-- Action: 剪切 (Cut)
	--==============================================================================
	function Actions.actions.explorer_cut(picker)
		local files = {}
		-- 视觉模式下获取选中项
		if vim.fn.mode():find("^[vV]") then
			picker.list:select()
		end
		-- 获取所有选中的文件路径
		for _, item in ipairs(picker:selected({ fallback = true })) do
			table.insert(files, Snacks.picker.util.path(item))
		end
		if #files == 0 then
			return Snacks.notify.warn("未选择文件")
		end
		-- 清除选择状态
		picker.list:set_selected()
		-- 将文件列表放入系统剪贴板（特殊标记格式）
		local value = table.concat(files, "\n")
		vim.fn.setreg(vim.v.register or "+", value, "l")
		-- 标记为剪切模式
		cut_mode = true

		-- 构建提示信息
		local msg_parts = { "已剪切 " .. #files .. " 个项：" }
		if #files <= 5 then
			for _, f in ipairs(files) do
				table.insert(msg_parts, "- " .. vim.fn.fnamemodify(f, ":t"))
			end
		else
			table.insert(msg_parts, "（粘贴后将移动原文件）")
		end
		Snacks.notify.info(table.concat(msg_parts, "\n"))
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
		-- 标记为非剪切模式
		cut_mode = false

		Snacks.notify.info("已复制 " .. #files .. " 个项到剪贴板")
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
			-- 计算完整路径
			local path = vim.fs.normalize(picker:dir() .. "/" .. value)
			local is_file = value:sub(-1) ~= "/"
			local dir = is_file and vim.fs.dirname(path) or path

			if is_file and uv.fs_stat(path) then
				return Snacks.notify.warn("文件已存在：\n" .. path)
			end

			-- 创建目录结构
			local ok, err = pcall(vim.fn.mkdir, dir, "p")
			if not ok then
				return Snacks.notify.error("创建目录失败：\n" .. (err or "未知错误"))
			end

			-- 如果是文件，创建空文件
			if is_file then
				local f, open_err = io.open(path, "w")
				if not f then
					return Snacks.notify.error("创建文件失败：\n" .. (open_err or "未知错误"))
				end
				f:close()
			end

			-- 刷新并聚焦
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
			if not new_name or new_name:find("^%s$") or new_name == old_name then
				return
			end
			local new_path = vim.fs.normalize(vim.fs.dirname(item.file) .. "/" .. new_name)

			if uv.fs_stat(new_path) then
				return Snacks.notify.warn("目标文件已存在，操作取消")
			end

			-- 执行重命名
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
	-- Action: 复制副本 (Duplicate/Copy)
	--==============================================================================
	function Actions.actions.explorer_copy(picker, item)
		-- 情况1：复制选中项到当前目录
		local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
		if #paths > 0 then
			local dir = picker:dir()
			-- 使用 Snacks 的 copy 方法，它会调用我们覆盖的 util.copy_file (带自动重命名)
			Snacks.picker.util.copy(paths, dir)

			picker.list:set_selected()
			local Tree = require("snacks.explorer.tree")
			Tree:refresh(dir)
			Tree:open(dir)
			Actions.update(picker, { target = dir })
			Snacks.notify.info("已创建 " .. #paths .. " 个副本")
			return
		end

		if not item then
			return
		end

		-- 情况2：复制单个文件并重命名
		Snacks.input({
			prompt = "复制副本为：",
			default = vim.fn.fnamemodify(item.file, ":t"),
		}, function(value)
			if not value or value:find("^%s$") then
				return
			end

			local dir = vim.fs.dirname(item.file)
			local to = vim.fs.normalize(dir .. "/" .. value)

			-- 自动重命名避免冲突
			local actual_to = util.get_backup_name(to)
			if actual_to ~= to then
				Snacks.notify.warn("目标存在，自动重命名为：\n" .. vim.fn.fnamemodify(actual_to, ":t"))
			end

			-- 执行复制
			util.copy_path(item.file, actual_to)

			local Tree = require("snacks.explorer.tree")
			Tree:refresh(dir)
			Actions.update(picker, { target = actual_to })
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

		-- 移动单个文件：带重命名功能
		if #paths == 1 then
			local from = paths[1]
			local current_dir = picker:dir()
			local filename = vim.fn.fnamemodify(from, ":t")

			Snacks.input({
				prompt = "移动/重命名到：",
				default = current_dir .. "/" .. filename,
			}, function(value)
				if not value or value == "" or value == from then
					return
				end
				local to = vim.fs.normalize(value)

				if uv.fs_stat(to) then
					return Snacks.notify.warn("目标已存在，请先删除或改名")
				end

				Snacks.rename.rename_file({
					from = from,
					to = to,
					on_rename = function(new, old)
						local Tree = require("snacks.explorer.tree")
						Tree:refresh(vim.fs.dirname(old))
						Tree:refresh(vim.fs.dirname(new))
						Actions.update(picker, { target = new })
						Snacks.notify.info("操作成功")
					end,
				})
			end)
			return
		end

		-- 移动多个文件到当前目录 (通常用于从其他目录拖过来)
		local target = picker:dir()
		local what = #paths .. " 个文件"
		local t = vim.fn.fnamemodify(target, ":p:~:.")

		Snacks.picker.util.confirm("是否移动 " .. what .. " 到 " .. t .. "？", function()
			local Tree = require("snacks.explorer.tree")
			for _, from in ipairs(paths) do
				local to = target .. "/" .. vim.fn.fnamemodify(from, ":t")
				-- 简单的冲突检测：如果存在则跳过
				if uv.fs_stat(to) then
					Snacks.notify.warn("跳过已存在文件：\n" .. vim.fn.fnamemodify(to, ":t"))
				else
					pcall(Snacks.rename.rename_file, { from = from, to = to })
					Tree:refresh(vim.fs.dirname(from))
				end
			end
			Tree:refresh(target)
			picker.list:set_selected()
			Actions.update(picker, { target = target })
			Snacks.notify.info("批量移动完成")
		end)
	end

	--==============================================================================
	-- Action: 粘贴 (Paste)
	--==============================================================================
	function Actions.actions.explorer_paste(picker)
		-- 从系统寄存器获取文件列表
		local files = vim.split(vim.fn.getreg(vim.v.register or "+") or "", "\n", { plain = true })
		files = vim.tbl_filter(function(f)
			return f ~= "" and (vim.fn.filereadable(f) == 1 or vim.fn.isdirectory(f) == 1)
		end, files)

		if #files == 0 then
			return Snacks.notify.warn("剪贴板中没有有效文件")
		end

		local dir = picker:dir()
		local is_move = cut_mode
		local count = 0

		for _, file in ipairs(files) do
			local filename = vim.fn.fnamemodify(file, ":t")
			local target = vim.fs.normalize(dir .. "/" .. filename)

			-- 检查是否原地操作
			if file == target then
				-- 原地复制：创建副本 (filename~1)
				if not is_move then
					local backup = util.get_backup_name(target)
					util.copy_path(file, backup)
					count = count + 1
				end
				-- 原地剪切：不做任何事
			else
				-- 异地操作
				-- 如果目标存在，自动重命名避免冲突
				if uv.fs_stat(target) then
					target = util.get_backup_name(target)
					Snacks.notify.warn(
						"检测到同名，已自动重命名为：\n" .. vim.fn.fnamemodify(target, ":t")
					)
				end

				-- 执行操作
				if is_move then
					local ok = vim.fn.rename(file, target)
					if ok == 0 then
						count = count + 1
					end
				else
					util.copy_path(file, target)
					count = count + 1
				end
			end
		end

		-- 如果是剪切操作，完成后重置状态
		if is_move then
			cut_mode = false
			-- 清空剪贴板标记
			vim.fn.setreg(vim.v.register or "+", "", "l")
		end

		-- 刷新界面
		local Tree = require("snacks.explorer.tree")
		Tree:refresh(dir)
		Actions.update(picker, { target = dir })

		local action_name = is_move and "移动" or "粘贴"
		Snacks.notify.info("已" .. action_name .. " " .. count .. " 个项")
	end

	--==============================================================================
	-- Action: 删除 (Delete)
	--==============================================================================
	function Actions.actions.explorer_del(picker)
		local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
		if #paths == 0 then
			return
		end

		-- 弹出确认框
		local msg = "是否永久删除 " .. #paths .. " 个项？\n(此操作不可撤销)"
		Snacks.picker.util.confirm(msg, function()
			for _, path in ipairs(paths) do
				local ok, err = Actions.trash(path)
				if ok then
					-- 同时删除对应的 buffer
					Snacks.bufdelete({ file = path, force = true })
				else
					Snacks.notify.error("删除失败：\n" .. (err or "未知错误"))
				end
			end
			-- 刷新
			local Tree = require("snacks.explorer.tree")
			Tree:refresh(picker:dir())
			Actions.update(picker)
			Snacks.notify.info("已删除 " .. #paths .. " 个项")
		end)
	end

	--==============================================================================
	-- Action: 打开文件 (Open)
	--==============================================================================
	function Actions.actions.explorer_open(_, item)
		if item then
			-- 使用系统默认程序打开 (xdg-open / open / start)
			vim.ui.open(item.file)
		end
	end
end

return M
