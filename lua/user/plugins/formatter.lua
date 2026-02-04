local custom = {}

custom["mhartington/formatter.nvim"] = {
	"mhartington/formatter.nvim",
	config = function()
		-- Utilities for creating configurations
		local util = require("formatter.util")
		-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
		require("formatter").setup({
			-- Enable or disable logging
			logging = true,
			-- Set the log level
			log_level = vim.log.levels.WARN,
			-- All formatter configurations are opt-in
			filetype = {
				-- Formatter configurations for filetype "lua" go here
				-- and will be executed in order
				lua = {
					-- "formatter.filetypes.lua" defines default configurations for the
					-- "lua" filetype
					require("formatter.filetypes.lua").stylua,

					-- You can also define your own configuration
					function()
						-- Full specification of configurations is down below and in Vim help
						-- files
						return {
							exe = "stylua",
							args = {
								"--search-parent-directories",
								"--stdin-filepath",
								util.escape_path(util.get_current_buffer_file_path()),
								"--",
								"-",
							},
							stdin = true,
						}
					end,
				},
				javascriptreact = { require("formatter.defaults.prettier") },
				javascript = { require("formatter.defaults.prettier") },
				typescriptreact = { require("formatter.defaults.prettier") },
				typescript = { require("formatter.defaults.prettier") },
				json = { require("formatter.defaults.prettier") },
				markdown = { require("formatter.defaults.prettier") },
				html = { require("formatter.defaults.prettier") },
				css = { require("formatter.defaults.prettier") },
				go = { require("formatter.filetypes.go").gofmt },
				-- Use the special "*" filetype for defining formatter configurations on
				-- any filetype
				["*"] = {
					-- "formatter.filetypes.any" defines default configurations for any
					-- filetype
					require("formatter.filetypes.any").remove_trailing_whitespace,
					-- Remove trailing whitespace without 'sed'
					-- require("formatter.filetypes.any").substitute_trailing_whitespace,
				},
			},
		})
		-- 不要再对所有文件强制 BufWritePost 自动格式化：
		-- 这个会与内置的 LSP format-on-save（BufWritePre）叠加，导致“改到无关区域”。
		-- 需要时手动执行 :Format 或 :FormatWrite。
	end,
}

return custom
