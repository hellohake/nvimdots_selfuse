return function()
	require("modules.utils").load_plugin("project_nvim", {
		manual_mode = true,
		detection_methods = { "lsp", "pattern" },
		patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "go.mod" },
		ignore_lsp = { "null-ls", "copilot" },
		exclude_dirs = { "**/go/pkg/mod/**" },
		show_hidden = false,
		silent_chdir = true,
		scope_chdir = "global",
		datapath = vim.fn.stdpath("data"),
	})
end
