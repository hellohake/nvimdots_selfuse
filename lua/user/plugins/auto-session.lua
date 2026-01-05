return {
	["rmagatti/auto-session"] = {
		lazy = false,
		config = function()
			require("auto-session").setup({
				suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
				git_use_branch_name = true,
				cwd_change_handling = true,
				session_lens = {
					load_on_setup = true,
					previewer = false,
					picker_opts = {
						border = true,
					},
				},
			})
		end,
	},
}
