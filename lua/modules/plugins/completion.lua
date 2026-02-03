local completion = {}
local use_copilot = require("core.settings").use_copilot

completion["neovim/nvim-lspconfig"] = {
	lazy = true,
	tag = "v1.0.0",
	event = { "CursorHold", "CursorHoldI" },
	config = require("completion.lsp"),
	dependencies = {
		{ "williamboman/mason.nvim" },
		{ "williamboman/mason-lspconfig.nvim" },
		{ "folke/neoconf.nvim" },
	},
}
completion["nvimdev/lspsaga.nvim"] = {
	lazy = true,
	cmd = "Lspsaga",
	event = "LspAttach",
	config = require("completion.lspsaga"),
	dependencies = { "nvim-tree/nvim-web-devicons" },
}
completion["DNLHC/glance.nvim"] = {
	lazy = true,
	event = "LspAttach",
	config = require("completion.glance"),
}
completion["joechrisellis/lsp-format-modifications.nvim"] = {
	lazy = true,
	event = "LspAttach",
}
completion["nvimtools/none-ls.nvim"] = {
	lazy = true,
	event = { "CursorHold", "CursorHoldI" },
	config = require("completion.null-ls"),
	dependencies = {
		"nvim-lua/plenary.nvim",
		"jay-babu/mason-null-ls.nvim",
	},
}
completion["hrsh7th/nvim-cmp"] = {
	lazy = true,
	event = "InsertEnter",
	config = require("completion.cmp"),
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			build = "make install_jsregexp",
			config = require("completion.luasnip"),
			dependencies = { "rafamadriz/friendly-snippets" },
		},
		{ "saadparwaiz1/cmp_luasnip" },
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/cmp-buffer" },
	},
}
completion["windwp/nvim-autopairs"] = {
	lazy = true,
	event = "InsertEnter",
	config = require("completion.autopairs"),
}
if use_copilot then
	completion["zbirenbaum/copilot.lua"] = {
		enabled = false,
		lazy = true,
		cmd = "Copilot",
		event = "InsertEnter",
		config = require("completion.copilot"),
	}
end

return completion
