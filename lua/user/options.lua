local options = {
	-- Example
	autoindent = true,
	maxmempattern = 30000,
	sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions",
}

-- Fix Telescope highlight groups for some plugins
vim.api.nvim_set_hl(0, "TelescopeResultsIdentifier", { link = "Identifier", default = true })
vim.api.nvim_set_hl(0, "TelescopeResultsDirectory", { link = "Directory", default = true })

return options
