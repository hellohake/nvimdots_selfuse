local bind = require("keymap.bind")
local map_cmd = bind.map_cmd
local map_cr = bind.map_cr

return {
	["i|jk"] = map_cmd("<Esc>"):with_noremap():with_silent():with_desc("Esc Mapping"),
	["i|jj"] = map_cmd("<Esc>"):with_noremap():with_silent():with_desc("Esc Mapping"),
	["i|kj"] = map_cmd("<Esc>"):with_noremap():with_silent():with_desc("Esc Mapping"),
	["n|j"] = map_cmd("jzz"):with_noremap():with_silent():with_desc("moving"),
	["n|k"] = map_cmd("kzz"):with_noremap():with_silent():with_desc("moving"),

	-- ["n|J"] = map_cmd("8jzz"):with_noremap():with_silent(),
	["n|K"] = map_cmd("8kzz"):with_noremap():with_silent(),
	-- ["n|<F7>"] = map_cmd("8zh"):with_noremap():with_silent():with_desc("moving"),
	-- ["n|<F8>"] = map_cmd("8zl"):with_noremap():with_silent():with_desc("moving"),
	["n|H"] = map_cmd("8zh"):with_noremap():with_silent():with_desc("moving"),
	["n|L"] = map_cmd("8zl"):with_noremap():with_silent():with_desc("moving"),
	["n|<leader>sa"] = map_cr("wa"):with_noremap():with_silent():with_desc("save all files"),
	["n|<leader>q"] = map_cr("q"):with_noremap():with_silent():with_desc("quit"),
	["n|<leader>gi"] = map_cr("GoImports"):with_noremap():with_silent():with_desc("GoImports"),
	["n|<leader>gb"] = map_cr("Git blame"):with_noremap():with_silent():with_desc("Git blame file"),
	["n|<leader>go"] = map_cr("GoImpl"):with_noremap():with_silent():with_desc("GoImpl"),
	["n|<leader>bo"] = map_cr("BufDelOthers"):with_noremap():with_silent():with_desc("BufDelOthers"),
	-- noice
	["n|<leader>nh"] = map_cr("Noice history"):with_noremap():with_silent():with_desc("Noice history"),
	["n|<leader>e"] = map_cr("Noice dismiss"):with_noremap():with_silent():with_desc("Noice dismiss"),
}
