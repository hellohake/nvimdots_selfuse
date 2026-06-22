return {
	["sidekick.nvim"] = {
		"folke/sidekick.nvim",
		event = "VeryLazy",
		opts = {
			cli = {
				win = {
					keys = {
						hide_ctrl_q = false,
						stopinsert = { "<c-[>", "stopinsert", mode = "t", desc = "enter normal mode" },
					},
				},
				tools = {
					traex = {
						cmd = { "traex" },
						title = "Traex AI",
					},
				},
			},
			-- nes = { enabled = false }, -- 可选：如果不需要 Next Edit Suggestions 功能，取消注释此行
		},
	},
}
