local custom = {}

custom["codeverse"] = {
	enabled = false,
	-- 使用本地 codeverse 插件
	dir = "/data00/home/lihao.hellohake/github_repo/nvim_plugin/codeverse.vim",
	name = "codeverse.vim",
	-- 仅加载插件本体（提供 `trae#...` vimscript 接口 / `trae.format` 等），
	-- 不再调用它自带的 nvim-cmp 注册逻辑（我们用 blink.cmp source 接入）。
	-- 重要：禁用它的“自动弹出/inline ghost text”与按键映射，否则 InsertEnter 会触发请求导致卡死，
	-- 也会覆盖 blink.cmp 的 <Tab>/<C-k> 等按键。
	init = function()
		-- 禁止插件启动时自动下载/登录/初始化（避免进入 Insert 模式卡死）
		vim.g.codeverse_disable_startup = 1
		vim.g.marscode_disable_startup = 1
		vim.g.trae_disable_startup = 1

		vim.g.codeverse_disable_autocompletion = 1
		vim.g.codeverse_disable_bindings = 1
		vim.g.codeverse_no_map_tab = 1
		-- 兼容变量名
		vim.g.marscode_disable_autocompletion = 1
		vim.g.marscode_disable_bindings = 1
		vim.g.marscode_no_map_tab = 1
		vim.g.trae_disable_autocompletion = 1
		vim.g.trae_disable_bindings = 1
		vim.g.trae_no_map_tab = 1
	end,
	lazy = false,
}

return custom
