local tool = {}
tool["ibhagwan/fzf-lua"] = {
	lazy = true,
	cmd = "FzfLua",
	-- 可选依赖：如果你系统里没装 fzf 和 bat，最好装一下
	-- sudo apt install fzf bat ripgrep
	config = function()
		local fzf = require("fzf-lua")
		fzf.setup({
			"max-perf", -- 【关键】开启高性能预设，针对大项目优化
			winopts = {
				preview = {
					default = "bat", -- 使用 bat 预览 (更美观)
					layout = "horizontal", -- 水平布局，视野更大
				},
			},
			previewers = {
				builtin = {
					-- 禁用预览窗口的 Treesitter/LSP 高亮，只用简单的语法高亮
					syntax_limit_b = 1024 * 100, -- 限制大文件高亮
					treesitter = { enabled = false }, -- 【关键】关闭预览窗口的 treesitter
				},
			},
			keymap = {
				builtin = {
					["<F1>"] = "toggle-help",
					["<F2>"] = "toggle-fullscreen",
					-- 这里的快捷键仅在 fzf 窗口内有效
					["<C-z>"] = "toggle-preview",
				},
				fzf = {
					["ctrl-z"] = "abort",
				},
			},
		})
	end,
}
return tool
