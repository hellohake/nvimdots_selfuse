local diffview_wrap = false -- 改成 true 后，<leader>gd 打开的 diff 代码默认自动换行

local function set_diffview_wrap(enabled)
	vim.opt_local.wrap = enabled
	vim.opt_local.linebreak = enabled
	vim.opt_local.breakindent = enabled
end

local function toggle_diffview_wrap()
	local enabled = not vim.wo.wrap
	set_diffview_wrap(enabled)
	vim.notify("Diffview wrap: " .. (enabled and "on" or "off"), vim.log.levels.INFO, { title = "diffview" })
end

return {
	hooks = {
		diff_buf_read = function()
			set_diffview_wrap(diffview_wrap)
		end,
	},
	keymaps = {
		view = {
			["<leader>uw"] = toggle_diffview_wrap,
			["<leader>e"] = false,
		},
		file_panel = {
			["<leader>e"] = false,
		},
		file_history_panel = {
			["<leader>e"] = false,
		},
	},
}
