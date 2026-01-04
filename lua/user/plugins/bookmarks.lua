local tool = {}

tool["LintaoAmons/bookmarks.nvim"] = {
	dir = "/data00/home/lihao.hellohake/github_repo/nvim_plugin/bookmarks.nvim",
	name = "lintao-bookmarks",
	lazy = false,
	dependencies = {
		{ "kkharji/sqlite.lua" },
		{ "nvim-telescope/telescope.nvim" },
		{ "stevearc/dressing.nvim" },
	},
	config = function()
		require("bookmarks").setup()

		-- 项目隔离逻辑：自动为每个项目创建/切换独立的书签列表
		local function switch_project_list()
			local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
			local Service = require("bookmarks.domain.service")
			local Repo = require("bookmarks.domain.repo")

			local lists = Repo.find_lists()
			local target_list = nil
			for _, list in ipairs(lists) do
				if list.name == project_name then
					target_list = list
					break
				end
			end

			if target_list then
				Service.set_active_list(target_list.id)
			else
				Service.create_list(project_name)
			end
		end

		-- 在启动和切换目录时自动执行
		vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
			callback = function()
				-- 延迟执行，确保插件完全加载
				vim.defer_fn(switch_project_list, 100)
			end,
		})
	end,
}

return tool
