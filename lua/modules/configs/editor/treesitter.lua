return vim.schedule_wrap(function()
	local use_ssh = require("core.settings").use_ssh
	local function patch_latex_highlights_for_new_parser()
		local has_new_label_nodes = pcall(vim.treesitter.query.parse, "latex", "(curly_group_label)")
		if not has_new_label_nodes then
			return
		end

		local highlights_ok = pcall(vim.treesitter.query.get, "latex", "highlights")
		if highlights_ok then
			return
		end

		local plugin = require("lazy.core.config").plugins["nvim-treesitter"]
		if not plugin then
			return
		end

		local query_path = plugin.dir .. "/queries/latex/highlights.scm"
		local query = table.concat(vim.fn.readfile(query_path), "\n")
		if query == "" then
			return
		end

		query = query
			:gsub(
				"%(label_definition\n  command: _ @function%.macro\n  name: %(curly_group_text\n    %(_%) @markup%.link @nospell%)%)",
				"(label_definition\n  command: _ @function.macro\n  name: (curly_group_label\n    (_) @markup.link @nospell))"
			)
			:gsub(
				"%(label_reference_range\n  command: _ @function%.macro\n  from: %(curly_group_text\n    %(_%) @markup%.link%)\n  to: %(curly_group_text\n    %(_%) @markup%.link%)%)",
				"(label_reference_range\n  command: _ @function.macro\n  from: (curly_group_label\n    (_) @markup.link)\n  to: (curly_group_label\n    (_) @markup.link))"
			)
			:gsub(
				"%(label_reference\n  command: _ @function%.macro\n  names: %(curly_group_text_list\n    %(_%) @markup%.link%)%)",
				"(label_reference\n  command: _ @function.macro\n  names: (curly_group_label_list\n    (_) @markup.link))"
			)
			:gsub(
				"%(label_number\n  command: _ @function%.macro\n  name: %(curly_group_text\n    %(_%) @markup%.link%)\n  number: %(_%) @markup%.link%)",
				"(label_number\n  command: _ @function.macro\n  name: (curly_group_label\n    (_) @markup.link)\n  number: (_) @markup.link)"
			)

		if pcall(vim.treesitter.query.parse, "latex", query) then
			vim.treesitter.query.set("latex", "highlights", query)
		end
	end

	vim.api.nvim_set_option_value("foldmethod", "expr", {})
	vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.treesitter.foldexpr()", {})

	require("modules.utils").load_plugin("nvim-treesitter", {
		ensure_installed = require("core.settings").treesitter_deps,
		highlight = {
			enable = true,
			disable = function(ft, bufnr)
				if
					vim.tbl_contains({ "gitcommit" }, ft)
					or (vim.api.nvim_buf_line_count(bufnr) > 7500 and ft ~= "vimdoc")
				then
					return true
				end

				local ok, is_large_file = pcall(vim.api.nvim_buf_get_var, bufnr, "bigfile_disable_treesitter")
				return ok and is_large_file
			end,
			additional_vim_regex_highlighting = false,
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
				},
			},
			move = {
				enable = true,
				set_jumps = true,
				goto_next_start = {
					["]["] = "@function.outer",
					["]m"] = "@class.outer",
				},
				goto_next_end = {
					["]]"] = "@function.outer",
					["]M"] = "@class.outer",
				},
				goto_previous_start = {
					["[["] = "@function.outer",
					["[m"] = "@class.outer",
				},
				goto_previous_end = {
					["[]"] = "@function.outer",
					["[M"] = "@class.outer",
				},
			},
		},
		indent = { enable = true },
		matchup = { enable = true },
	}, false, require("nvim-treesitter.configs").setup)
	require("nvim-treesitter.install").prefer_git = true
	local parsers = require("nvim-treesitter.parsers").get_parser_configs()
	parsers.latex.install_info.revision = "7e0ecdc02926c7b9b2e0c76003d4fe7b0944f957"
	if use_ssh then
		for _, parser in pairs(parsers) do
			parser.install_info.url = parser.install_info.url:gsub("https://github.com/", "git@github.com:")
		end
	end
	patch_latex_highlights_for_new_parser()
end)
