return function()
	vim.api.nvim_set_hl(
		0,
		"FlashLabel",
		{ bold = true, fg = "#1e1e2e", bg = "#f9e2af", ctermfg = "Black", ctermbg = "Yellow" }
	)
	vim.api.nvim_set_hl(0, "FlashCurrent", { bold = true, fg = "#1e1e2e", bg = "#fab387" })

	require("modules.utils").load_plugin("flash", {
		labels = "asdfghjklqwertyuiopzxcvbnm",
		label = {
			-- allow uppercase labels
			uppercase = true,
			-- add a label for the first match in the current window.
			-- you can always jump to the first match with `<CR>`
			current = true,
			-- for the current window, label targets closer to the cursor first
			distance = true,
		},
		modes = {
			search = { enabled = false },
			-- options used when flash is activated through
			-- `f`, `F`, `t`, `T`, `;` and `,` motions
			char = {
				enabled = true,
				-- keep labels visible so repeated chars are easier to distinguish
				autohide = false,
				-- label every target so `f/F/t/T` can disambiguate repeated chars fast
				jump_labels = true,
				-- keep the candidate set focused like native `f` to reduce visual noise
				multi_line = false,
				-- When using jump labels, don't use these keys
				-- This allows using those keys directly after the motion
				label = { exclude = "hjkli" },
			},
		},
	})
end
