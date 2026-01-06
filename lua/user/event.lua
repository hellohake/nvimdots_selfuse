return {
	tmux_border = {
		{ "VimEnter,VimResume", "*", [[if $TMUX != '' | silent !tmux set -w pane-border-status off | endif]] },
		{ "VimLeave,VimSuspend", "*", [[if $TMUX != '' | silent !tmux set -w pane-border-status top | endif]] },
	},
}
