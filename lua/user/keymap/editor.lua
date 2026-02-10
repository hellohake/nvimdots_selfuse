local bind = require("keymap.bind")
local map_cmd = bind.map_cmd
local map_cr = bind.map_cr
local map_callback = bind.map_callback

-- Emergency Fix: 如果 Leader 键失效，运行 :FixLeader 命令即可修复
vim.api.nvim_create_user_command("FixLeader", function()
	vim.g.mapleader = " "
	vim.keymap.set({ "n", "x" }, "<Space>", "<Nop>", { noremap = true, silent = true })
	vim.notify("Leader key (Space) has been reset! Try pressing it now.", vim.log.levels.INFO)
end, { desc = "Fix broken leader key (Space)" })

_G.copy_global_path_with_line = function()
	local path = vim.fn.expand("%:p") -- 绝对路径
	if path == "" then
		return
	end
	local line = vim.fn.line(".")
	local text = path .. ":" .. line
	vim.fn.setreg("+", text)
	vim.notify("Copied: " .. text)
end

_G.copy_git_relative_path_with_line = function()
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if not git_root or git_root == "" then
		vim.notify("Not in a git repo", vim.log.levels.WARN)
		return
	end

	local file = vim.fn.expand("%:p")
	if file == "" then
		return
	end

	local rel = file:gsub("^" .. git_root .. "/", "")
	local line = vim.fn.line(".")
	local text = rel .. ":" .. line

	vim.fn.setreg("+", text)
	vim.notify("Copied: " .. text)
end

_G.search_visual_selection = function()
	vim.cmd('noau normal! gv"vy')
	local text = vim.fn.getreg("v")
	vim.fn.setreg("v", {})

	text = string.gsub(text, "\n", "")
	if #text > 0 then
		require("telescope.builtin").grep_string({ search = text })
	end
end

_G.toggle_diffview = function(args)
	local lib = require("diffview.lib")
	local view = lib.get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	else
		args = args or ""
		vim.cmd("DiffviewOpen " .. args)
	end
end

-- 直接打开指定 diff（若已打开则先关闭再打开），用于在不同 commit 之间快速切换
_G.open_diffview = function(args)
	local lib = require("diffview.lib")
	local view = lib.get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	end
	args = args or ""
	vim.cmd("DiffviewOpen " .. args)
end

-- 查看第 N 个“最近提交”的 diff（1=HEAD，2=HEAD~1，...）
-- 使用 `commit^!` 语法展示“该提交相对于其父提交”的变更。
_G.open_diffview_nth_commit = function(n)
	n = tonumber(n)
	if not n or n < 1 then
		vim.notify("请输入有效的提交序号：1=HEAD, 2=HEAD~1, ...", vim.log.levels.WARN, { title = "diffview" })
		return
	end
	local ref = (n == 1) and "HEAD" or ("HEAD~" .. (n - 1))
	_G.open_diffview(ref .. "^!")
end

_G.open_diffview_prompt_commit = function()
	local input = vim.fn.input("查看第 N 个最近提交 diff（1=HEAD, 2=HEAD~1...）：", "1")
	if input == nil or input == "" then
		return
	end
	_G.open_diffview_nth_commit(input)
end

_G.toggle_file_history = function()
	local lib = require("diffview.lib")
	local view = lib.get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	else
		vim.cmd("DiffviewFileHistory %")
	end
end

_G.smart_toggle_bookmark = function()
	local service = require("bookmarks.domain.service")
	local repo = require("bookmarks.domain.repo")
	local location = require("bookmarks.domain.location").get_current_location()
	local existing = repo.find_bookmark_by_location(location)

	if existing then
		-- 如果已存在，直接取消标记（传入空字符串作为名称即可静默取消）
		service.toggle_mark("", location)
		require("bookmarks.sign").safe_refresh_signs()
		pcall(function()
			require("bookmarks.tree.operate").refresh()
		end)
	else
		-- 如果不存在，调用插件原生的 toggle_mark 以弹出输入框让用户输入内容
		require("bookmarks").toggle_mark()
	end
end

-- 关闭“未显示在任何窗口”的隐藏 buffer（保留当前所有可见窗口里的文件）
-- 场景：左右分屏各显示一个文件，但左侧窗口历史里还有很多“看不见”的 buffer，不想一个个 :bd。
_G.bufdel_hidden = function()
	-- 收集所有 tabpage 的可见 buffer
	local visible = {}
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
			local b = vim.api.nvim_win_get_buf(win)
			visible[b] = true
		end
	end

	local deleted, skipped_modified = 0, 0
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if not visible[b] and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
			-- 不动特殊 buffer / 终端 / 提示窗口
			local bt = vim.bo[b].buftype
			if bt == "" then
				if vim.bo[b].modified then
					skipped_modified = skipped_modified + 1
				else
					local ok = pcall(vim.api.nvim_buf_delete, b, { force = false })
					if ok then
						deleted = deleted + 1
					end
				end
			end
		end
	end

	local msg = string.format("已清理隐藏 buffer：%d 个", deleted)
	if skipped_modified > 0 then
		msg = msg .. string.format("（跳过未保存：%d 个）", skipped_modified)
	end
	vim.notify(msg, vim.log.levels.INFO, { title = "buffer" })
end

return {
	["i|jk"] = map_cmd("<Esc>"):with_noremap():with_silent():with_desc("Esc Mapping"),
	["i|jj"] = map_cmd("<Esc>"):with_noremap():with_silent():with_desc("Esc Mapping"),
	["i|kj"] = map_cmd("<Esc>"):with_noremap():with_silent():with_desc("Esc Mapping"),
	["n|j"] = map_cmd("jzz"):with_noremap():with_silent():with_desc("moving"),
	["n|k"] = map_cmd("kzz"):with_noremap():with_silent():with_desc("moving"),

	-- ["n|J"] = map_cmd("8jzz"):with_noremap():with_silent(),
	["n|K"] = map_cmd("8kzz"):with_noremap():with_silent(),
	-- ["n|<F7>"] = map_cmd("8zh"):with_noremap():with_silent():with_desc("moving"),
	-- ["n|<F8>"] = map_cmd("8zl"):with_noremap():with_silent():with_desc("moving"),
	["n|H"] = map_cmd("8zh"):with_noremap():with_silent():with_desc("moving"),
	["n|L"] = map_cmd("8zl"):with_noremap():with_silent():with_desc("moving"),
	["n|<leader>sa"] = map_cr("wa"):with_noremap():with_silent():with_desc("save all files"),
	["n|<leader>q"] = map_cr("q"):with_noremap():with_silent():with_desc("quit"),
	["n|<leader>gi"] = map_cr("GoImports"):with_noremap():with_silent():with_desc("GoImports"),
	["n|<leader>gb"] = map_cr("Git blame"):with_noremap():with_silent():with_desc("Git blame file"),
	["n|<leader>go"] = map_cr("GoImpl"):with_noremap():with_silent():with_desc("GoImpl"),
	["n|<leader>bo"] = map_cr("BufDelOthers"):with_noremap():with_silent():with_desc("BufDelOthers"),
	["n|<leader>bh"] = map_callback(function()
			_G.bufdel_hidden()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("BufDelHidden (keep visible)"),
	-- noice
	["n|<leader>nh"] = map_cr("Noice history"):with_noremap():with_silent():with_desc("Noice history"),
	["n|<leader>e"] = map_cr("Noice dismiss"):with_noremap():with_silent():with_desc("Noice dismiss"),

	["n|<leader>m"] = map_callback(function()
			if _G.switch_bookmark_project_list then
				_G.switch_bookmark_project_list()
			end
			require("bookmarks").goto_bookmark()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("Bookmarks: List with preview"),
	["n|mm"] = map_callback(function()
			if _G.switch_bookmark_project_list then
				_G.switch_bookmark_project_list()
			end
			_G.smart_toggle_bookmark()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("Bookmarks: Smart toggle mark"),
	["n|mn"] = map_callback(function()
			require("bookmarks").goto_next_bookmark()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("Bookmarks: Next mark"),
	["n|mp"] = map_callback(function()
			require("bookmarks").goto_prev_bookmark()
		end)
		:with_noremap()
		:with_silent()
		:with_desc("Bookmarks: Prev mark"),
	["n|<leader>sw"] = map_cr("Telescope grep_string"):with_desc("Search word under cursor"),
	["v|<leader>sw"] = map_cr("lua _G.search_visual_selection()"):with_desc("Search selection"),
	["n|<leader>cg"] = map_cr("lua _G.copy_global_path_with_line()")
		:with_noremap()
		:with_silent()
		:with_desc("Copy global path with line"),
	["n|<leader>cp"] = map_cr("lua _G.copy_git_relative_path_with_line()")
		:with_noremap()
		:with_silent()
		:with_desc("Copy relative path with line"),
	["n|<leader>gc"] = map_cr("lua _G.toggle_diffview('master')")
		:with_noremap()
		:with_silent()
		:with_desc("git: Toggle diff against master"),
	["n|<leader>g0"] = map_cr("lua _G.open_diffview()")
		:with_noremap()
		:with_silent()
		:with_desc("git: Diff (working tree)"),
	["n|<leader>g1"] = map_cr("lua _G.open_diffview_nth_commit(1)")
		:with_noremap()
		:with_silent()
		:with_desc("git: Diff (HEAD)"),
	["n|<leader>g2"] = map_cr("lua _G.open_diffview_nth_commit(2)")
		:with_noremap()
		:with_silent()
		:with_desc("git: Diff (HEAD~1)"),
	["n|<leader>gn"] = map_cr("lua _G.open_diffview_prompt_commit()")
		:with_noremap()
		:with_silent()
		:with_desc("git: Diff (prompt Nth commit)"),
	["n|<leader>gd"] = map_cr("lua _G.toggle_diffview()")
		:with_noremap()
		:with_silent()
		:with_desc("git: Toggle diffview"),
	["n|<leader>gf"] = map_cr("lua _G.toggle_file_history()")
		:with_noremap()
		:with_silent()
		:with_desc("git: Toggle file history"),
	-- auto-session
	["n|<leader>ss"] = map_callback(function()
			require("auto-session.pickers.telescope").extension_search_session({
				picker_opts = {
					default_text = vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
				},
			})
		end)
		:with_noremap()
		:with_silent()
		:with_desc("Session: Search (Current Project)"),
	["n|<leader>as"] = map_cr("AutoSession save"):with_noremap():with_silent():with_desc("Session: Save"),
	-- git-worktree
	["n|<leader>gw"] = map_callback(function()
			require("telescope").extensions.git_worktree.git_worktrees({
				path_display = { "absolute" },
			})
		end)
		:with_noremap()
		:with_silent()
		:with_desc("Git: Worktrees"),
	["n|<leader>gN"] = map_cr("Telescope git_worktree create_git_worktree")
		:with_noremap()
		:with_silent()
		:with_desc("Git: Create worktree"),
	-- sidekick
	["n|<leader>aa"] = map_cr("Sidekick cli toggle name='coco'"):with_noremap():with_silent():with_desc("Sidekick: Toggle Coco"),
	["n|<leader>am"] = map_cr("Sidekick cli select"):with_noremap():with_silent():with_desc("Sidekick: Select CLI"),
	["n|<leader>af"] = map_cr("Sidekick cli send msg='{file}'")
		:with_noremap()
		:with_silent()
		:with_desc("Sidekick: Send File"),
	["v|<leader>at"] = map_cr("Sidekick cli send msg='{selection}'")
		:with_noremap()
		:with_silent()
		:with_desc("Sidekick: Send Selection"),
}
