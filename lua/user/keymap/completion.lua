local bind = require("keymap.bind")
local map_cr = bind.map_cr

local M = {}

---@param buf integer
function M.lsp(buf)
	return {
		["n|gd"] = map_cr("Lspsaga goto_definition"):with_silent():with_buffer(buf):with_desc("lsp: Goto definition"),
	}
end

return M