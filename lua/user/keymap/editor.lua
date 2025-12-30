local bind = require("keymap.bind")
local map_cmd = bind.map_cmd
local map_cr = bind.map_cr

_G.copy_relative_path_with_line = function()
	local path = vim.fn.expand("%") -- 相对 cwd
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
	-- noice
	["n|<leader>nh"] = map_cr("Noice history"):with_noremap():with_silent():with_desc("Noice history"),
	["n|<leader>e"] = map_cr("Noice dismiss"):with_noremap():with_silent():with_desc("Noice dismiss"),

	["n|<leader>m"] = map_cr("<CMD>Telescope vim_bookmarks current_file<CR>")
		:with_noremap()
		:with_silent()
		:with_desc("Telescope: File Bookmarks"),
	["n|<leader>fm"] = map_cr("<CMD>Telescope vim_bookmarks all<CR>")
		:with_noremap()
		:with_silent()
		:with_desc("Telescope: Project Bookmarks"),
	["n|<leader>sw"] = map_cr("Telescope grep_string"):with_desc("Search word under cursor"),
	["v|<leader>sw"] = map_cr("lua _G.search_visual_selection()"):with_desc("Search selection"),
	["n|<leader>cg"] = map_cr("lua _G.copy_relative_path_with_line()")
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
	["n|<leader>gd"] = map_cr("lua _G.toggle_diffview()"):with_noremap():with_silent():with_desc("git: Toggle diffview"),
}
