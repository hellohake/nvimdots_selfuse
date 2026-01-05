return function()
	local icons = { ui = require("modules.utils.icons").get("ui", true) }
	local lga_actions = require("telescope-live-grep-args.actions")

	vim.api.nvim_create_autocmd("User", {
		pattern = "TelescopePreviewerLoaded",
		callback = function()
			vim.wo.wrap = true
			vim.wo.linebreak = true -- 智能折行，不在单词中间截断
		end,
	})

	local function quote_prompt_with_postfix(postfix)
		return function(prompt_bufnr)
			local action_state = require("telescope.actions.state")
			local picker = action_state.get_current_picker(prompt_bufnr)
			local prompt = picker:_get_prompt()
			local trimmed = vim.trim(prompt)
			if trimmed == "" then
				return
			end

			-- 核心逻辑：检查是否已经包裹了双引号，避免重复转义
			if trimmed:sub(1, 1) == '"' and trimmed:sub(-1) == '"' then
				-- 如果已经有引号了，且还没加过该后缀，则直接追加后缀
				if not trimmed:find(postfix, 1, true) then
					picker:set_prompt(trimmed .. postfix)
				end
			else
				-- 没有引号，清理掉可能残留的首尾单边引号，然后统一重新包裹
				local clean = trimmed:gsub('^"', ""):gsub('"$', "")
				picker:set_prompt('"' .. clean .. '"' .. postfix)
			end
		end
	end

	require("modules.utils").load_plugin("telescope", {
		defaults = {
			vimgrep_arguments = {
				"rg",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
				"--smart-case",
			},
			initial_mode = "insert",
			prompt_prefix = " " .. icons.ui.Telescope .. " ",
			selection_caret = icons.ui.ChevronRight,
			scroll_strategy = "limit",
			results_title = false,
			layout_strategy = "horizontal",
			--path_display = { "absolute" },
			-- path_display = { "smart" },
			path_display = { "truncate" },
			wrap_results = true,
			selection_strategy = "reset",
			sorting_strategy = "ascending",
			color_devicons = true,
			file_ignore_patterns = {
				"kitex_gen/",
				".git/",
				".cache",
				"build/",
				"%.class",
				"%.pdf",
				"%.mkv",
				"%.mp4",
				"%.zip",
			},
			layout_config = {
				horizontal = {
					prompt_position = "top",
					preview_width = 0.55,
					results_width = 0.8,
				},
				vertical = {
					mirror = false,
				},
				width = 0.85,
				height = 0.92,
				preview_cutoff = 120,
			},
			file_previewer = require("telescope.previewers").vim_buffer_cat.new,
			grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
			qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
			file_sorter = require("telescope.sorters").get_fuzzy_file,
			generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
			buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
		},
		extensions = {
			fzf = {
				fuzzy = true,
				override_generic_sorter = true,
				override_file_sorter = true,
				case_mode = "smart_case",
			},
			frecency = {
				show_scores = true,
				show_unindexed = true,
				ignore_patterns = { "*.git/*", "*/tmp/*" },
			},
			live_grep_args = {
				auto_quoting = true, -- 恢复为 true
				mappings = { -- extend mappings
					i = {
						["<C-k>"] = quote_prompt_with_postfix(""),
						["<C-i>"] = quote_prompt_with_postfix(" --iglob "),
						["<C-g>"] = quote_prompt_with_postfix(" -F "),
					},
				},
			},
			undo = {
				side_by_side = true,
				mappings = {
					i = {
						["<cr>"] = require("telescope-undo.actions").yank_additions,
						["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
						["<C-cr>"] = require("telescope-undo.actions").restore,
					},
				},
			},
			advanced_git_search = {
				diff_plugin = "diffview",
				git_flags = { "-c", "delta.side-by-side=true" },
				entry_default_author_or_date = "author", -- one of "author" or "date"
			},
		},
	})

	require("telescope").load_extension("frecency")
	require("telescope").load_extension("fzf")
	require("telescope").load_extension("live_grep_args")
	require("telescope").load_extension("notify")
	require("telescope").load_extension("projects")
	require("telescope").load_extension("undo")
	require("telescope").load_extension("zoxide")
	pcall(require("telescope").load_extension, "persisted")
	require("telescope").load_extension("advanced_git_search")
end
