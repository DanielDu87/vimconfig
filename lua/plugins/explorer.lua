--==============================================================================
-- Snacks.nvim 配置
--==============================================================================
-- 配置文件浏览器和启动行为

return {
	-- LazyVim 默认会安装 snacks.nvim；这里用 opts 扩展配置
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			--==============================================================================
			-- 中文化 Explorer 操作提示
			--==============================================================================
			opts.picker = opts.picker or {}
			opts.picker.explorer = opts.picker.explorer or {}

			-- 覆盖 actions 以中文化提示信息
			local Actions = require("snacks.explorer.actions")
			local uv = vim.uv or vim.loop

			--==============================================================================
			-- 覆盖 copy_file 和 copy_path 函数，实现自动重命名和中文提示
			--==============================================================================
			local util = require("snacks.picker.util")

			-- 辅助函数：计算副本文件名
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

			-- 覆盖 copy_path
			function util.copy_path(from, to)
				if not uv.fs_stat(from) then
					Snacks.notify.error(("文件不存在：`%s`"):format(from))
					return
				end
				if Snacks.util.path_type(from) == "directory" then
					util.copy_dir(from, to)
				else
					util.copy_file(from, to)
				end
			end

			-- 覆盖 copy_file，实现自动重命名而不显示英文错误
			function util.copy_file(from, to)
				if vim.fn.filereadable(from) == 0 then
					Snacks.notify.error(("文件不可读：`%s`"):format(from))
					return
				end

				-- 如果目标文件已存在，自动重命名
				if uv.fs_stat(to) then
					to = util.get_backup_name(to)
				end

				local dir = vim.fs.dirname(to)
				vim.fn.mkdir(dir, "p")
				local ok, err = uv.fs_copyfile(from, to, { excl = true, ficlone = true })
				if not ok then
					Snacks.notify.error(("复制文件失败：\n- 从：`%s`\n- 到：`%s`\n%s"):format(from, to, err))
				end
			end

			-- 剪切（cut）- 标记文件为待剪切状态
			function Actions.actions.explorer_cut(picker)
				local files = {} ---@type string[]
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
				-- 使用特殊寄存器标记剪切操作（在寄存器值前加特殊前缀）
				vim.fn.setreg(vim.v.register or "+", value, "l")
				-- 使用全局变量标记为剪切模式
				_G.explorer_cut_mode = true
				local file_list = table.concat(files, "\n- ")
				Snacks.notify.info("已剪切 " .. #files .. " 个文件（粘贴后将删除原文件）：\n- " .. file_list)
			end

			-- 复制（yank）
			function Actions.actions.explorer_yank(picker)
				local files = {} ---@type string[]
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
				-- 清除剪切模式标记
				_G.explorer_cut_mode = false
				local file_list = table.concat(files, "\n- ")
				Snacks.notify.info("已复制 " .. #files .. " 个文件：\n- " .. file_list)
			end

			-- 粘贴
			function Actions.actions.explorer_paste(picker)
				local files = vim.split(vim.fn.getreg(vim.v.register or "+") or "", "\n", { plain = true })
				files = vim.tbl_filter(function(file)
					return file ~= "" and vim.fn.filereadable(file) == 1
				end, files)

				if #files == 0 then
					return Snacks.notify.warn(("`%s` 寄存器中没有文件"):format(vim.v.register or "+"))
				end
				local dir = picker:dir()

				-- 检查是否在剪切模式
				local is_cut = _G.explorer_cut_mode == true

				-- 剪切模式：移动文件
				if is_cut then
					local success_count = 0
					local failed_files = {}
					local moved_files = {}

					for _, file in ipairs(files) do
						local filename = vim.fn.fnamemodify(file, ":t")
						local target = vim.fs.normalize(dir .. "/" .. filename)

						-- 如果目标是同一位置，跳过
						if file == target then
							table.insert(failed_files, file .. "（已在目标位置）")
						elseif uv.fs_stat(target) then
							table.insert(failed_files, file .. "（目标已存在）")
						else
							local ok, err = pcall(Snacks.rename.rename_file, { from = file, to = target })
							if ok then
								success_count = success_count + 1
								table.insert(moved_files, file)
								Tree = require("snacks.explorer.tree")
								Tree:refresh(vim.fs.dirname(file))
							else
								table.insert(failed_files, file .. "（" .. (err or "未知错误") .. "）")
							end
						end
					end

					-- 清除剪切模式标记
					_G.explorer_cut_mode = false

					-- 刷新目标目录
					Tree = require("snacks.explorer.tree")
					Tree:refresh(dir)
					Tree:open(dir)
					Actions.update(picker, { target = dir })

					-- 显示结果
					if success_count > 0 then
						local moved_list = table.concat(moved_files, "\n- ")
						Snacks.notify.info("已移动 " .. success_count .. " 个文件到：\n- `" .. dir .. "`\n文件：\n- " .. moved_list)
					end
					if #failed_files > 0 then
						vim.schedule(function()
							Snacks.notify.warn("部分文件移动失败：\n- " .. table.concat(failed_files, "\n- "))
						end)
					end
					return
				end

				-- 复制模式：复制文件
				-- 检查是否在同目录粘贴，并计算副本名称
				local same_dir_info = {}
				local file_map = {} -- 记录原文件到副本文件的映射
				for _, file in ipairs(files) do
					local filename = vim.fn.fnamemodify(file, ":t")
					local target_path = vim.fs.normalize(dir .. "/" .. filename)
					local backup_name = Snacks.picker.util.get_backup_name(target_path)
					local backup_filename = vim.fn.fnamemodify(backup_name, ":t")

					file_map[file] = backup_name

					local file_dir = vim.fn.fnamemodify(file, ":p:h")
					if vim.fn.fnamemodify(file_dir, ":p") == vim.fn.fnamemodify(dir, ":p") then
						table.insert(same_dir_info, {
							original = filename,
							backup = backup_filename
						})
					end
				end

				-- 如果有同目录文件，给出提示（显示副本名称）
				if #same_dir_info > 0 then
					local info_list = {}
					for _, info in ipairs(same_dir_info) do
						if info.original == info.backup then
							table.insert(info_list, info.backup)
						else
							table.insert(info_list, info.original .. " → " .. info.backup)
						end
					end
					Snacks.notify.warn("检测到同目录粘贴，将创建副本：\n- " .. table.concat(info_list, "\n- "))
				end

				Snacks.picker.util.copy(files, dir)
				Tree = require("snacks.explorer.tree")
				Tree:refresh(dir)
				Tree:open(dir)
				Actions.update(picker, { target = dir })

				-- 构建成功提示：显示实际创建的副本名称
				local result_files = {}
				for _, file in ipairs(files) do
					table.insert(result_files, file_map[file])
				end
				local file_list = table.concat(result_files, "\n- ")
				Snacks.notify.info("已粘贴 " .. #files .. " 个文件：\n- " .. file_list)
			end

			-- 新建文件/目录
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
						Snacks.notify.warn("文件已存在：\n- `" .. path .. "`")
						return
					end
					local ok, err = pcall(vim.fn.mkdir, dir, "p")
					if not ok then
						Snacks.notify.error("创建目录失败：\n- " .. (err or "未知错误"))
						return
					end
					if is_file then
						local f, open_err = io.open(path, "w")
						if not f then
							Snacks.notify.error("创建文件失败：\n- " .. (open_err or "未知错误"))
							return
						end
						f:close()
					end
					Tree = require("snacks.explorer.tree")
					Tree:open(dir)
					Tree:refresh(dir)
					Actions.update(picker, { target = path })
					local msg_type = is_file and "文件" or "目录"
					Snacks.notify.info("已创建" .. msg_type .. "：\n- `" .. path .. "`")
				end)
			end

			-- 重命名文件
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

					-- 检查目标文件是否已存在
					if uv.fs_stat(new_path) then
						Snacks.notify.warn("目标文件已存在：\n- `" .. new_path .. "`")
						return
					end

					Snacks.rename.rename_file({
						from = item.file,
						to = new_path,
						on_rename = function(new, old)
							Tree = require("snacks.explorer.tree")
							Tree:refresh(vim.fs.dirname(old))
							Tree:refresh(vim.fs.dirname(new))
							Actions.update(picker, { target = new })
							Snacks.notify.info("已重命名为：\n- " .. new)
						end,
					})
				end)
			end

			-- 复制文件
			function Actions.actions.explorer_copy(picker, item)
				if not item then
					return Snacks.notify.warn("未选择文件")
				end
				---@type string[]
				local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
				-- 复制选中项
				if #paths > 0 then
					local dir = picker:dir()
					-- 检查同目录复制
					local same_dir_info = {}
					local file_map = {} -- 记录原文件到副本文件的映射
					for _, path in ipairs(paths) do
						local filename = vim.fn.fnamemodify(path, ":t")
						local target_path = vim.fs.normalize(dir .. "/" .. filename)
						local backup_name = Snacks.picker.util.get_backup_name(target_path)
						local backup_filename = vim.fn.fnamemodify(backup_name, ":t")

						file_map[path] = backup_name

						local file_dir = vim.fn.fnamemodify(path, ":p:h")
						if vim.fn.fnamemodify(file_dir, ":p") == vim.fn.fnamemodify(dir, ":p") then
							table.insert(same_dir_info, {
								original = filename,
								backup = backup_filename
							})
						end
					end
					-- 如果有同目录复制，显示副本名称
					if #same_dir_info > 0 then
						local info_list = {}
						for _, info in ipairs(same_dir_info) do
							if info.original == info.backup then
								table.insert(info_list, info.backup)
							else
								table.insert(info_list, info.original .. " → " .. info.backup)
							end
						end
						Snacks.notify.warn("检测到同目录复制，将创建副本：\n- " .. table.concat(info_list, "\n- "))
					end
					Snacks.picker.util.copy(paths, dir)
					picker.list:set_selected()
					Tree = require("snacks.explorer.tree")
					Tree:refresh(dir)
					Tree:open(dir)
					Actions.update(picker, { target = dir })
					-- 显示实际创建的副本名称
					local result_files = {}
					for _, path in ipairs(paths) do
						table.insert(result_files, file_map[path])
					end
					local file_list = table.concat(result_files, "\n- ")
					Snacks.notify.info("已复制 " .. #paths .. " 个文件：\n- " .. file_list)
					return
				end
				-- 复制单个文件到指定位置
				Snacks.input({
					prompt = "复制到：",
					default = vim.fn.fnamemodify(item.file, ":t"),
				}, function(value)
					if not value or value:find("^%s$") then
						return
					end
					local dir = vim.fs.dirname(item.file)
					local to = vim.fs.normalize(dir .. "/" .. value)
					-- 计算实际的目标文件名
					local actual_to = Snacks.picker.util.get_backup_name(to)
					-- 如果目标文件已存在，显示副本名称
					if uv.fs_stat(to) then
						local backup_filename = vim.fn.fnamemodify(actual_to, ":t")
						Snacks.notify.warn("目标文件已存在，将创建副本：\n- " .. backup_filename)
					end
					local ok, err = pcall(Snacks.picker.util.copy_path, item.file, to)
					if not ok then
						Snacks.notify.error("复制文件失败：\n- `" .. item.file .. "`\n- " .. (err or "未知错误"))
						return
					end
					Tree = require("snacks.explorer.tree")
					Tree:refresh(vim.fs.dirname(actual_to))
					Actions.update(picker, { target = actual_to })
					Snacks.notify.info("已复制文件到：\n- `" .. actual_to .. "`")
				end)
			end

			-- 移动/剪切文件
			function Actions.actions.explorer_move(picker)
				---@type string[]
				local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
				-- 如果没有选中文件，使用当前光标下的文件
				if #paths == 0 then
					local current = picker:current()
					if current then
						paths = { Snacks.picker.util.path(current) }
					else
						return Snacks.notify.warn("未选择文件")
					end
				end

				-- 单个文件：弹出输入框让用户输入目标路径（支持重命名）
				if #paths == 1 then
					local from = paths[1]
					local current_dir = picker:dir()
					local filename = vim.fn.fnamemodify(from, ":t")

					Snacks.input({
						prompt = "移动到：",
						default = current_dir .. "/" .. filename,
					}, function(value)
						if not value or value == "" or value == from then
							return
						end

						local to = vim.fs.normalize(value)

						-- 检查目标文件是否已存在
						if uv.fs_stat(to) then
							Snacks.notify.warn("目标文件已存在：\n- `" .. to .. "`")
							return
						end

						local ok, err = pcall(Snacks.rename.rename_file, { from = from, to = to })
						if not ok then
							Snacks.notify.error("移动失败 `" .. from .. "`：\n" .. (err or "未知错误"))
							return
						end

						Tree = require("snacks.explorer.tree")
						Tree:refresh(vim.fs.dirname(from))
						Tree:refresh(vim.fs.dirname(to))
						picker.list:set_selected()
						Actions.update(picker, { target = to })
						Snacks.notify.info("已移动文件：\n- `" .. from .. "`\n到：\n- `" .. to .. "`")
					end)
					return
				end

				-- 多个文件：移动到当前目录
				local target = picker:dir()
				local what = #paths .. " 个文件"
				local t = vim.fn.fnamemodify(target, ":p:~:.")

				Snacks.picker.util.confirm("是否移动 " .. what .. " 到 " .. t .. "？", function()
					for _, from in ipairs(paths) do
						local to = target .. "/" .. vim.fn.fnamemodify(from, ":t")
						local ok, err = pcall(Snacks.rename.rename_file, { from = from, to = to })
						if not ok then
							Snacks.notify.error("移动失败 `" .. from .. "`：\n" .. (err or "未知错误"))
						end
						Tree = require("snacks.explorer.tree")
						Tree:refresh(vim.fs.dirname(from))
					end
					Tree = require("snacks.explorer.tree")
					Tree:refresh(target)
					picker.list:set_selected()
					Actions.update(picker, { target = target })
					local file_list = table.concat(paths, "\n- ")
					Snacks.notify.info("已移动 " .. #paths .. " 个文件到：\n- `" .. target .. "`\n文件：\n- " .. file_list)
				end)
			end

			-- 删除文件
			function Actions.actions.explorer_del(picker)
				---@type string[]
				local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
				if #paths == 0 then
					return Snacks.notify.warn("未选择文件")
				end
				-- 确认对话框显示文件名
				local filenames = vim.tbl_map(function(p)
					local name = vim.fn.fnamemodify(p, ":t")
					-- 移除 macOS 符号链接末尾的 @ 符号
					return name:gsub("@$", "")
				end, paths)
				local msg
				if #paths == 1 then
					msg = "是否删除 " .. filenames[1] .. "？"
				else
					local filename_list = table.concat(filenames, "\n- ")
					msg = "是否删除 " .. #paths .. " 个文件？\n- " .. filename_list
				end
				Snacks.picker.util.confirm(msg, function()
					for _, path in ipairs(paths) do
						local ok, err = Actions.trash(path)
						if ok then
							Snacks.bufdelete({ file = path, force = true })
						else
							Snacks.notify.error("删除失败 `" .. path .. "`：\n" .. err)
						end
						Tree = require("snacks.explorer.tree")
						Tree:refresh(vim.fs.dirname(path))
					end
					picker.list:set_selected()
					Actions.update(picker)
					-- 成功提示显示完整路径
					local file_list = table.concat(paths, "\n- ")
					Snacks.notify.info("已删除 " .. #paths .. " 个文件：\n- " .. file_list)
				end)
			end

			-- 打开文件（用于系统默认程序打开）
			function Actions.actions.explorer_open(_, item)
				if item then
					local _, err = vim.ui.open(item.file)
					if err then
						Snacks.notify.error("打开文件失败 `" .. item.file .. "`：\n- " .. err)
					end
				end
			end

			--==============================================================================
			-- 添加 explorer 键映射
			--==============================================================================
			-- 根据源代码，应该使用 opts.picker.sources.explorer 而不是 opts.picker.explorer
			opts.picker = opts.picker or {}
			opts.picker.sources = opts.picker.sources or {}
			opts.picker.sources.explorer = opts.picker.sources.explorer or {}
			opts.picker.sources.explorer.win = opts.picker.sources.explorer.win or {}
			opts.picker.sources.explorer.win.list = opts.picker.sources.explorer.win.list or {}
			opts.picker.sources.explorer.win.list.keys = opts.picker.sources.explorer.win.list.keys or {}

			-- 设置 x 键映射到剪切操作
			opts.picker.sources.explorer.win.list.keys["x"] = { "explorer_cut", mode = { "n", "x" } }

			-- 修复从输入模式退出后按键识别问题：确保退出输入模式时焦点返回列表
			opts.picker.sources.explorer.win.input = opts.picker.sources.explorer.win.input or {}
			opts.picker.sources.explorer.win.input.keys = opts.picker.sources.explorer.win.input.keys or {}
			opts.picker.sources.explorer.win.input.keys["<Esc>"] = function(picker)
				-- 退出插入模式并聚焦到列表
				vim.cmd("stopinsert")
				picker.list:focus()
			end

			--==============================================================================
			-- 处理目录参数启动
			--==============================================================================
			-- 检测是否以目录参数启动
			local start_with_dir = false
			for _, a in ipairs(vim.fn.argv()) do
				if not vim.startswith(a, "-") and vim.fn.isdirectory(a) == 1 then
					start_with_dir = true
					vim.cmd("cd " .. vim.fn.fnamemodify(a, ":p"))
					break
				end
			end

			--==============================================================================
			-- 启动时自动打开 Explorer（仅当非目录参数启动时）
			--==============================================================================
			-- 只有在不以目录参数启动时才自动打开 Explorer
			if not start_with_dir then
				vim.api.nvim_create_autocmd("VimEnter", {
					group = vim.api.nvim_create_augroup("SnacksExplorerAutoStart", { clear = true }),
					once = true,
					callback = function()
						vim.schedule(function()
							local ok, Snacks = pcall(require, "snacks")
							if not ok or not Snacks.explorer then
								return
							end

							-- 检查是否已经有 Explorer 窗口
							local has_explorer = false
							for _, win in ipairs(vim.api.nvim_list_wins()) do
								local buf = vim.api.nvim_win_get_buf(win)
								local buf_name = vim.api.nvim_buf_get_name(buf)
								if buf_name:match("[Ee]xplorer") or buf_name:match("[Ss]nacks") or buf_name:match("picker") then
									has_explorer = true
									break
								end
							end

							if not has_explorer then
								local root = vim.g.root_dir
									or (_G.LazyVim and _G.LazyVim.root and _G.LazyVim.root.get and _G.LazyVim.root.get())
									or vim.fn.getcwd()
								Snacks.explorer.open({ cwd = root })

								-- 如果打开了文件，焦点回到文件窗口
								local argv = vim.fn.argv()
								local has_file = false
								for _, a in ipairs(argv) do
									if not vim.startswith(a, "-") and vim.fn.isdirectory(a) == 0 then
										has_file = true
										break
									end
								end

								if has_file then
									vim.schedule(function()
										vim.cmd("wincmd p") -- 切换到上一个窗口
									end)
								end
							end
						end)
					end,
					desc = "启动时自动打开 Snacks Explorer",
				})
			end
		end,
	},
}
