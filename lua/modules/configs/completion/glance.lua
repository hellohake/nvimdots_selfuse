return function()
	local icons = { ui = require("modules.utils.icons").get("ui", true) }
	local actions = require("glance").actions

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "Glance",
		callback = function()
			vim.schedule(function()
				vim.opt_local.wrap = true
			end)
		end,
	})

	-- 自定义高亮以区分目录和文件 (适配 elflord 主题，确保清晰不刺眼)
	vim.api.nvim_set_hl(0, "GlanceListFilename", { fg = "#90ee90", bold = true }) -- 浅绿色文件名
	vim.api.nvim_set_hl(0, "GlanceListFilepath", { fg = "#87ceeb" })              -- 天蓝色目录路径
	vim.api.nvim_set_hl(0, "GlanceListCount", { fg = "#ffd700" })                 -- 金色计数
	vim.api.nvim_set_hl(0, "GlanceWinBarFilename", { fg = "#90ee90", bold = true })
	vim.api.nvim_set_hl(0, "GlanceWinBarFilepath", { fg = "#87ceeb", italic = true })

	require("modules.utils").load_plugin("glance", {
		height = 25,
		zindex = 50,
		detached = true,
		preview_win_opts = {
			cursorline = true,
			number = true,
			wrap = true,
		},
		border = {
			enable = require("core.settings").transparent_background,
			top_char = "―",
			bottom_char = "―",
		},
		list = {
			position = "right",
			width = 0.5,
		},
		folds = {
			folded = true, -- Automatically fold list on startup
			fold_closed = icons.ui.ArrowClosed,
			fold_open = icons.ui.ArrowOpen,
		},
		indent_lines = { enable = true },
		winbar = { enable = true },
		mappings = {
			list = {
				["k"] = actions.previous,
				["j"] = actions.next,
				["<Up>"] = actions.previous,
				["<Down>"] = actions.next,
				["<S-Tab>"] = actions.previous_location, -- Bring the cursor to the previous location skipping groups in the list
				["<Tab>"] = actions.next_location, -- Bring the cursor to the next location skipping groups in the list
				["<C-u>"] = actions.preview_scroll_win(8),
				["<C-d>"] = actions.preview_scroll_win(-8),
				["<CR>"] = actions.jump,
				["v"] = actions.jump_vsplit,
				["s"] = actions.jump_split,
				["t"] = actions.jump_tab,
				["c"] = actions.close_fold,
				["o"] = actions.open_fold,
				["[]"] = actions.enter_win("preview"), -- Focus preview window
				["q"] = actions.close,
				["Q"] = actions.close,
				["<Esc>"] = actions.close,
				["gq"] = actions.quickfix,
			},
			preview = {
				["Q"] = actions.close,
				["<C-c>q"] = actions.close,
				["<C-c>o"] = actions.jump,
				["<C-c>v"] = actions.jump_vsplit,
				["<C-c>s"] = actions.jump_split,
				["<C-c>t"] = actions.jump_tab,
				["<C-p>"] = actions.previous_location,
				["<C-n>"] = actions.next_location,
				["[]"] = actions.enter_win("list"), -- Focus list window
			},
		},
		hooks = {
			before_open = function(results, open, jump, method)
				if #results == 0 then
					vim.notify(
						"This method is not supported by any of the servers registered for the current buffer",
						vim.log.levels.WARN,
						{ title = "Glance" }
					)
				elseif #results == 1 and method == "references" then
					-- 如果只有一条引用，且就是当前位置，Glance 默认不打开。
					-- 这里改为直接打开窗口，让用户确认。或者你可以选择直接 jump(results[1])
					open(results)
				else
					open(results)
				end
			end,
		},
	})
end
