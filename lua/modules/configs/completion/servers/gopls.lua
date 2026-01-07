local socket_path = "/dev/shm/gopls-daemon-lihao.sock"
-- local gopls_bin = "/data00/home/lihao.hellohake/.local/share/nvim/mason/packages/gopls/gopls"
local gopls_bin = "/data00/home/lihao.hellohake/.local/bin/trae-gopls"
-- gopls针对大项目专门优化配置
-- 使用mason gopls v0.20.0
return {
	cmd = { gopls_bin, "-remote=unix;" .. socket_path },
	filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },

	flags = {
		allow_incremental_sync = true,
		debounce_text_changes = 500,
	},

	settings = {
		gopls = {
			["ui.diagnostic.staticcheck"] = false,
			["ui.diagnostic.analyses"] = {
				fieldalignment = false,
				nilness = false,
				unusedparams = false,
				unusedwrite = false,
				useany = false,
				shadow = false,
			},
			codelenses = {
				generate = false,
				gc_details = false,
				test = false,
				tidy = false,
				vendor = false,
				regenerate_cgo = false,
				upgrade_dependency = false,
			},
			["ui.semanticTokens"] = false,

			diagnosticsDelay = "60s",

			directoryFilters = {
				"-node_modules",
				"-bazel-out",
				"-dist",
				"-vendor",
				"-.git",
				"-**/*.generated.go",
				"-**/testdata",
				"-**/mock",
				"-**/mocks",
			},

			usePlaceholders = true,
			completeUnimported = false,

			symbolMatcher = "FastFuzzy",

			hoverKind = "FullDocumentation",
		},
	},

	on_attach = function(client, bufnr)
		-- client.server_capabilities.semanticTokensProvider = nil
	end,
}
