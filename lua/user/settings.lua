local settings = {}

-- `catppuccin`, `catppuccin-latte`, `catppucin-mocha`, `catppuccin-frappe`, `catppuccin-macchiato`.
settings["colorscheme"] = "elflord"
-- settings["colorscheme"] = "murphy"
-- settings["colorscheme"] = "ron"
-- settings["colorscheme"] = "catppuccin"

-- Filetypes in this list will skip lsp formatting if rhs is true.
---@type table<string, boolean>
settings["formatter_block_list"] = {
	thrift = false,
}

settings["disabled_plugins"] = {
	"olimorris/persisted.nvim",
}

return settings
