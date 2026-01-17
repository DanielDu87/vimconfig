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

			-- 复制（yank）
			function Actions.actions.explorer_yank(picker)
				local files = {} ---@type string[]
				if vim.fn.mode():find("^[vV]") then
					picker.list:select()
				end
				for _, item in ipairs(picker:selected({ fallback = true })) do
					table.insert(files, Snacks.picker.util.path(item))
				end
				picker.list:set_selected()
				local value = table.concat(files, "\n")
				vim.fn.setreg(vim.v.register or "+", value, "l")
				Snacks.notify.info("已复制 " .. #files .. " 个文件")
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
				Snacks.picker.util.copy(files, dir)
				Tree = require("snacks.explorer.tree")
				Tree:refresh(dir)
				Tree:open(dir)
				Actions.update(picker, { target = dir })
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
					vim.fn.mkdir(dir, "p")
					if is_file then
						io.open(path, "w"):close()
					end
					Tree = require("snacks.explorer.tree")
					Tree:open(dir)
					Tree:refresh(dir)
					Actions.update(picker, { target = path })
				end)
			end

			-- 复制文件
			function Actions.actions.explorer_copy(picker, item)
				if not item then
					return
				end
				---@type string[]
				local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
				-- Copy selection
				if #paths > 0 then
					local dir = picker:dir()
					Snacks.picker.util.copy(paths, dir)
					picker.list:set_selected()
					Tree = require("snacks.explorer.tree")
					Tree:refresh(dir)
					Tree:open(dir)
					Actions.update(picker, { target = dir })
					return
				end
				Snacks.input({
					prompt = "复制到：",
				}, function(value)
					if not value or value:find("^%s$") then
						return
					end
					local dir = vim.fs.dirname(item.file)
					local to = vim.fs.normalize(dir .. "/" .. value)
					local uv = vim.uv or vim.loop
					if uv.fs_stat(to) then
						Snacks.notify.warn("文件已存在：\n- `" .. to .. "`")
						return
					end
					Snacks.picker.util.copy_path(item.file, to)
					Tree = require("snacks.explorer.tree")
					Tree:refresh(vim.fs.dirname(to))
					Actions.update(picker, { target = to })
				end)
			end

			-- 移动文件
			function Actions.actions.explorer_move(picker)
				---@type string[]
				local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected())
				if #paths == 0 then
					Snacks.notify.warn("未选择文件，改为重命名")
					return Actions.actions.explorer_rename(picker, picker:current())
				end
				local target = picker:dir()
				local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " 个文件"
				local t = vim.fn.fnamemodify(target, ":p:~:.")

				Snacks.picker.util.confirm("是否移动 " .. what .. " 到 " .. t .. "？", function()
					for _, from in ipairs(paths) do
						local to = target .. "/" .. vim.fn.fnamemodify(from, ":t")
						Snacks.rename.rename_file({ from = from, to = to })
						Tree = require("snacks.explorer.tree")
						Tree:refresh(vim.fs.dirname(from))
					end
					Tree = require("snacks.explorer.tree")
					Tree:refresh(target)
					picker.list:set_selected()
					Actions.update(picker, { target = target })
				end)
			end

			-- 删除文件
			function Actions.actions.explorer_del(picker)
				---@type string[]
				local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
				if #paths == 0 then
					return
				end
				local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " 个文件"
				Snacks.picker.util.confirm("是否删除 " .. what .. "？", function()
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
				end)
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
