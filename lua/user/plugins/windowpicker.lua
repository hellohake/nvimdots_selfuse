local custom = {}

custom["s1n7ax/nvim-window-picker"] = {
	"s1n7ax/nvim-window-picker",
	name = "window-picker",
	event = "VeryLazy",
	version = "2.*",
	config = function()
		require("window-picker").setup({
			-- type of hints you want to get
			-- following types are supported
			-- 'statusline-winbar' | 'floating-big-letter'
			-- 'statusline-winbar' draw on 'statusline' if possible, if not 'winbar' will be
			-- 'floating-big-letter' draw big letter on a floating window
			-- used
			hint = "statusline-winbar",

			-- when you go to window selection mode, status bar will show one of
			-- following letters on them so you can use that letter to select the window
			selection_chars = "FJDKSLA;CMRUEIWOQP",
			-- whether to show 'Pick window:' prompt
			show_prompt = true,

			-- prompt message to show to get the user input
			prompt_message = "Pick window: ",
			filter_rules = {
				include_current_win = true,
				bo = {
					filetype = { "fidget", "neo-tree" },
				},
			},
		})
	end,
	keys = {
		{
			"<Leader>pw",
			function()
				local window_number = require("window-picker").pick_window()
				if window_number then
					vim.api.nvim_set_current_win(window_number)
				end
			end,
			mode = { "n" },
			desc = "window picker",
		},
	},
}

return custom
