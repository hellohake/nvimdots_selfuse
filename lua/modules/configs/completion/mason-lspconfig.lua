local M = {}

M.setup = function()
	local diagnostics_virtual_text = require("core.settings").diagnostics_virtual_text
	local diagnostics_level = require("core.settings").diagnostics_level

	local nvim_lsp = require("lspconfig")
	local mason_lspconfig = require("mason-lspconfig")
	require("lspconfig.ui.windows").default_options.border = "rounded"

	require("modules.utils").load_plugin("mason-lspconfig", {
		ensure_installed = require("core.settings").lsp_deps,
	})

	vim.diagnostic.config({
		signs = true,
		underline = true,
		virtual_text = diagnostics_virtual_text and {
			severity = {
				min = vim.diagnostic.severity[diagnostics_level],
			},
		} or false,
		update_in_insert = false,
	})

	-- 复用同一个 signatureHelp 浮窗，避免多 client / 多次触发导致叠出多个相同签名框
	-- 注：截图里的“3 个补全提示”实际是多个 `textDocument/signatureHelp` 浮窗被同时打开。
	local _orig_signature_help = vim.lsp.handlers["textDocument/signatureHelp"] or vim.lsp.handlers.signature_help
	if type(_orig_signature_help) == "function" then
		vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
			config = config or {}
			config.border = config.border or "rounded"
			-- focus_id 会让 open_floating_preview 复用窗口，而不是每次新开一个
			config.focus_id = config.focus_id or "lsp_signature_help"
			return _orig_signature_help(err, result, ctx, config)
		end
	end

	-- 安全加载 blink.cmp，如果插件被禁用或未加载，则回退到默认 capabilities
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if ok then
		capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
	end

	local opts = {
		capabilities = capabilities,
		on_attach = function(client, _)
			client.server_capabilities.semanticTokensProvider = nil
		end,
	}
	---A handler to setup all servers defined under `completion/servers/*.lua`
	---@param lsp_name string
	local function mason_lsp_handler(lsp_name)
		-- rust_analyzer is configured using mrcjkb/rustaceanvim
		-- warn users if they have set it up manually
		if lsp_name == "rust_analyzer" then
			local config_exist = pcall(require, "completion.servers." .. lsp_name)
			if config_exist then
				vim.notify(
					[[
`rust_analyzer` is configured independently via `mrcjkb/rustaceanvim`. To get rid of this warning,
please REMOVE your LSP configuration (rust_analyzer.lua) from the `servers` directory and configure
`rust_analyzer` using the appropriate init options provided by `rustaceanvim` instead.]],
					vim.log.levels.WARN,
					{ title = "nvim-lspconfig" }
				)
			end
			return
		end

		local ok, custom_handler = pcall(require, "user.configs.lsp-servers." .. lsp_name)
		local default_ok, default_handler = pcall(require, "completion.servers." .. lsp_name)
		-- Use preset if there is no user definition
		if not ok then
			ok, custom_handler = default_ok, default_handler
		end

		if not ok then
			-- Default to use factory config for server(s) that doesn't include a spec
			nvim_lsp[lsp_name].setup(opts)
			return
		elseif type(custom_handler) == "function" then
			--- Case where language server requires its own setup
			--- Make sure to call require("lspconfig")[lsp_name].setup() in the function
			--- See `clangd.lua` for example.
			custom_handler(opts)
		elseif type(custom_handler) == "table" then
			nvim_lsp[lsp_name].setup(
				vim.tbl_deep_extend(
					"force",
					opts,
					type(default_handler) == "table" and default_handler or {},
					custom_handler
				)
			)
		else
			vim.notify(
				string.format(
					"Failed to setup [%s].\n\nServer definition under `completion/servers` must return\neither a fun(opts) or a table (got '%s' instead)",
					lsp_name,
					type(custom_handler)
				),
				vim.log.levels.ERROR,
				{ title = "nvim-lspconfig" }
			)
		end
	end

	mason_lspconfig.setup_handlers({ mason_lsp_handler })
end

return M
