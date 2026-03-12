local M = {}

M.setup = function()
	require("modules.utils").load_plugin("neoconf", {
		-- send new configuration to lsp clients when changing json settings
		live_reload = true,
		-- name of the local settings files
		local_settings = ".neoconf.json",
		-- name of the global settings file in your Neovim config directory
		global_settings = "neoconf.json",
		-- import existing settings from other plugins
		import = {
			vscode = true, -- local .vscode/settings.json
			coc = true, -- global/local coc-settings.json
			nlsp = true, -- global/local nlsp-settings.nvim json settings
		},
	})

	-- 修复：neoconf.nvim 在 notify 的 on_open 里把 window-local option `spell` 当成 buf-local 来 set。
	-- 这会让 nvim-notify 的渲染服务报错并停止，表现为“后续完全不弹窗”。
	pcall(function()
		local util = require("neoconf.util")
		if type(util) ~= "table" then return end

		util.notify = function(msg, level)
			vim.notify(msg, level, {
				title = "settings.nvim",
				on_open = function(win)
					pcall(vim.api.nvim_set_option_value, "conceallevel", 3, { win = win, scope = "local" })
					local buf = vim.api.nvim_win_get_buf(win)
					pcall(vim.api.nvim_set_option_value, "filetype", "markdown", { buf = buf, scope = "local" })
					-- `spell` 是 window-local
					pcall(vim.api.nvim_set_option_value, "spell", false, { win = win, scope = "local" })
				end,
			})
		end
	end)
end

return M
