-- lua/util/refactor_smart.lua
local M = {}

-- =============================================================================
-- 辅助功能：Visual 模式重构菜单（中文界面）
-- =============================================================================
function M.smart_visual_refactor()
	-- 重构操作选项（中文标签 + refactoring.nvim 需要的命令名）
	local refactor_options = {
		{ label = "✨ 提取函数", cmd = "extract", name = "Extract Function" },
		{ label = "🧱 提取代码块", cmd = "extract_block", name = "Extract Block" },
		{ label = "📦 提取变量", cmd = "extract_var", name = "Extract Variable" },
		{ label = "📥 内联函数", cmd = "inline_func", name = "Inline Function" },
		{ label = "🗑️ 内联变量", cmd = "inline_var", name = "Inline Variable" },
		{ label = "📄 提取函数到文件", cmd = "extract_to_file", name = "Extract Function To File" },
		{ label = "📁 提取代码块到文件", cmd = "extract_block_to_file", name = "Extract Block To File" },
	}

	-- 必须在 Visual/Select 模式触发（包含 visual/select/operator-pending 变体）
	local mode = vim.fn.mode()
	local ok_modes = { v = true, V = true, ["\22"] = true, s = true, x = true }
	if not ok_modes[mode] then
		vim.notify("请先选择代码（Visual/Select 模式）", vim.log.levels.WARN)
		return
	end

	-- 在 Visual 模式下直接尝试读取当前选区（避免依赖 marks）
	local selection_from_getpos = false
	local r1, c1, r2, c2
	if mode == "v" or mode == "V" or mode == "x" or mode == "s" or mode == "\22" then
		local vp = vim.fn.getpos("v") -- 0:buf,1:ln,2:col,3:off
		local cp = vim.fn.getpos(".")
		if vp and cp and vp[2] and cp[2] then
			local a_r, a_c = vp[2], (vp[3] or 1) - 1
			local b_r, b_c = cp[2], (cp[3] or 1) - 1
			if a_r > b_r or (a_r == b_r and a_c > b_c) then
				r1, c1, r2, c2 = b_r, b_c, a_r, a_c
			else
				r1, c1, r2, c2 = a_r, a_c, b_r, b_c
			end
			selection_from_getpos = true
		end
	end

	-- 如果未能直接读取选区，尝试退出 Visual 以依赖 marks
	if not selection_from_getpos then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", true)
	end

	-- helper: 多次尝试聚焦到指定缓冲并进入 insert（避免插件恢复焦点）
	local function focus_and_insert_on_buf(target_buf)
		local delays = { 0, 50, 150, 300, 600 }
		for _, d in ipairs(delays) do
			pcall(vim.defer_fn, function()
				for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
					for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
						local bufnr = vim.api.nvim_win_get_buf(win)
						if bufnr == target_buf then
							-- 切换到该窗口并进入插入模式
							pcall(vim.api.nvim_set_current_win, win)
							pcall(vim.cmd, "startinsert")
							return
						end
					end
				end
			end, d)
		end
	end

	-- 异步处理以获取 marks 或使用前面捕获的选区（安全）
	vim.schedule(function()
		if not selection_from_getpos then
			local s_mark = vim.api.nvim_buf_get_mark(0, "<")
			local e_mark = vim.api.nvim_buf_get_mark(0, ">")
			r1, c1 = s_mark[1], s_mark[2]
			r2, c2 = e_mark[1], e_mark[2]
			if not r1 or not r2 then return end
		end

		local lines = vim.api.nvim_buf_get_lines(0, r1 - 1, r2, false)
		if #lines == 0 then return end

		-- 计算并返回精修后的 range（行/列均为 1-based 行，0-based 列）
		local function get_clean_range()
			local sr, sc, er, ec = r1, c1, r2, c2

			-- 去除首尾空行
			local f_non = 1
			while f_non <= #lines and lines[f_non]:match("^%s*$") do f_non = f_non + 1 end
			local l_non = #lines
			while l_non >= f_non and lines[l_non]:match("^%s*$") do l_non = l_non - 1 end
			if f_non > l_non then return nil end

			sr = r1 + f_non - 1
			er = r1 + l_non - 1
			local sc_i = (f_non == 1) and c1 or 0
			local ec_i = (l_non == #lines) and c2 or (#lines[l_non] - 1)

			-- 获取选区文本片段
			local sub = {}
			for i = f_non, l_non do
				local line = lines[i]
				local s = (i == f_non) and sc_i or 0
				local e = (i == l_non) and ec_i or (#line - 1)
				table.insert(sub, line:sub(s + 1, e + 1))
			end
			local text = table.concat(sub, "\n")

			-- 激进修剪函数：去除零宽字符、外层包裹与首尾干扰标点
			local function aggressive_trim(s)
				-- 删除常见零宽字符与 BOM
				local zero_width_codes = {0x200B, 0x200C, 0x200D, 0xFEFF, 0x2060}
				for _, code in ipairs(zero_width_codes) do
					local ch = vim.fn.nr2char(code)
					s = s:gsub(ch, "")
				end

				local changed = true
				while changed do
					changed = false
					local n = s:gsub("^%s+", ""):gsub("%s+$", "")

					-- 成对括号/中括号/花括号/尖括号
					local pairs = { { "(", ")" }, { "[", "]" }, { "{", "}" }, { "<", ">" } }
					local stripped = false
					for _, p in ipairs(pairs) do
						if n:sub(1,1) == p[1] and n:sub(-1) == p[2] then
							local content = n:sub(2, -2)
							local bal = 0
							local ok = true
							for i = 1, #content do
								local char = content:sub(i,i)
								if char == p[1] then bal = bal + 1 elseif char == p[2] then bal = bal - 1 end
								if bal < 0 then ok = false; break end
							end
							if ok and bal == 0 then
								n = content
								changed = true
								stripped = true
								break
							end
						end
					end

					-- 去除成对引号或反引号包裹
					if not stripped then
						local first = n:sub(1,1)
						local last = n:sub(-1)
						if (first == last) and (first == '"' or first == "'" or first == "`") then
							n = n:sub(2, -2)
							changed = true
						end
					end

					-- 保守去除首尾的标点或控制字符（避免内部符号被误删）
					local n2 = n:gsub("^[%p%c]+", ""):gsub("[%p%c]+$", "")
					if n2 ~= n then n = n2; changed = true end

					-- 额外删除尾部常见分隔符
					local n3 = n:gsub("[,;:]+$", "")
					if n3 ~= n then n = n3; changed = true end

					if n ~= s then s = n; changed = true end
				end
				return s
			end

			local clean = aggressive_trim(text)
			if clean == "" then return nil end

			-- 计算 clean 在原始 text 中的偏移以找回行/列
			local start_off = text:find(clean, 1, true)
			if not start_off then return { sr = sr, sc = sc_i, er = er, ec = ec_i } end

			local before = text:sub(1, start_off - 1)
			local nl_b = 0
			for i = 1, #before do if before:sub(i,i) == "\n" then nl_b = nl_b + 1 end end
			local fsr = sr + nl_b
			local fsc = 0
			if nl_b > 0 then
				local l_nl = 0
				for i = #before, 1, -1 do if before:sub(i,i) == "\n" then l_nl = i; break end end
				fsc = #before - l_nl
			else
				fsc = sc_i + #before
			end

			local nl_i = 0
			for i = 1, #clean do if clean:sub(i,i) == "\n" then nl_i = nl_i + 1 end end
			local fer = fsr + nl_i
			local fec = 0
			if nl_i > 0 then
				local cur = ""
				for i = 1, #clean do
					local c = clean:sub(i,i)
					if c == "\n" then cur = "" else cur = cur .. c end
				end
				fec = #cur - 1
			else
				fec = fsc + #clean - 1
			end

			return { sr = fsr, sc = fsc, er = fer, ec = fec }
		end

		local range = get_clean_range()
		if not range then
			vim.notify("选区为空，已取消重构", vim.log.levels.WARN)
			return
		end

		-- 弹出重构操作选择（中文标签）
		vim.ui.select(refactor_options, {
			prompt = "选择重构操作 (选区已自动精修)",
			format_item = function(item) return item.label end,
		}, function(choice)
			if not choice then return end

			-- 设置 marks 并用 refactoring.nvim 执行（优先直接 Lua 调用，失败回退到 feedkeys）
			vim.schedule(function()
				vim.api.nvim_buf_set_mark(0, "<", range.sr, range.sc, {})
				vim.api.nvim_buf_set_mark(0, ">", range.er, range.ec, {})

				-- 检查 refactoring.nvim 是否可用
				local ok, refactoring = pcall(require, "refactoring")
				if ok and type(refactoring.refactor) == "function" then
					-- 尝试直接调用并执行返回的 normal keys（refactoring.refactor 返回 "g@..."）
					local suc, keys_or_err = pcall(function()
						return refactoring.refactor(choice.cmd)
					end)
					if not suc then
						vim.notify("直接调用重构失败，尝试回退执行", vim.log.levels.WARN)
					else
						local keys = keys_or_err
						-- plugin 返回 "g@" 或 "g@iw" 等，参考 plugin 实现需使用 normal 执行
						if keys == "g@" then keys = "gvg@" end
						local ok_norm, norm_err = pcall(function() vim.cmd.normal(keys) end)
						if not ok_norm then
							vim.notify("执行重构命令失败，已回退", vim.log.levels.WARN)
						else
							-- 保底：查找可能的 refactor 缓冲并重复尝试聚焦进入 insert
							local target_buf = nil
							for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
								local name = vim.api.nvim_buf_get_name(bufnr) or ""
								local ok_ftb, ftb = pcall(vim.api.nvim_buf_get_option, bufnr, "filetype")
								if name:match("refactoring://") or (ok_ftb and (ftb == "refactoring" or ftb == "snacks_input")) or name:match("[Rr]efact") then
									target_buf = bufnr
									break
								end
							end
							if target_buf then
								focus_and_insert_on_buf(target_buf)
							end
							return
						end
					end
				else
					vim.notify("未检测到 refactoring.nvim，使用回退执行", vim.log.levels.INFO)
				end

				-- 回退策略：先验证 marks 是否已设置
				local m1 = vim.api.nvim_buf_get_mark(0, "<")
				local m2 = vim.api.nvim_buf_get_mark(0, ">")
				if not m1 or not m2 or m1[1] == 0 or m2[1] == 0 then
					vim.notify("无法执行重构：选区标记未设置", vim.log.levels.ERROR)
					return
				end

				-- 尝试使用命令范围调用 :Refactor (使用短命令 key `choice.cmd`)
				local ok_cmd, cmd_err = pcall(function()
					local cmd_str = string.format("%d,%dRefactor %s", m1[1], m2[1], choice.cmd)
					vim.cmd(cmd_str)
				end)
				if ok_cmd then
					return
				else
					vim.notify("范围命令调用失败，回退执行", vim.log.levels.WARN)
				end

				-- 最后回退：通过 feedkeys 恢复 Visual 并触发 Lua API（尽量避免触发 E20）
				local keys = vim.api.nvim_replace_termcodes(
					string.format("gv<cmd>lua require('refactoring').refactor('%s')<CR>", choice.cmd),
					true, false, true
				)
				vim.api.nvim_feedkeys(keys, "m", false)
				-- 回退路径保底：查找可能的 refactor 缓冲并重复尝试聚焦进入 insert
				local target_buf = nil
				for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
					local name = vim.api.nvim_buf_get_name(bufnr) or ""
					local ok_ftb, ftb = pcall(vim.api.nvim_buf_get_option, bufnr, "filetype")
					if name:match("refactoring://") or (ok_ftb and (ftb == "refactoring" or ftb == "snacks_input")) or name:match("[Rr]efact") then
						target_buf = bufnr
						break
					end
				end
				if target_buf then
					focus_and_insert_on_buf(target_buf)
				end
			end)
		end)
	end)
end

return M
