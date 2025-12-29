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

		-- 解决在只读目录(如 go/pkg/mod)下无法保存书签的问题
		-- 当进入只读目录时禁用自动保存，避免报错；离开时恢复
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			pattern = "*/go/pkg/mod/*",
			callback = function()
				vim.g.bookmark_auto_save = 0
			end,
		})

		vim.api.nvim_create_autocmd({ "BufLeave" }, {
			pattern = "*/go/pkg/mod/*",
			callback = function()
				vim.g.bookmark_auto_save = 1
			end,
		})
	end,
	config = function()
		pcall(function()
			require("telescope").load_extension("vim_bookmarks")
		end)
	end,
}

return tool
