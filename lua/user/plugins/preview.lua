local custom = {}

-- custom["itaranto/plantuml.nvim"] = {
-- 	"https://gitlab.com/itaranto/plantuml.nvim",
-- 	version = "*",
-- 	config = function()
-- 		require("plantuml").setup()
-- 	end,
-- }

custom["itaranto/preview.nvim"] = {
	"https://gitlab.com/itaranto/preview.nvim",
	version = "*",

	config = function()
		local opts = {
			-- Your options.
			previewers_by_ft = {
				markdown = {
					name = "pandoc_wkhtmltopdf",
					renderer = { type = "command", opts = { cmd = { "zathura" } } },
				},
				plantuml = {
					name = "plantuml_text",
					renderer = { type = "buffer" },
				},
				groff = {
					name = "groff_ms_pdf",
					renderer = { type = "command", opts = { cmd = { "zathura" } } },
				},
			},
			render_on_write = true,
		}
		require("preview").setup()
	end,
}

return custom
