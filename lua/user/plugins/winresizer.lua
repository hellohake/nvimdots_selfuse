local plugin = {}

plugin["simeji/winresizer"] = {
	lazy = false, -- 需要直接加载以生效 keymap
	init = function()
		-- 注意：winresizer 是 Vim Script 插件，必须在插件加载前（init阶段）设置全局变量
		-- 否则插件加载时会读取不到配置，使用默认的 <C-e>

		-- 使用 <C-w>e (Window Edit) 既符合 Vim 窗口操作直觉 (<C-w>前缀)，又无冲突
		vim.g.winresizer_start_key = "<C-w>e"

		-- 其他可选配置
		vim.g.winresizer_vert_resize = 10 -- 左右调整的步长
		vim.g.winresizer_horiz_resize = 3 -- 上下调整的步长

		-- 确保 Enter (13) 为确认键，q (113) 为取消键
		-- 注意：在某些终端环境下，Enter 可能会有所不同，如果回车无效，请尝试使用 Esc (默认也支持确认)
		vim.g.winresizer_keycode_finish = 13
		vim.g.winresizer_keycode_cancel = 113
	end,
}

return plugin
