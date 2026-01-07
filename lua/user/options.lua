local options = {
	-- Example
	autoindent = true,
	maxmempattern = 30000,
	sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions",
}

-- Fix NVM path for formatters and LSP
if vim.fn.executable("node") == 0 then
	local nvm_versions_dir = vim.fn.expand("~/.nvm/versions/node")
	local node_versions = vim.fn.glob(nvm_versions_dir .. "/v*", false, true)
	if #node_versions > 0 then
		table.sort(node_versions)
		local latest_node_bin = node_versions[#node_versions] .. "/bin"
		if vim.fn.isdirectory(latest_node_bin) == 1 then
			vim.env.PATH = latest_node_bin .. ":" .. vim.env.PATH
		end
	end
end

-- Fix Telescope highlight groups for some plugins
vim.api.nvim_set_hl(0, "TelescopeResultsIdentifier", { link = "Identifier", default = true })
vim.api.nvim_set_hl(0, "TelescopeResultsDirectory", { link = "Directory", default = true })

return options
