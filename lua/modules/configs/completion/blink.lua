return function()
	local icons = {
		kind = require("modules.utils.icons").get("kind"),
		type = require("modules.utils.icons").get("type"),
		cmp = require("modules.utils.icons").get("cmp"),
	}

	require("modules.utils").load_plugin("blink.cmp", {
		keymap = {
			preset = "default",
			["<C-k>"] = { "show", "show_documentation", "hide_documentation" },
			["<C-e>"] = { "hide", "fallback" },
			["<CR>"] = { "accept", "fallback" },

			["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
			["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },

			["<C-p>"] = { "select_prev", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },

			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
		},
		appearance = {
			use_nvim_cmp_as_default = false,
			nerd_font_variant = "mono",
			kind_icons = vim.tbl_extend("force", icons.kind, icons.type, icons.cmp),
		},
		snippets = { preset = "luasnip" },
		-- 避免和其他 LSP UI 叠加导致重复的签名框
		signature = { enabled = false },
		completion = {
			menu = {
				border = "rounded",
				winhighlight = "Normal:Pmenu,CursorLine:PmenuSel,Search:PmenuSel",
				draw = {
					columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
					treesitter = { "lsp" },
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 500,
				window = { border = "rounded" },
			},
			ghost_text = {
				enabled = true,
			},
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			providers = {
				lsp = {
					fallbacks = { "buffer" },
				},
				path = {
					opts = {
						show_hidden_files_by_default = true,
					},
				},
				buffer = {
					min_keyword_length = 2,
				},
			},
		},
	})
end
