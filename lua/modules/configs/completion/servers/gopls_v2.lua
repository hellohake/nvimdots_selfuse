local socket_path = "/dev/shm/gopls-daemon-lihao.sock"

-- 2. 将配置定义给一个局部变量 'config'
local config = {
	cmd = {
		"sh",
		"-c",
		-- 简化的字符串拼接，确保 shell 命令格式正确
		"GOMEMLIMIT=150GiB gopls -remote='auto;unix:"
			.. socket_path
			.. "'",
	},

	filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },

	flags = {
		allow_incremental_sync = true,
		debounce_text_changes = 500,
	},

	capabilities = {
		textDocument = {
			completion = {
				contextSupport = true,
				dynamicRegistration = true,
				completionItem = {
					commitCharactersSupport = true,
					deprecatedSupport = true,
					preselectSupport = true,
					insertReplaceSupport = true,
					labelDetailsSupport = true,
					snippetSupport = true,
					documentationFormat = { "markdown", "plaintext" },
					resolveSupport = {
						properties = { "documentation", "details", "additionalTextEdits" },
					},
				},
			},
		},
	},

	settings = {
		gopls = {
			["ui.diagnostic.staticcheck"] = true,
			["ui.diagnostic.analyses"] = {
				fieldalignment = true,
				nilness = true,
				unusedparams = true,
				unusedwrite = true,
				useany = true,
				shadow = true,
			},
			directoryFilters = {
				"-node_modules",
				"-bazel-out",
				"-dist",
				"-vendor",
				"-.git",
				"-**/*.generated.go",
				"-**/testdata",
				"-**/mock",
			},
			usePlaceholders = true,
			completeUnimported = true,
			symbolMatcher = "Fuzzy",
			hoverKind = "FullDocumentation",
			gofumpt = true,
			codelenses = {
				generate = true,
				gc_details = false,
				test = true,
				tidy = true,
				vendor = true,
				regenerate_cgo = true,
				upgrade_dependency = true,
			},
		},
	},
}

-- 3. 【关键】必须显式返回这个变量！如果不写这一行，就会报 'got boolean' 错误
return config
