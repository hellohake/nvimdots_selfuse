local bind = require("keymap.bind")
local map_cr = bind.map_cr

local M = {}

---@param buf integer
function M.lsp(buf)
	return {
		["n|gd"] = bind
			.map_callback(function()
				_G._go_goto_definition_fallback()
			end)
			:with_silent()
			:with_buffer(buf)
			:with_desc("lsp: Goto definition"),
	}
end

return M
