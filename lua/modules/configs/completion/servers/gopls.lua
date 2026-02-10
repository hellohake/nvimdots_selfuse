local socket_path = "/dev/shm/gopls-daemon-lihao.sock"
--local gopls_bin = "/data00/home/lihao.hellohake/.local/bin/trae-gopls"
local gopls_bin = "/data00/home/lihao.hellohake/.trae-cn-server/tools/trae-gopls/current/trae-gopls"
-- gopls针对大项目专门优化配置
-- 使用mason gopls v0.20.0
return {
	cmd = { gopls_bin, "-remote=unix;" .. socket_path },
	filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
	root_dir = function(fname)
		local util = require("lspconfig.util")
		-- 从主项目跳转到 GOPATH module cache（pkg/mod）时：
		-- 1) 该目录经常没有 go.mod（尤其 @xxx+incompatible）
		-- 2) 如果让 lspconfig 以该目录作为 root_dir，会触发 gopls `packages.Load` 报 go.mod not found
		-- 这里优先复用「已有的 gopls workspace root」，让依赖文件挂到主项目的 gopls 会话下。
		if fname:find("/pkg/mod/") then
			local clients = {}
			if vim.lsp.get_clients then
				clients = vim.lsp.get_clients({ name = "gopls" })
			elseif vim.lsp.get_active_clients then
				-- 兼容旧版本 nvim
				clients = vim.lsp.get_active_clients({ name = "gopls" })
			end
			for _, client in ipairs(clients) do
				local root = client.config and client.config.root_dir
				if type(root) == "string" and root ~= "" then
					return root
				end
			end
			local cwd = vim.fn.getcwd()
			local cwd_root = util.root_pattern("go.work", "go.mod", ".git")(cwd)
			if cwd_root then
				return cwd_root
			end
		end
		return util.root_pattern("go.work", "go.mod", ".git")(fname)
	end,

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
		-- 禁用 semanticTokens 以解决 Glance 插件查看引用时的 "Invalid buffer id" 报错
		-- 使用 dummy table 而非 nil，防止 diffview 等场景下出现 "attempt to index field 'semanticTokensProvider' (a nil value)"
		client.server_capabilities.semanticTokensProvider = {
			full = false,
			range = false,
			legend = {
				tokenTypes = {},
				tokenModifiers = {},
			},
		}
	end,
}
