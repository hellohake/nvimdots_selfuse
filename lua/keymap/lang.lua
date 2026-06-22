local bind = require("keymap.bind")
local map_cr = bind.map_cr

local mappings = {
	plugins = {
		-- Plugin: render-markdown.nvim
		["n|<leader>tm"] = map_cr("RenderMarkdown toggle")
			:with_noremap()
			:with_silent()
			:with_desc("tool: toggle markdown render (raw <-> rendered)"),
		-- Plugin: MarkdownPreview
		["n|<F12>"] = map_cr("MarkdownPreviewToggle"):with_noremap():with_silent():with_desc("tool: Preview markdown"),
	},
}

bind.nvim_load_mapping(mappings.plugins)
