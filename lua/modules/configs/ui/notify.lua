return function()
	local notify = require("notify")
	local icons = {
		diagnostics = require("modules.utils.icons").get("diagnostics"),
		ui = require("modules.utils.icons").get("ui"),
	}

	require("modules.utils").load_plugin("notify", {
		---@usage Animation style one of { "fade", "slide", "fade_in_slide_out", "static" }
		stages = "fade",
		---@usage Function called when a new window is opened, use for changing win settings/config
		on_open = function(win)
			vim.api.nvim_set_option_value("winblend", 0, { scope = "local", win = win })
			vim.api.nvim_win_set_config(win, { zindex = 90 })
		end,
		---@usage Function called when a window is closed
		on_close = nil,
		---@usage timeout for notifications in ms, default 5000
		timeout = 1000,
		-- @usage User render fps value
		fps = 20,
		-- Render function for notifications. See notify-render()
		render = "default",
		---@usage highlight behind the window for stages that change opacity
		background_colour = "NotifyBackground",
		---@usage minimum width for notification windows
		minimum_width = 50,
		---@usage notifications with level lower than this would be ignored. [ERROR > WARN > INFO > DEBUG > TRACE]
		level = "INFO",
		---@usage Icons for the different levels
		icons = {
			ERROR = icons.diagnostics.Error,
			WARN = icons.diagnostics.Warning,
			INFO = icons.diagnostics.Information,
			DEBUG = icons.ui.Bug,
			TRACE = icons.ui.Pencil,
		},
	})

	-- 关键：不要把 `vim.notify` 永久绑定到 nvim-notify。
	-- 否则 Noice 即使启用了 `notify/messages`，也接管不到通知，`:Noice history` 自然是空的。
	-- 这里做一层路由：Noice 已加载就走 Noice（会记录 history），否则回退到 nvim-notify。
	vim.notify = function(msg, level, opts)
		local ok, noice = pcall(require, "noice")
		if ok and type(noice.notify) == "function" then
			return noice.notify(msg, level, opts)
		end
		return notify(msg, level, opts)
	end

	-- 兼容：有些插件会直接 `require("notify")(... )` 绕过 `vim.notify`。
	-- 这里把 `notify` 模块也代理到 `vim.notify`，保证同样能进入 Noice。
	local notify_proxy = setmetatable({}, {
		__call = function(_, msg, level, opts)
			return vim.notify(msg, level, opts)
		end,
		__index = notify,
	})
	package.loaded["notify"] = notify_proxy
end
