local tool = {}
tool["MattesGroeger/vim-bookmarks"] = {
	lazy = false, -- 书签需要开机加载，否则无法显示图标
	dependencies = {
		"tom-anders/telescope-vim-bookmarks.nvim",
	},
	init = function()
		vim.g.bookmark_save_per_working_dir = 1
		vim.g.bookmark_auto_save = 1

		vim.g.bookmark_sign = ""
		vim.g.bookmark_annotation_sign = "☰"

		-- 开启默认快捷键 (mm:打标, mi:注释, mn/mp:跳转)
		vim.g.bookmark_no_default_key_mappings = 0
	end,
	config = function()
		pcall(function()
			require("telescope").load_extension("vim_bookmarks")
		end)
	end,
}

return tool
