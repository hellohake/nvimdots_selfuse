local custom = {}
-- https://github.com/folke/noice.nvim
custom["noice.nvim"] = {
	-- lazy.nvim
	"folke/noice.nvim",
	-- 直接常驻加载，避免错过早期 message/notify，且 `:Noice history` 始终可用
	lazy = false,
	opts = {
		-- add any options here
	},
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		"MunifTanjim/nui.nvim",
		-- OPTIONAL:
		--   `nvim-notify` is only needed, if you want to use the notification view.
		--   If not available, we use `mini` as the fallback
		"rcarriga/nvim-notify",
	},
	config = function()
		require("noice").setup({
			-- 说明：`:messages` 是 Vim 自己的 message-history；Noice 的 `:Noice history`
			-- 只展示它“接管/路由”的 message/notify。
			-- 开启 notify/messages 接管后，大多数 `vim.notify()` / 普通 msg 也会进入 Noice history。
			messages = {
				enabled = true,
				view = "notify",
			},
			notify = {
				enabled = true,
				view = "notify",
			},
			commands = {
				history = {
					-- 扩大 history 覆盖范围：默认只收 kind=="" 的 msg_show，
					-- 像 csv.vim 这种 `echomsg` 往往会被过滤掉，导致你看到“history 为空”。
					filter = {
						any = {
							{ event = "notify" },
							{ error = true },
							{ warning = true },
							{ event = "msg_show" },
							{ event = "lsp", kind = "message" },
						},
					},
				},
			},
			lsp = {
				-- 这里的“3 个补全提示”截图实际是 `textDocument/signatureHelp` 的浮窗被重复渲染。
				-- Noice 默认会接管/展示 LSP 的 signature help；如果同时还有其他 UI（如 lspsaga / 内置 handler / 其他签名插件），
				-- 就会出现多个相同签名框叠加。
				signature = {
					enabled = false,
				},
				-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					-- ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
				},
			},
			-- you can enable a preset for easier configuration
			presets = {
				bottom_search = true, -- use a classic bottom cmdline for search
				command_palette = true, -- position the cmdline and popupmenu together
				long_message_to_split = true, -- long messages will be sent to a split
				inc_rename = false, -- enables an input dialog for inc-rename.nvim
				lsp_doc_border = false, -- add a border to hover docs and signature help
			},
		})
	end,
}
return custom
