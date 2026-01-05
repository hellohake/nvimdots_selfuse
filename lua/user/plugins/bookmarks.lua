local tool = {}

tool["LintaoAmons/bookmarks.nvim"] = {
	name = "bookmarks",
	lazy = false,
	dependencies = {
		{ "kkharji/sqlite.lua" },
		{ "nvim-telescope/telescope.nvim" },
		{ "stevearc/dressing.nvim" },
	},
	config = function()
		require("bookmarks").setup({
			picker = {
				entry_display = function(bookmark, _)
					local name = bookmark.name
					local filename = vim.fn.fnamemodify(bookmark.location.path, ":t")
					local path = vim.fn.fnamemodify(bookmark.location.path, ":~")
					return string.format("%s │ %s │ %s", name, filename, path)
				end,
			},
		})

		-- 项目隔离逻辑：自动为每个项目创建/切换独立的书签列表
		_G.switch_bookmark_project_list = function()
			local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
			local ok, Service = pcall(require, "bookmarks.domain.service")
			local ok2, Repo = pcall(require, "bookmarks.domain.repo")
			if not (ok and ok2) then
				return
			end

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
				-- 创建后再次查找并设置，确保激活成功
				vim.defer_fn(function()
					local new_lists = Repo.find_lists()
					for _, list in ipairs(new_lists) do
						if list.name == project_name then
							Service.set_active_list(list.id)
							break
						end
					end
				end, 50)
			end
		end

		-- 在启动和切换目录时自动执行
		vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
			callback = function()
				-- 延迟执行，确保插件完全加载
				vim.defer_fn(_G.switch_bookmark_project_list, 200)
			end,
		})
	end,
}

return tool
