_G._command_panel = function()
	require("telescope.builtin").keymaps({
		lhs_filter = function(lhs)
			return not string.find(lhs, "Þ")
		end,
	})
end

_G._flash_esc_or_noh = function()
	local flash_active, state = pcall(function()
		return require("flash.plugins.char").state
	end)
	if flash_active and state then
		state:hide()
	else
		pcall(vim.cmd.noh)
	end
end

_G._telescope_collections = function(picker_type)
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values
	local finder = require("telescope.finders")
	local pickers = require("telescope.pickers")
	picker_type = picker_type or {}

	local collections = vim.tbl_keys(require("search.tabs").collections)
	pickers
		.new(picker_type, {
			prompt_title = "Telescope Collections",
			finder = finder.new_table({ results = collections }),
			sorter = conf.generic_sorter(picker_type),
			attach_mappings = function(bufnr)
				actions.select_default:replace(function()
					actions.close(bufnr)
					local selection = action_state.get_selected_entry()
					require("search").open({ collection = selection[1] })
				end)

				return true
			end,
		})
		:find()
end

_G._toggle_inlayhint = function()
	local is_enabled = vim.lsp.inlay_hint.is_enabled()

	vim.lsp.inlay_hint.enable(not is_enabled)
	vim.notify(
		(is_enabled and "Inlay hint disabled successfully" or "Inlay hint enabled successfully"),
		vim.log.levels.INFO,
		{ title = "LSP Inlay Hint" }
	)
end

-- Go: 兜底的 goto-definition
-- 场景：在 GOPATH module cache（pkg/mod）里，gopls 可能会因为 workspace/metadata 问题返回空 definition。
-- 这里先尝试标准 LSP definition；若为空，再根据 import path 打开目标包并跳到 `type <Ident>`。
_G._go_goto_definition_fallback = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype
	if ft ~= "go" then
		vim.lsp.buf.definition()
		return
	end

	local function get_qualified_ident_at_cursor()
		local pos = vim.api.nvim_win_get_cursor(0)
		local col = (pos[2] or 0) + 1 -- 1-based
		local line = vim.api.nvim_get_current_line()
		local function nearest_ident()
			local ident = vim.fn.expand("<cword>")
			if ident and ident ~= "" then
				return ident
			end
			-- 光标可能落在 `*` / 空白等位置：尝试取右侧第一个标识符
			local right = line:sub(col)
			local r = right:match("([%w_]+)")
			if r and r ~= "" then
				return r
			end
			-- 再尝试左侧最后一个标识符
			local left = line:sub(1, col)
			local l = left:match("([%w_]+)%s*$")
			return l
		end
		local i = 1
		while true do
			local s, e, a, b = line:find("([%w_]+)%.([%w_]+)", i)
			if not s then
				break
			end
			if col >= s and col <= e then
				return a, b
			end
			i = e + 1
		end

		-- 如果光标落在 `DocInfo` 上，<cword> 只有标识符，没有别名；尝试从左侧补全 alias
		local ident = nearest_ident()
		local left = line:sub(1, col)
		local alias = left:match("([%w_]+)%.([%w_]*)$")
		if alias and ident and ident ~= "" then
			return alias, ident
		end
		-- 同包类型：没有 pkg. 前缀时也返回 ident
		if ident and ident ~= "" then
			return nil, ident
		end

		-- 最后退化：用 <cWORD> 再尝试一次（能包含点号）
		local cWORD = vim.fn.expand("<cWORD>")
		local a2, b2 = cWORD:match("([%w_]+)%.([%w_]+)")
		return a2, b2
	end

	local params = vim.lsp.util.make_position_params(0, "utf-16")
	local resp = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", params, 1200)
	local function has_locations(r)
		if type(r) ~= "table" then
			return false
		end
		for _, v in pairs(r) do
			local res = v and v.result
			if res and ((vim.islist and vim.islist(res) and #res > 0) or res.uri) then
				return true
			end
		end
		return false
	end
	if has_locations(resp) then
		vim.lsp.buf.definition()
		return
	end

	-- 解析形如 `search_common.DocInfo`（允许光标落在任意一侧）
	local alias, ident = get_qualified_ident_at_cursor()
	if not ident or ident == "" then
		vim.notify("LSP definition 为空，且无法解析到标识符", vim.log.levels.WARN, { title = "gopls" })
		return
	end
	-- 如果是当前包内的类型（没有 pkg. 前缀），直接在当前 buffer 搜 `type <Ident>`
	if not alias then
		local pat_local = "^type\\s\\+" .. ident .. "\\>"
		vim.cmd("normal! m'")
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		local lnum = vim.fn.search(pat_local, "W")
		if lnum ~= 0 then
			vim.api.nvim_win_set_cursor(0, { lnum, 0 })
			vim.cmd("normal! zz")
			return
		end
		-- 再在当前包目录内兜底查找（同包类型可能定义在别的 .go 文件）
		local dir = vim.fn.expand("%:p:h")
		local files = vim.fn.globpath(dir, "*.go", false, true)
		for _, f in ipairs(files) do
			vim.cmd("normal! m'")
			vim.cmd("edit " .. vim.fn.fnameescape(f))
			vim.api.nvim_win_set_cursor(0, { 1, 0 })
			local ln = vim.fn.search(pat_local, "W")
			if ln ~= 0 then
				vim.api.nvim_win_set_cursor(0, { ln, 0 })
				vim.cmd("normal! zz")
				return
			end
		end
		vim.notify("LSP definition 为空，且未在当前包找到 type " .. ident, vim.log.levels.WARN, { title = "gopls" })
		return
	end

	-- 从 import block 里找 alias -> import path
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
	local in_block = false
	local imports = {}
	for _, line in ipairs(lines) do
		if line:match("^import%s*%(") then
			in_block = true
		elseif in_block and line:match("^%)") then
			break
		end
		local p = line:match('^%s*"([^"]+)"')
		if p then
			local base = p:match("/([^/]+)$") or p
			imports[base] = p
		else
			local a, pp = line:match('^%s*([%w_]+)%s+"([^"]+)"')
			if a and pp then
				imports[a] = pp
			end
		end
	end
	local import_path = imports[alias]
	if not import_path then
		vim.notify("LSP definition 为空，且未找到 import: " .. alias, vim.log.levels.WARN, { title = "gopls" })
		return
	end

	-- 选一个合理的工作目录：优先 cwd 上的 go.work/go.mod
	local cwd = vim.fn.getcwd()
	local go_root = cwd
	local ok_find, found = pcall(function()
		return vim.fs.find({ "go.work", "go.mod" }, { upward = true, path = cwd })
	end)
	if ok_find and type(found) == "table" and #found > 0 then
		go_root = vim.fs.dirname(found[1])
	end

	local cmd = "cd " .. vim.fn.shellescape(go_root) .. " && go list -f '{{.Dir}}' " .. vim.fn.shellescape(import_path)
	local out = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 or not out or not out[1] or out[1] == "" then
		vim.notify("go list 失败: " .. (out and out[1] or ""), vim.log.levels.ERROR, { title = "gopls" })
		return
	end
	local dir = out[1]

	-- Vim 正则里不要用 \b（是退格），用 \> 做单词边界
	local pat = "^type\\s\\+" .. ident .. "\\>"

	-- 优先尝试 thrift 常见的 ttypes.go（但必须从文件开头搜索，避免落到旧光标位置导致找不到/定位偏移）
	-- 把这次“跳定义”也写入 tagstack，这样默认的 <C-t>（tag pop）能回跳
	pcall(vim.fn.settagstack, 0, {
		items = {
			{ tagname = (alias and (alias .. ".") or "") .. ident, from = vim.fn.getcurpos() },
		},
	}, "a")

	local ttypes = dir .. "/ttypes.go"
	if vim.fn.filereadable(ttypes) == 1 then
		vim.cmd("normal! m'")
		vim.cmd("edit " .. vim.fn.fnameescape(ttypes))
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		local lnum = vim.fn.search(pat, "W")
		if lnum ~= 0 then
			vim.api.nvim_win_set_cursor(0, { lnum, 0 })
			vim.cmd("normal! zz")
			return
		end
	end

	-- 再在整个目录里兜底查找：第一个命中的 `type <Ident>`
	local files = vim.fn.globpath(dir, "*.go", false, true)
	for _, f in ipairs(files) do
		vim.cmd("normal! m'")
		vim.cmd("edit " .. vim.fn.fnameescape(f))
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		local lnum = vim.fn.search(pat, "W")
		if lnum ~= 0 then
			vim.api.nvim_win_set_cursor(0, { lnum, 0 })
			vim.cmd("normal! zz")
			return
		end
	end

	vim.notify("未在 " .. dir .. " 找到 type " .. ident, vim.log.levels.WARN, { title = "gopls" })
end

local _vt_enabled = require("core.settings").diagnostics_virtual_text
_G._toggle_virtualtext = function()
	if vim.diagnostic.is_enabled() then
		_vt_enabled = not _vt_enabled
		vim.diagnostic[_vt_enabled and "show" or "hide"]()
		vim.notify(
			(_vt_enabled and "Virtual text is now displayed" or "Virtual text is now hidden"),
			vim.log.levels.INFO,
			{ title = "LSP Diagnostic" }
		)
	end
end

local _lazygit = nil
_G._toggle_lazygit = function()
	if vim.fn.executable("lazygit") == 1 then
		if not _lazygit then
			_lazygit = require("toggleterm.terminal").Terminal:new({
				cmd = "lazygit",
				direction = "float",
				close_on_exit = true,
				hidden = true,
			})
		end
		_lazygit:toggle()
	else
		vim.notify("Command [lazygit] not found!", vim.log.levels.ERROR, { title = "toggleterm.nvim" })
	end
end
