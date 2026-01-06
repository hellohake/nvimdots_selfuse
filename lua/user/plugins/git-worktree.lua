return {
	["ThePrimeagen/git-worktree.nvim"] = {
		lazy = true,
		event = "VeryLazy",
		config = function()
			local git_worktree = require("git-worktree")
			git_worktree.setup({})

			-- 自动化：创建新 Worktree 时自动为根目录的共享文件创建软链接
			git_worktree.on_tree_change(function(op, metadata)
				if op == git_worktree.Operations.Create then
					local shared_items = { ".coco", ".ai_doc", "AGENTS.md" }
					local target_path = metadata.path
					local root = vim.fn.fnamemodify(target_path, ":h")

					for _, item in ipairs(shared_items) do
						local source = root .. "/" .. item
						local dest = target_path .. "/" .. item
						-- 如果源文件存在且目标不存在，则创建软链接
						if vim.fn.getftype(source) ~= "" and vim.fn.getftype(dest) == "" then
							os.execute(string.format("ln -s %s %s", source, dest))
						end
					end
				end
			end)

			-- 猴子补丁修复 Telescope 扩展中的高亮报错
			local ok, telescope = pcall(require, "telescope")
			if ok then
				pcall(telescope.load_extension, "git_worktree")
				local wt_ext = telescope.extensions.git_worktree
				if wt_ext and wt_ext.git_worktrees then
					-- 完全重写 telescope_git_worktree 以修复高亮和路径问题
					wt_ext.git_worktrees = function(opts)
						local pickers = require("telescope.pickers")
						local finders = require("telescope.finders")
						local utils = require("telescope.utils")
						local strings = require("plenary.strings")
						local entry_display = require("telescope.pickers.entry_display")
						local conf = require("telescope.config").values
						local action_set = require("telescope.actions.set")
						local git_wt = require("git-worktree")

						opts = opts or {}
						local output = utils.get_os_command_output({ "git", "worktree", "list" })
						local results = {}
						local widths = { path = 0, sha = 0, branch = 0 }

						for _, line in ipairs(output) do
							local fields = vim.split(string.gsub(line, "%s+", " "), " ")
							if fields[1] and fields[2] ~= "(bare)" then
								local entry = { path = fields[1], sha = fields[2], branch = fields[3] or "" }
								widths.branch = math.max(widths.branch, strings.strdisplaywidth(entry.branch))
								widths.path = math.max(widths.path, strings.strdisplaywidth(entry.path))
								widths.sha = math.max(widths.sha, strings.strdisplaywidth(entry.sha))
								table.insert(results, entry)
							end
						end

						if #results == 0 then return end

						local displayer = entry_display.create({
							separator = "  ",
							items = {
								{ width = widths.branch },
								{ width = widths.path },
								{ width = widths.sha },
							},
						})

						local make_display = function(entry)
							return displayer({
								{ entry.branch, "TelescopeResultsIdentifier" },
								entry.path, -- 修复：直接传字符串，避免渲染器找不存在的高亮组
								entry.sha,
							})
						end

						pickers.new(opts, {
							prompt_title = "Git Worktrees",
							finder = finders.new_table({
								results = results,
								entry_maker = function(entry)
									entry.value = entry.branch
									entry.ordinal = entry.branch .. " " .. entry.path
									entry.display = make_display
									return entry
								end,
							}),
							sorter = conf.generic_sorter(opts),
							attach_mappings = function(prompt_bufnr, map)
								action_set.select:replace(function()
									local selection = require("telescope.actions.state").get_selected_entry()
									require("telescope.actions").close(prompt_bufnr)

									-- 切换前强制保存所有文件，防止因未保存导致切换失败
									vim.cmd("silent! wa")

									-- 执行插件切换逻辑
									git_wt.switch_worktree(selection.path)

									-- 强制延时执行 CD，确保路径切换成功且不被其他插件拦截
									vim.schedule(function()
										vim.cmd("cd " .. selection.path)
									end)
								end)
								map("i", "<c-d>", function()
									local selection = require("telescope.actions.state").get_selected_entry()
									require("telescope.actions").close(prompt_bufnr)
									git_wt.delete_worktree(selection.path)
								end)
								return true
							end,
						}):find()
					end
				end
			end
		end,
	},
}
