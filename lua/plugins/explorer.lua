--==============================================================================
-- Snacks.nvim Explorer 配置
--==============================================================================
-- 配置文件浏览器和启动行为

return {
	{
		"snacks.nvim",
		opts = function(_, opts)
			--==============================================================================
			-- 一劳永逸锁定 Snacks 侧边栏宽度
			--==============================================================================
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "snacks_picker*" },
				callback = function()
					vim.wo.winfixwidth = true
				end,
			})

			--==============================================================================
			-- 浮动窗口边框配置
			--==============================================================================
			opts.terminal = opts.terminal or {}
			opts.terminal.border = "rounded"
			opts.styles = opts.styles or {}
			opts.styles.float = opts.styles.float or {}
			opts.styles.float.border = "rounded"
			opts.styles.float.backdrop = 100

			--==============================================================================
			-- 中文化 Explorer 操作提示
			--==============================================================================
			opts.picker = opts.picker or {}
			opts.picker.explorer = opts.picker.explorer or {}

			--==============================================================================
			-- Explorer 宽度持久化配置
			--==============================================================================
			local width_file = vim.fn.stdpath("config") .. "/.explorer_width"

			-- 读取保存的宽度
			local function load_width()
				local f = io.open(width_file, "r")
				if f then
					local content = f:read("*a")
					f:close()
					return tonumber(content) or 30
				end
				return 30
			end

			-- 配置 Explorer 布局（使用官方推荐方式）
			-- 参考: https://github.com/folke/snacks.nvim/discussions/2139
			opts.picker.sources = opts.picker.sources or {}
			opts.picker.sources.explorer = opts.picker.sources.explorer or {}
			opts.picker.sources.explorer.layout = function()
				return {
					preset = "sidebar",
					preview = false,
					layout = {
						width = load_width(),
						-- 锁定宽度，防止窗口重排时被拉伸
						win_options = { winfixwidth = true },
					},
				}
			end

			--==============================================================================
			-- Explorer 宽度持久化配置（带防抖）
			--==============================================================================
			local width_save_timer = nil
			local function save_width_debounced(width)
				-- 取消之前的定时器
				if width_save_timer then
					width_save_timer:stop()
					width_save_timer:close()
				end
				-- 创建新的定时器（500ms 后执行）
				width_save_timer = vim.loop.new_timer()
				width_save_timer:start(500, 0, vim.schedule_wrap(function()
					local f = io.open(width_file, "w")
					if f then
						f:write(tostring(width))
						f:close()
					end
					width_save_timer:close()
					width_save_timer = nil
				end))
			end

			-- 使用 autocmd 在窗口调整大小时保存宽度（带防抖）
			vim.api.nvim_create_autocmd("WinResized", {
				group = vim.api.nvim_create_augroup("SnacksExplorerWidth", { clear = true }),
				callback = function(ev)
					-- 检查是否有 explorer picker 在运行
					local ok, pickers = pcall(function()
						return require("snacks.picker").get({ source = "explorer" })
					end)
					if not ok or not pickers or #pickers == 0 then
						return
					end
					-- 获取第一个 explorer picker
					local picker = pickers[1]
					if picker.closed then
						return
					end
					-- 延迟保存当前宽度
					local ok2, size = pcall(function()
						return picker.layout.root:size()
					end)
					if ok2 and size and size.width then
						save_width_debounced(size.width)
					end
				end,
			})

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
				-- 区分文件和目录显示
				local cut_dirs = {}
				local cut_files = {}
				for _, path in ipairs(files) do
					local stat = uv.fs_stat(path)
					if stat and stat.type == "directory" then
						table.insert(cut_dirs, path)
					else
						table.insert(cut_files, path)
					end
				end
				local msg_parts = {}
				if #cut_dirs > 0 then
					table.insert(msg_parts, "已剪切 " .. #cut_dirs .. " 个目录：\n- " .. table.concat(cut_dirs, "\n- "))
				end
				if #cut_files > 0 then
					table.insert(msg_parts, "已剪切 " .. #cut_files .. " 个文件：\n- " .. table.concat(cut_files, "\n- "))
				end
				Snacks.notify.info(table.concat(msg_parts, "\n") .. "\n（粘贴后将删除原文件）")
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
				-- 区分文件和目录显示
				local file_names = {}
				local dir_names = {}
				for _, path in ipairs(files) do
					local stat = uv.fs_stat(path)
					if stat and stat.type == "directory" then
						table.insert(dir_names, path)
					else
						table.insert(file_names, path)
					end
				end
				local msg_parts = {}
				if #dir_names > 0 then
					table.insert(msg_parts, "已复制 " .. #dir_names .. " 个目录：\n- " .. table.concat(dir_names, "\n- "))
				end
				if #file_names > 0 then
					table.insert(msg_parts, "已复制 " .. #file_names .. " 个文件：\n- " .. table.concat(file_names, "\n- "))
				end
				Snacks.notify.info(table.concat(msg_parts, "\n"))
			end

			-- 粘贴
			function Actions.actions.explorer_paste(picker)
				local files = vim.split(vim.fn.getreg(vim.v.register or "+") or "", "\n", { plain = true })
				files = vim.tbl_filter(function(file)
					return file ~= "" and (vim.fn.filereadable(file) == 1 or vim.fn.isdirectory(file) == 1)
				end, files)

				if #files == 0 then
					return Snacks.notify.warn(("`%s` 寄存器中没有文件"):format(vim.v.register or "+"))
				end
				local dir = picker:dir()

				-- 检查是否在剪切模式
				local is_cut = _G.explorer_cut_mode == true

				-- 检查同名文件
				local conflicts = {}
				local no_conflicts = {}
				for _, file in ipairs(files) do
					local filename = vim.fn.fnamemodify(file, ":t")
					local target = vim.fs.normalize(dir .. "/" .. filename)
					if uv.fs_stat(target) then
						table.insert(conflicts, { from = file, to = target, name = filename })
					else
						table.insert(no_conflicts, file)
					end
				end

				-- 如果没有冲突，直接执行
				if #conflicts == 0 then
					-- 执行粘贴操作（无冲突情况）
					local function do_paste(file_list, is_move)
						local success_count = 0
						local failed_files = {}
						local processed_files = {}

						for _, file in ipairs(file_list) do
							local filename = vim.fn.fnamemodify(file, ":t")
							local target = vim.fs.normalize(dir .. "/" .. filename)

							if file == target then
								table.insert(failed_files, file .. "（已在目标位置）")
							else
								local ok, err
								if is_move then
									-- 使用系统命令移动文件（mv 本身就是递归的，不需要 -R）
									local full_cmd = "mv -- " .. vim.fn.shellescape(file) .. " " .. vim.fn.shellescape(dir)
									local result = vim.fn.system(full_cmd)
									if vim.v.shell_error == 0 then
										ok = true
									else
										ok, err = false, result
									end
								else
									-- 复制模式（cp 需要 -R 来递归复制目录）
									local recursive = vim.fn.isdirectory(file) == 1 and " -R" or ""
									local full_cmd = "cp" .. recursive .. " -- " .. vim.fn.shellescape(file) .. " " .. vim.fn.shellescape(dir)
									local result = vim.fn.system(full_cmd)
									if vim.v.shell_error == 0 then
										ok = true
									else
										ok, err = false, result
									end
								end

								if ok then
									success_count = success_count + 1
									table.insert(processed_files, file)
									Tree = require("snacks.explorer.tree")
									Tree:refresh(vim.fs.dirname(file))
								else
									table.insert(failed_files, file .. "（" .. (err or "未知错误") .. "）")
								end
							end
						end

						-- 刷新目标目录
						Tree = require("snacks.explorer.tree")
						Tree:refresh(dir)
						Tree:open(dir)
						Actions.update(picker, { target = dir })

						-- 显示结果
						if success_count > 0 then
							local proc_dirs = {}
							local proc_files = {}
							for _, path in ipairs(processed_files) do
								local stat = uv.fs_stat(path) or uv.fs_stat(dir .. "/" .. vim.fn.fnamemodify(path, ":t"))
								if stat and stat.type == "directory" then
									table.insert(proc_dirs, path)
								else
									table.insert(proc_files, path)
								end
							end
							local msg_parts = {}
							local action_text = is_move and "已移动" or "已粘贴"
							if #proc_dirs > 0 then
								table.insert(msg_parts, action_text .. " " .. #proc_dirs .. " 个目录：\n- " .. table.concat(proc_dirs, "\n- "))
							end
							if #proc_files > 0 then
								table.insert(msg_parts, action_text .. " " .. #proc_files .. " 个文件：\n- " .. table.concat(proc_files, "\n- "))
							end
							Snacks.notify.info(table.concat(msg_parts, "\n"))
						end
						if #failed_files > 0 then
							vim.schedule(function()
								Snacks.notify.warn("部分文件操作失败：\n- " .. table.concat(failed_files, "\n- "))
							end)
						end
					end

					do_paste(files, is_cut)
					if is_cut then
						_G.explorer_cut_mode = false
					end
					return
				end

				-- 有冲突，显示确认对话框和文件列表
				local conflict_names = {}
				for _, c in ipairs(conflicts) do
					table.insert(conflict_names, c.name)
				end

				-- 创建预览窗口显示冲突文件列表
				local max_name_len = 0
				for _, name in ipairs(conflict_names) do
					max_name_len = math.max(max_name_len, vim.api.nvim_strwidth(name))
				end
				local width = math.max(20, math.min(max_name_len + 8, 35))
				local function center_text(text, width)
					local padding = math.floor((width - vim.api.nvim_strwidth(text)) / 2)
					return string.rep(" ", math.max(0, padding)) .. text
				end
				local file_list_lines = {}
				for _, name in ipairs(conflict_names) do
					table.insert(file_list_lines, center_text(name, width))
				end
				local buf = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, file_list_lines)
				vim.api.nvim_buf_set_option(buf, "modifiable", false)
				local height = #conflict_names
				local preview_win = vim.api.nvim_open_win(buf, false, {
					relative = "editor",
					row = math.floor((vim.o.lines - height) / 2) - 1,
					col = math.floor((vim.o.columns - width) / 2),
					width = width,
					height = height,
					style = "minimal",
					border = "rounded",
					zindex = 50,
					anchor = "NW",
				})
				vim.api.nvim_win_set_option(preview_win, "winblend", 0)
				vim.api.nvim_win_set_option(preview_win, "winhl", "Normal:NormalFloat,NormalNC:NormalFloat")

				-- 显示确认对话框
				local dir_count = 0
				local file_count = 0
				for _, c in ipairs(conflicts) do
					local stat = uv.fs_stat(c.to)
					if stat and stat.type == "directory" then
						dir_count = dir_count + 1
					else
						file_count = file_count + 1
					end
				end
				local function get_confirm_text()
					if dir_count > 0 and file_count > 0 then
						return "是否覆盖 " .. dir_count .. " 个目录、" .. file_count .. " 个文件？"
					elseif dir_count > 0 then
						return "是否覆盖 " .. dir_count .. " 个目录？"
					else
						return "是否覆盖 " .. file_count .. " 个文件？"
					end
				end

				Snacks.picker.select({ "取消", "覆盖" }, {
					prompt = get_confirm_text(),
					layout = { preset = "select", layout = { max_width = 60 } },
				}, function(item, idx)
					if preview_win and vim.api.nvim_win_is_valid(preview_win) then
						vim.api.nvim_win_close(preview_win, true)
					end
					if idx ~= 2 then
						return
					end

					-- 用户确认覆盖
					local function do_paste_with_overwrite()
						local success_count = 0
						local failed_files = {}
						local processed_files = {}

						-- 先处理无冲突的文件
						for _, file in ipairs(no_conflicts) do
							local filename = vim.fn.fnamemodify(file, ":t")
							local target = vim.fs.normalize(dir .. "/" .. filename)
							local ok, err

							if is_cut then
								-- mv 命令本身就是递归的，不需要 -R
								local full_cmd = "mv -- " .. vim.fn.shellescape(file) .. " " .. vim.fn.shellescape(dir)
								local result = vim.fn.system(full_cmd)
								if vim.v.shell_error == 0 then
									ok = true
								else
									ok, err = false, result
								end
							else
								local recursive = vim.fn.isdirectory(file) == 1 and " -R" or ""
								local full_cmd = "cp" .. recursive .. " -- " .. vim.fn.shellescape(file) .. " " .. vim.fn.shellescape(dir)
								local result = vim.fn.system(full_cmd)
								if vim.v.shell_error == 0 then
									ok = true
								else
									ok, err = false, result
								end
							end

							if ok then
								success_count = success_count + 1
								table.insert(processed_files, file)
								Tree = require("snacks.explorer.tree")
								Tree:refresh(vim.fs.dirname(file))
							else
								table.insert(failed_files, file .. "（" .. (err or "未知错误") .. "）")
							end
						end

						-- 处理有冲突的文件（覆盖）
						for _, c in ipairs(conflicts) do
							local file = c.from
							local target = c.to
							local ok, err

							if is_cut then
								-- 先删除目标，再移动
								if vim.fn.isdirectory(target) == 1 then
									vim.fn.system("rm -rf -- " .. vim.fn.shellescape(target))
								else
									vim.fn.system("rm -f -- " .. vim.fn.shellescape(target))
								end
								-- mv 命令本身就是递归的，不需要 -R
								local full_cmd = "mv -- " .. vim.fn.shellescape(file) .. " " .. vim.fn.shellescape(dir)
								local result = vim.fn.system(full_cmd)
								if vim.v.shell_error == 0 then
									ok = true
								else
									ok, err = false, result
								end
							else
								-- 复制模式：先删除目标，再复制
								if vim.fn.isdirectory(target) == 1 then
									vim.fn.system("rm -rf -- " .. vim.fn.shellescape(target))
								else
									vim.fn.system("rm -f -- " .. vim.fn.shellescape(target))
								end
								local recursive = vim.fn.isdirectory(file) == 1 and " -R" or ""
								local full_cmd = "cp" .. recursive .. " -- " .. vim.fn.shellescape(file) .. " " .. vim.fn.shellescape(dir)
								local result = vim.fn.system(full_cmd)
								if vim.v.shell_error == 0 then
									ok = true
								else
									ok, err = false, result
								end
							end

							if ok then
								success_count = success_count + 1
								table.insert(processed_files, file)
								Tree = require("snacks.explorer.tree")
								Tree:refresh(vim.fs.dirname(file))
							else
								table.insert(failed_files, file .. "（" .. (err or "未知错误") .. "）")
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
							local proc_dirs = {}
							local proc_files = {}
							for _, path in ipairs(processed_files) do
								local stat = uv.fs_stat(path) or uv.fs_stat(dir .. "/" .. vim.fn.fnamemodify(path, ":t"))
								if stat and stat.type == "directory" then
									table.insert(proc_dirs, path)
								else
									table.insert(proc_files, path)
								end
							end
							local msg_parts = {}
							local action_text = is_cut and "已移动" or "已粘贴"
							if #proc_dirs > 0 then
								table.insert(msg_parts, action_text .. " " .. #proc_dirs .. " 个目录：\n- " .. table.concat(proc_dirs, "\n- "))
							end
							if #proc_files > 0 then
								table.insert(msg_parts, action_text .. " " .. #proc_files .. " 个文件：\n- " .. table.concat(proc_files, "\n- "))
							end
							Snacks.notify.info(table.concat(msg_parts, "\n"))
						end
						if #failed_files > 0 then
							vim.schedule(function()
								Snacks.notify.warn("部分文件操作失败：\n- " .. table.concat(failed_files, "\n- "))
							end)
						end
					end

					do_paste_with_overwrite()
				end)
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
					if not new_name or new_name:find("^%s$") then
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
					-- 区分文件和目录显示
					local files = {}
					local dirs = {}
					for _, path in ipairs(paths) do
						-- 使用 uv.fs_stat 检测目录
						local stat = uv.fs_stat(path)
						if stat and stat.type == "directory" then
							table.insert(dirs, path)
						else
							table.insert(files, path)
						end
					end
					local msg_parts = {}
					if #dirs > 0 then
						table.insert(msg_parts, "已复制 " .. #dirs .. " 个目录：\n- " .. table.concat(dirs, "\n- "))
					end
					if #files > 0 then
						table.insert(msg_parts, "已复制 " .. #files .. " 个文件：\n- " .. table.concat(files, "\n- "))
					end
					Snacks.notify.info(table.concat(msg_parts, "\n"))
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
						local type_name = Snacks.util.path_type(item.file) == "directory" and "目录" or "文件"
						Snacks.notify.error("复制" .. type_name .. "失败：\n- `" .. item.file .. "`\n- " .. (err or "未知错误"))
						return
					end
					Tree = require("snacks.explorer.tree")
					Tree:refresh(vim.fs.dirname(actual_to))
					Actions.update(picker, { target = actual_to })
					local type_name = Snacks.util.path_type(item.file) == "directory" and "目录" or "文件"
					Snacks.notify.info("已复制" .. type_name .. "到：\n- `" .. actual_to .. "`")
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

				-- 检查是否尝试删除 nvim 启动时的根目录
				local init_dir = vim.fn.getcwd() -- nvim 启动时的工作目录
				for _, path in ipairs(paths) do
					local normalized_path = vim.fs.normalize(path)
					local normalized_init = vim.fs.normalize(init_dir)
					if normalized_path == normalized_init then
						return Snacks.notify.warn("不能删除项目根目录")
					end
				end

				-- 获取文件名列表
				local filenames = vim.tbl_map(function(p)
					local name = vim.fn.fnamemodify(p, ":t")
					-- 移除 macOS 符号链接末尾的 @ 符号
					return name:gsub("@$", "")
				end, paths)

				-- 统计文件和目录数量
				local file_count = 0
				local dir_count = 0
				for _, path in ipairs(paths) do
					local stat = uv.fs_stat(path)
					if stat and stat.type == "directory" then
						dir_count = dir_count + 1
					else
						file_count = file_count + 1
					end
				end

				-- 生成确认提示文本
				local function get_confirm_text()
					if dir_count > 0 and file_count > 0 then
						return "是否删除 " .. dir_count .. " 个目录、" .. file_count .. " 个文件？"
					elseif dir_count > 0 then
						return "是否删除 " .. dir_count .. " 个目录？"
					else
						return "是否删除 " .. file_count .. " 个文件？"
					end
				end

				local function do_delete()
					-- 在删除前保存文件类型信息
					local path_types = {}
					for _, path in ipairs(paths) do
						local stat = uv.fs_stat(path)
						path_types[path] = stat and stat.type == "directory" and "dir" or "file"
					end

					for _, path in ipairs(paths) do
						local ok, err = Actions.trash(path)
						if ok then
							Snacks.bufdelete({ file = path, force = true })
						else
							Snacks.notify.error("删除失败 `" .. path .. "`：\n" .. err)
						end
						Tree = require("snacks.explorer.tree")
						local parent_dir = vim.fs.dirname(path)
						-- 检查父目录是否仍然存在
						if vim.fn.isdirectory(parent_dir) == 1 then
							Tree:refresh(parent_dir)
						end
					end
					picker.list:set_selected()
					-- 检查当前目录是否仍然存在，再尝试更新
					local current_dir = picker:dir()
					if vim.fn.isdirectory(current_dir) == 1 then
						pcall(Actions.update, picker)
					end
					-- 使用保存的类型信息区分文件和目录
					local files = {}
					local dirs = {}
					for _, path in ipairs(paths) do
						if path_types[path] == "dir" then
							table.insert(dirs, path)
						else
							table.insert(files, path)
						end
					end
					local msg_parts = {}
					if #dirs > 0 then
						table.insert(msg_parts, "已删除 " .. #dirs .. " 个目录：\n- " .. table.concat(dirs, "\n- "))
					end
					if #files > 0 then
						table.insert(msg_parts, "已删除 " .. #files .. " 个文件：\n- " .. table.concat(files, "\n- "))
					end
					Snacks.notify.info(table.concat(msg_parts, "\n"))
				end

				-- 统一使用预览窗口确认对话框（单个和多个文件都使用相同界面）
				-- 创建预览窗口显示文件列表
				-- 计算最大文件名长度来确定窗口宽度
				local max_name_len = 0
				for _, name in ipairs(filenames) do
					max_name_len = math.max(max_name_len, vim.api.nvim_strwidth(name))
				end
				local width = math.max(20, math.min(max_name_len + 8, 35))
				local function center_text(text, width)
					local padding = math.floor((width - vim.api.nvim_strwidth(text)) / 2)
					return string.rep(" ", math.max(0, padding)) .. text
				end
				local file_list_lines = {}
				for i, name in ipairs(filenames) do
					local stat = uv.fs_stat(paths[i])
					local display_name = name
					if stat and stat.type == "directory" then
						display_name = name .. "（目录）"
					end
					table.insert(file_list_lines, center_text(display_name, width))
				end
				-- 预览窗口放在确认对话框下方
				local dialog_height = 2 -- 确认对话框大约高度
				local gap = 0 -- 对话框和预览窗口之间的间距
				local bottom_margin = 2 -- 底部边距
				local max_height = math.max(5, vim.o.lines - vim.o.lines / 2 - dialog_height / 2 - gap - bottom_margin)
				local height = math.min(#filenames, max_height)
				-- 如果文件列表超过预览窗口高度，截断显示
				local display_lines = file_list_lines
				if #filenames > max_height then
					display_lines = { unpack(file_list_lines, 1, max_height - 1) }
					table.insert(display_lines, center_text("...（还有 " .. (#filenames - max_height + 1) .. " 项）", width))
				end
				local buf = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
				vim.api.nvim_buf_set_option(buf, "modifiable", false)
				-- 预览窗口放在确认对话框下方
				local row = math.floor(vim.o.lines / 2 + dialog_height / 2 + gap)
				local preview_win = vim.api.nvim_open_win(buf, false, {
					relative = "editor",
					row = row,
					col = math.floor((vim.o.columns - width) / 2),
					width = width,
					height = height,
					style = "minimal",
					border = "rounded",
					zindex = 50,
					anchor = "NW",
				})
				-- 去掉背景色
				vim.api.nvim_win_set_option(preview_win, "winblend", 0)
				vim.api.nvim_win_set_option(preview_win, "winhl", "Normal:NormalFloat,NormalNC:NormalFloat")
				-- 显示确认对话框
				Snacks.picker.select({ "取消", "删除" }, {
					prompt = get_confirm_text(),
					layout = { preset = "select", layout = { max_width = 60 } },
				}, function(item, idx)
					if preview_win and vim.api.nvim_win_is_valid(preview_win) then
						vim.api.nvim_win_close(preview_win, true)
					end
					if idx == 2 then
						do_delete()
					end
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
			opts.picker.sources.explorer.win = opts.picker.sources.explorer.win or {}
			opts.picker.sources.explorer.win.list = opts.picker.sources.explorer.win.list or {}
			opts.picker.sources.explorer.win.list.keys = opts.picker.sources.explorer.win.list.keys or {}

			-- 设置 x 键映射到剪切操作
			opts.picker.sources.explorer.win.list.keys["x"] = { "explorer_cut", mode = { "n", "x" } }

			-- 修复从输入模式退出后按键识别问题：确保退出输入模式时焦点返回列表
			-- 添加自定义动作来聚焦到列表
			opts.picker.actions = opts.picker.actions or {}
			opts.picker.actions.explorer_focus_list = function(picker)
				-- 聚焦到列表
				picker:focus("list", { show = false })
			end

			opts.picker.sources.explorer.win.input = opts.picker.sources.explorer.win.input or {}
			opts.picker.sources.explorer.win.input.keys = opts.picker.sources.explorer.win.input.keys or {}
			-- 覆盖默认的 cancel 行为，改为聚焦到列表
			opts.picker.sources.explorer.win.input.keys["<Esc>"] = { "explorer_focus_list", mode = { "i" } }

			--==============================================================================
			-- 配置诊断图标显示在 git 状态图标左边
			--==============================================================================
			opts.picker.sources.explorer.formatters = opts.picker.sources.explorer.formatters or {}
			opts.picker.sources.explorer.formatters.severity = {
				pos = "right",
				icons = true,
				level = false,
			}

			-- 覆盖 severity 格式化器，支持 col 参数
			local format_mod = require("snacks.picker.format")
			local original_severity = format_mod.severity
			format_mod.severity = function(item, picker)
				local ret = {} ---@type snacks.picker.Highlight[]
				local severity = item.severity
				severity = type(severity) == "number" and vim.diagnostic.severity[severity] or severity
				if not severity or type(severity) == "number" then
					return ret
				end
				---@cast severity string
				local lower = severity:lower()
				local cap = severity:sub(1, 1):upper() .. lower:sub(2)

				if picker.opts.formatters.severity.pos == "right" then
					-- 使用配置的 col 值，默认为 2（在 git 图标左边）
					local col_offset = picker.opts.formatters.severity.col or 2
					return {
						{
							col = col_offset,
							virt_text = { { picker.opts.icons.diagnostics[cap], "Diagnostic" .. cap } },
							virt_text_pos = "right_align",
							hl_mode = "combine",
						},
					}
				end

				if picker.opts.formatters.severity.icons then
					ret[#ret + 1] = { picker.opts.icons.diagnostics[cap], "Diagnostic" .. cap, virtual = true }
					ret[#ret + 1] = { " ", virtual = true }
				end

				if picker.opts.formatters.severity.level then
					ret[#ret + 1] = { lower:upper(), "Diagnostic" .. cap, virtual = true }
					ret[#ret + 1] = { " ", virtual = true }
				end

				return ret
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
			-- 修改 Git 文件颜色
			--==============================================================================
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("SnacksExplorerHighlight", { clear = true }),
				callback = function()
					-- 未跟踪文件：绿色
					vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { link = "String" })
					-- 已添加文件：黄色
					vim.api.nvim_set_hl(0, "SnacksPickerGitStatusAdded", { link = "DiagnosticWarn" })
					-- 已暂存修改：蓝色
					vim.api.nvim_set_hl(0, "SnacksPickerGitStatusStaged", { link = "DiagnosticInfo" })
					-- 目录树光标行颜色（链接到 CursorLine，自动跟随主题）
					vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { link = "CursorLine" })
				end,
			})
			-- 立即应用一次（防止 ColorScheme 已经加载过）
			vim.schedule(function()
				vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { link = "String" })
				vim.api.nvim_set_hl(0, "SnacksPickerGitStatusAdded", { link = "DiagnosticWarn" })
				vim.api.nvim_set_hl(0, "SnacksPickerGitStatusStaged", { link = "DiagnosticInfo" })
				vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { link = "CursorLine" })
			end)

			--==============================================================================
			-- 启动时自动打开 Explorer（仅当非目录参数启动时）
			--==============================================================================
			-- 只有在不以目录参数启动时才自动打开 Explorer
			if not start_with_dir then
				vim.api.nvim_create_autocmd("UiEnter", {
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
								-- 检测是否有文件参数
								local has_file_arg = false
								for _, a in ipairs(vim.fn.argv()) do
									if not vim.startswith(a, "-") and vim.fn.isdirectory(a) == 0 and a ~= "" then
										has_file_arg = true
										break
									end
								end

								local root = vim.g.root_dir
									or (_G.LazyVim and _G.LazyVim.root and _G.LazyVim.root.get and _G.LazyVim.root.get())
									or vim.fn.getcwd()
								Snacks.explorer.open({ cwd = root })

								-- 只有在带文件参数启动时才切换到编辑器窗口
								if has_file_arg then
									vim.defer_fn(function()
										for _, win in ipairs(vim.api.nvim_list_wins()) do
											local buf = vim.api.nvim_win_get_buf(win)
											local filetype = vim.bo[buf].filetype
											if filetype ~= "snacks_explorer" and filetype ~= "snacks_picker" and filetype ~= "snacks_input" then
												pcall(vim.api.nvim_set_current_win, win)
												break
											end
										end
									end, 10)
								end
							end
						end)
					end,
					desc = "启动时自动打开 Snacks Explorer",
				})
			end

			--==============================================================================
			-- 修复 Explorer 在文件切换后消失的问题
			--==============================================================================
			-- 方案：将 q 键映射为关闭 buffer（而非窗口），避免布局重排导致 Explorer 消失

			-------------------------------------------------------------------------------
			-- Pinned 状态管理（方案 B：自己维护，不依赖 bufferline 内部 API）
			-------------------------------------------------------------------------------
			---@param buf number
			---@return boolean
			local function is_pinned(buf)
				-- 优先检查我们自己的 pinned 状态
				if vim.b[buf].pinned then
					return true
				end
				-- 兼容其他人可能用的 buf var 名
				if vim.b[buf].bufferline_pinned then
					return true
				end
				-- 检查 bufferline groups 的 pinned 状态
				local ok_groups, groups = pcall(require, "bufferline.groups")
				local ok_state, state = pcall(require, "bufferline.state")
				if ok_groups and ok_state and state.components then
					for _, element in ipairs(state.components) do
						if element.id == buf and groups._is_pinned(element) then
							return true
						end
					end
				end
				return false
			end

			-- 1. 命令行模式 :q 和 :x 映射为保存后删除 buffer
			vim.api.nvim_create_autocmd("VimEnter", {
				once = true,
				callback = function()
					vim.api.nvim_create_user_command("Q", function(opts)
						local buf = vim.api.nvim_get_current_buf()
						-- 检查 pinned
						if is_pinned(buf) then
							vim.notify("Buffer 已固定，无法关闭", vim.log.levels.WARN)
							return
						end
						local bufname = vim.api.nvim_buf_get_name(buf)
						-- 先保存（如果有文件名且已修改）
						if bufname ~= "" and vim.bo[buf].modified then
							vim.api.nvim_buf_call(buf, function()
								vim.cmd("write")
							end)
						end
						-- 使用 Snacks.bufdelete 只删除当前 buffer
						require("snacks").bufdelete(buf, opts.bang)
					end, { bang = true, desc = "Write and delete buffer" })
					vim.cmd("cnoreabbrev q Q")
					vim.cmd("cnoreabbrev q! Q!")
					vim.cmd("cnoreabbrev x Q")
					vim.cmd("cnoreabbrev x! Q!")
				end,
			})

			-- 2. 普通模式 q 键映射
			vim.api.nvim_create_autocmd("BufWinEnter", {
				group = vim.api.nvim_create_augroup("SnacksExplorerQKey", { clear = true }),
				callback = function(ev)
					-- 只对普通文件生效
					local buftype = vim.bo[ev.buf].buftype
					local filetype = vim.bo[ev.buf].filetype
					-- 排除特殊缓冲区
					if buftype ~= "" then
						return
					end
					-- 排除 Explorer 和 picker 等特殊类型
					if filetype == "snacks_explorer" or filetype == "snacks_picker" or filetype == "snacks_input" then
						return
					end
					-- 为这个 buffer 设置 q 键映射 (保存后删除 buffer)
					vim.keymap.set("n", "q", function()
						local buf = ev.buf
						-- 检查 pinned
						if is_pinned(buf) then
							vim.notify("Buffer 已固定，无法关闭", vim.log.levels.WARN)
							return
						end
						-- 先保存当前 buffer（如果有文件名且已修改）
						local bufname = vim.api.nvim_buf_get_name(buf)
						if bufname ~= "" and vim.bo[buf].modified then
							vim.api.nvim_buf_call(buf, function()
								vim.cmd("write")
							end)
						end
						-- 使用 Snacks.bufdelete 只删除当前 buffer
						require("snacks").bufdelete(buf)
					end, {
						buffer = ev.buf,
						desc = "Write and delete buffer (keep window layout)",
					})
				end,
				desc = "将 q 键映射为关闭 buffer，保护 Explorer 窗口布局",
			})

			-- 3. Option+q 切换目录树
			vim.keymap.set("n", "<M-q>", function()
				local Snacks = require("snacks")
				Snacks.explorer()
			end, { desc = "Toggle Explorer" })

			-- 4. Option+=/- 切换 buffer
			vim.keymap.set("n", "<M-=>", function()
				vim.cmd("bnext")
			end, { desc = "Next buffer" })
			vim.keymap.set("n", "<M-->", function()
				vim.cmd("bprevious")
			end, { desc = "Previous buffer" })

			--==============================================================================
			-- 行内快速移动
			--==============================================================================
			-- 定义 <Plug> 映射作为动作基础
			vim.keymap.set({ "n", "o", "x" }, "<Plug>(MotionLineStart)", "^", { desc = "Motion to line start" })
			vim.keymap.set({ "n", "o", "x" }, "<Plug>(MotionLineEnd)", "$", { desc = "Motion to line end" })

			-- Normal 模式快捷移动
			vim.keymap.set("n", "<M-h>", "<Plug>(MotionLineStart)", { desc = "Move to line start" })
			vim.keymap.set("n", "<M-l>", "<Plug>(MotionLineEnd)", { desc = "Move to line end" })

			-- Operator-pending 模式 (配合 d, c, y 等操作符)
			vim.keymap.set("o", "<M-h>", "<Plug>(MotionLineStart)", { desc = "Operator: to line start" })
			vim.keymap.set("o", "<M-l>", "<Plug>(MotionLineEnd)", { desc = "Operator: to line end" })

			-- Visual 模式扩展选择
			vim.keymap.set("x", "<M-h>", "^", { desc = "Visual select to line start" })
			vim.keymap.set("x", "<M-l>", "$", { desc = "Visual select to line end" })

			--==============================================================================
			-- 屏幕滚动
			--==============================================================================
			-- Alt + z 跳转到文件末尾并居中
			vim.keymap.set({ "n", "i" }, "<M-z>", function()
				vim.cmd("normal! Gzz")
			end, { desc = "Go to end of file and center" })

			return opts
		end,
	},

	--==============================================================================
	-- 覆盖 LazyVim 的 bufferline 配置
	--==============================================================================
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			opts.options = opts.options or {}
			opts.options.always_show_bufferline = true
			return opts
		end,
		config = function(_, opts)
			require("bufferline").setup(opts)
			-- 使用 ColorScheme 事件确保在主题加载后设置高亮
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("BufferlineHighlights", { clear = true }),
				callback = function()
					-- 设置未激活标签页的文字颜色（更亮）
					vim.api.nvim_set_hl(0, "BufferLineBackground", { fg = "#9aa5ce", bold = true })
					vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { fg = "#9aa5ce", bold = true })
				end,
			})
			-- 立即执行一次
			vim.cmd("doautocmd ColorScheme")
		end,
		keys = {
			{
				"<leader>bp",
				function()
					vim.cmd("BufferLineTogglePin")
				end,
				desc = "切换固定",
			},
		},
	},
}
