return {
	tmux_border = {
		{
			"VimEnter,VimResume",
			"*",
			[[lua if vim.env.TMUX and vim.env.TMUX ~= '' then vim.fn.jobstart({ 'tmux', 'set', '-w', 'pane-border-status', 'off' }, { detach = true }) end]],
		},
		{
			"VimLeave,VimSuspend",
			"*",
			[[lua if vim.env.TMUX and vim.env.TMUX ~= '' then vim.fn.jobstart({ 'tmux', 'set', '-w', 'pane-border-status', 'top' }, { detach = true }) end]],
		},
	},
}
