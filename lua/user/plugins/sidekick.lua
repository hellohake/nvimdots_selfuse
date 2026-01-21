return {
	["sidekick.nvim"] = {
		"folke/sidekick.nvim",
		event = "VeryLazy",
		opts = {
			cli = {
				tools = {
					coco = {
						cmd = { "coco" },
						title = "Coco AI",
					},
				},
			},
			-- nes = { enabled = false }, -- 可选：如果不需要 Next Edit Suggestions 功能，取消注释此行
		},
	},
}
