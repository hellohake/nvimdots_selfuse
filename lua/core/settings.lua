local settings = {}

-- Set it to false if you want to use https to update plugins and treesitter parsers.
---@type boolean
settings["use_ssh"] = true

-- Set it to false if you don't use copilot
---@type boolean
settings["use_copilot"] = true

-- Set it to false if there is no need to format on save.
---@type boolean
settings["format_on_save"] = true

-- Set format timeout here (in ms).
---@type number
settings["format_timeout"] = 2000

-- Set it to false if the notification after formatting is annoying.
---@type boolean
settings["format_notify"] = false

-- Set it to true if you prefer formatting ONLY the *changed lines* as defined by your version control system.
-- NOTE: This entry will only be respected if:
--  > The buffer to be formatted is under version control (Git or Mercurial);
--  > Any of the server attached to that buffer supports |DocumentRangeFormattingProvider| server capability.
-- Otherwise Neovim would fall back to format the whole buffer, and a warning will be issued.
---@type boolean
settings["format_modifications_only"] = false

-- Set the format disabled directories here, files under these dirs won't be formatted on save.
--- NOTE: Directories may contain regular expressions (grammar: vim). |regexp|
--- NOTE: Directories are automatically normalized. |vim.fs.normalize()|
---@type string[]
settings["format_disabled_dirs"] = {
	-- Example
	"~/format_disabled_dir",
}

-- Filetypes in this list will skip lsp formatting if rhs is true.
---@type table<string, boolean>
settings["formatter_block_list"] = {
	lua = false, -- example
}

-- Servers in this list will skip setting formatting capabilities if rhs is true.
---@type table<string, boolean>
settings["server_formatting_block_list"] = {
	clangd = true,
	lua_ls = true,
	ts_ls = true,
}

-- Set it to false if you want to turn off LSP Inlay Hints
---@type boolean
settings["lsp_inlayhints"] = true

-- Set it to false if diagnostics virtual text is annoying.
-- If disabled, you may browse lsp diagnostics using trouble.nvim (press `gt` to toggle it).
---@type boolean
settings["diagnostics_virtual_text"] = true

-- Set it to one of the values below if you want to change the visible severity level of lsp diagnostics.
-- Priority: `Error` > `Warning` > `Information` > `Hint`.
--  > e.g. if you set this option to `Warning`, only lsp warnings and errors will be shown.
-- NOTE: This entry only works when `diagnostics_virtual_text` is true.
---@type "ERROR"|"WARN"|"INFO"|"HINT"
settings["diagnostics_level"] = "HINT"

-- Set the plugins to disable here.
-- Example: "Some-User/A-Repo"
---@type string[]
settings["disabled_plugins"] = {}

-- Set it to false if you don't use nvim to open big files.
---@type boolean
settings["load_big_files_faster"] = true

-- Change the colors of the global palette here.
-- Settings will complete their replacement at initialization.
-- Parameters will be automatically completed as you type.
-- Example: { sky = "#04A5E5" }
---@type palette[]
settings["palette_overwrite"] = {}

-- Set the colorscheme to use here.
-- Available values are: `catppuccin`, `catppuccin-latte`, `catppucin-mocha`, `catppuccin-frappe`, `catppuccin-macchiato`.
---@type string
settings["colorscheme"] = "catppuccin"

-- Set it to true if your terminal has transparent background.
---@type boolean
settings["transparent_background"] = false

-- Set background color to use here.
-- Useful if you would like to use a colorscheme that has a light and dark variant like `edge`.
-- Valid values are: `dark`, `light`.
---@type "dark"|"light"
settings["background"] = "dark"

-- Set the command for handling external URLs here. The executable must be available on your $PATH.
-- This entry is IGNORED on Windows and macOS, which have their default handlers builtin.
---@type string
settings["external_browser"] = "chrome-cli open"

-- Set the language servers that will be installed during bootstrap here.
-- check the below link for all the supported LSPs:
-- https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/server_configurations
---@type string[]
settings["lsp_deps"] = {
	"bashls",
	"clangd",
	"html",
	"jsonls",
	"lua_ls",
	"pylsp",
	"gopls",
	"thriftls",
}

-- Set the general-purpose servers that will be installed during bootstrap here.
-- Check the below link for all supported sources.
-- in `code_actions`, `completion`, `diagnostics`, `formatting`, `hover` folders:
-- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins
---@type string[]
settings["null_ls_deps"] = {
	"clang_format",
	"gofumpt",
	"goimports",
	"prettier",
	"shfmt",
	"stylua",
	"vint",
}

-- Set the Debug Adapter Protocol (DAP) clients that will be installed and configured during bootstrap here.
-- Check the below link for all supported DAPs:
-- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
---@type string[]
settings["dap_deps"] = {
	"codelldb", -- C-Family
	"delve", -- Go
	"python", -- Python (debugpy)
}

-- Set the Treesitter parsers that will be installed during bootstrap here.
-- Check the below link for all supported languages:
-- https://github.com/nvim-treesitter/nvim-treesitter#supported-languages
---@type string[]
settings["treesitter_deps"] = {
	"bash",
	"c",
	"cpp",
	"css",
	"go",
	"gomod",
	"html",
	"javascript",
	"json",
	"jsonc",
	"latex",
	"lua",
	"make",
	"markdown",
	"markdown_inline",
	"python",
	"rust",
	"typescript",
	"vimdoc",
	"vue",
	"yaml",
	"thrift",
}

-- Set the options for neovim's gui clients like `neovide` and `neovim-qt` here.
-- NOTE: Currently, only the following options related to the GUI are supported. Other entries will be IGNORED.
---@type { font_name: string, font_size: number }
settings["gui_config"] = {
	font_name = "JetBrainsMono Nerd Font",
	font_size = 10,
}

-- Set the options specific to `neovide` here.
-- NOTE: You should remove the `neovide_` prefix (with trailing underscore) from all your entries below.
-- Check the below link for all supported entries:
-- https://neovide.dev/configuration.html
---@type table<string, boolean|number|string>
settings["neovide_config"] = {
	no_idle = true,
	refresh_rate = 120,
	cursor_vfx_mode = "railgun",
	cursor_vfx_opacity = 200.0,
	cursor_antialiasing = true,
	cursor_trail_length = 0.05,
	cursor_animation_length = 0.03,
	cursor_vfx_particle_speed = 20.0,
	cursor_vfx_particle_density = 5.0,
	cursor_vfx_particle_lifetime = 1.2,
}

-- Set the dashboard startup image here
-- You can generate the ascii image using: https://github.com/TheZoraiz/ascii-image-converter
-- More info: https://github.com/ayamir/nvimdots/wiki/Issues#change-dashboard-startup-image
---@type string[]
settings["dashboard_image1"] = {
	[[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⣠⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣡⣾⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣟⠻⣿⣿⣿⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⣿⡿⢫⣷⣿⣿⣿⣿⣿⣿⣿⣾⣯⣿⡿⢧⡚⢷⣌⣽⣿⣿⣿⣿⣿⣶⡌⣿⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⣿⠇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣮⣇⣘⠿⢹⣿⣿⣿⣿⣿⣻⢿⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⡟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣻⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⡇⠀⣬⠏⣿⡇⢻⣿⣿⣿⣿⣿⣿⣿⣷⣼⣿⣿⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⢻⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⠀⠈⠁⠀⣿⡇⠘⡟⣿⣿⣿⣿⣿⣿⣿⣿⡏⠿⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣇⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⡏⠀⠀⠐⠀⢻⣇⠀⠀⠹⣿⣿⣿⣿⣿⣿⣩⡶⠼⠟⠻⠞⣿⡈⠻⣟⢻⣿⣿⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⢿⠀⡆⠀⠘⢿⢻⡿⣿⣧⣷⢣⣶⡃⢀⣾⡆⡋⣧⠙⢿⣿⣿⣟⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⡥⠂⡐⠀⠁⠑⣾⣿⣿⣾⣿⣿⣿⡿⣷⣷⣿⣧⣾⣿⣿⣿⣿⣿⣿⣿]],
	[[⣿⣿⡿⣿⣍⡴⠆⠀⠀⠀⠀⠀⠀⠀⠀⣼⣄⣀⣷⡄⣙⢿⣿⣿⣿⣿⣯⣶⣿⣿⢟⣾⣿⣿⢡⣿⣿⣿⣿⣿]],
	[[⣿⡏⣾⣿⣿⣿⣷⣦⠀⠀⠀⢀⡀⠀⠀⠠⣭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⣡⣾⣿⣿⢏⣾⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⣿⣿⣿⣿⣿⡴⠀⠀⠀⠀⠀⠠⠀⠰⣿⣿⣿⣷⣿⠿⠿⣿⣿⣭⡶⣫⠔⢻⢿⢇⣾⣿⣿⣿⣿⣿⣿]],
	[[⣿⣿⣿⡿⢫⣽⠟⣋⠀⠀⠀⠀⣶⣦⠀⠀⠀⠈⠻⣿⣿⣿⣾⣿⣿⣿⣿⡿⣣⣿⣿⢸⣾⣿⣿⣿⣿⣿⣿⣿]],
	[[⡿⠛⣹⣶⣶⣶⣾⣿⣷⣦⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠉⠛⠻⢿⣿⡿⠫⠾⠿⠋⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
	[[⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⡆⣠⢀⣴⣏⡀⠀⠀⠀⠉⠀⠀⢀⣠⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
	[[⠿⠛⠛⠛⠛⠛⠛⠻⢿⣿⣿⣿⣿⣯⣟⠷⢷⣿⡿⠋⠀⠀⠀⠀⣵⡀⢠⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿]],
	[[⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⢿⣿⣿⠂⠀⠀⠀⠀⠀⢀⣽⣿⣿⣿⣿⣿⣿⣿⣍⠛⠿⣿⣿⣿⣿⣿⣿]],
}

settings["dashboard_image2"] = {
	[[                                                 /===-_---~~~~~~~~~------____]],
	[[                                                |===-~___                _,-']],
	[[                 -==\\                         `//~\\   ~~~~`---.___.-~~]],
	[[             ______-==|                         | |  \\           _-~`]],
	[[       __--~~~  ,-/-==\\                        | |   `\        ,']],
	[[    _-~       /'    |  \\                      / /      \      /]],
	[[  .'        /       |   \\                   /' /        \   /']],
	[[ /  ____  /         |    \`\.__/-~~ ~ \ _ _/'  /          \/']],
	[[/-'~    ~~~~~---__  |     ~-/~         ( )   /'        _--~`]],
	[[                  \_|      /        _)   ;  ),   __--~~]],
	[[                    '~~--_/      _-~/-  / \   '-~ \]],
	[[                   {\__--_/}    / \\_>- )<__\      \]],
	[[                   /'   (_/  _-~  | |__>--<__|      |]],
	[[                  |0  0 _/) )-~     | |__>--<__|     |]],
	[[                  / /~ ,_/       / /__>---<__/      |]],
	[[                 o o _//        /-~_>---<__-~      /]],
	[[                 (^(~          /~_>---<__-      _-~]],
	[[                ,/|           /__>--<__/     _-~]],
	[[             ,//('(          |__>--<__|     /                  .----_]],
	[[            ( ( '))          |__>--<__|    |                 /' _---_~\]],
	[[         `-)) )) (           |__>--<__|    |               /'  /     ~\`\]],
	[[        ,/,'//( (             \__>--<__\    \            /'  //        ||]],
	[[      ,( ( ((, ))              ~-__>--<_~-_  ~--____---~' _/'/        /']],
	[[    `~/  )` ) ,/|                 ~-_~>--<_/-__       __-~ _/]],
	[[  ._-~//( )/ )) `                    ~~-'_/_/ /~~~~~~~__--~]],
	[[   ;'( ')/ ,)(                              ~~~~~~~~~~]],
	[[  ' ') '( (/]],
}

settings["dashboard_image"] = {
	[[ ,\/~~~\_                            _/~~~~\]],
	[[ |  ---, `\_    ___,-------~~\__  /~' ,,''  |]],
	[[ | `~`, ',,\`-~~--_____    ---  - /, ,--/ '/']],
	[[  `\_|\ _\`    ______,---~~~\  ,_   '\_/' /']],
	[[    \,_|   , '~,/'~   /~\ ,_  `\_\ \_  \_\']],
	[[    ,/   /' ,/' _,-'~~  `\  ~~\_ ,_  `\  `\]],
	[[  /@@ _/  /' ./',-                 \       `@,]],
	[[  @@ '   |  ___/  /'  /  \  \ '\__ _`~|, `, @@]],
	[[/@@ /  | | ',___  |  |    `  | ,,---,  |  | `@@,]],
	[[@@@ \  | | \ \O_`\ |        / / O_/' | \  \  @@@]],
	[[@@@ |  | `| '   ~ / ,          ~     /  |    @@@]],
	[[`@@ |   \ `\     ` |         | |  _/'  /'  | @@']],
	[[ @@ |    ~\ /--'~  |       , |  \__   |    | |@@]],
	[[ @@, \     | ,,|   |       ,,|   | `\     /',@@]],
	[[ `@@, ~\   \ '     |       / /    `' '   / ,@@]],
	[[  @@@,    \    ~~\ `\/~---'~/' _ /'~~~~~~~~--,_]],
	[[   `@@@_,---::::::=  `-,| ,~  _=:::::''''''    `]],
	[[   ,/~~_---'_,-___     _-__  ' -~~~\_```---]],
	[[     ~`   ~~_/'// _,--~\_/ '~--, |\_]],
	[[          /' /'| `@@@@@,,,,,@@@@  | \      -Chev]],
	[[               `     `@@@@@@']],
}

settings["dashboard_image1"] = {
	[[                        .]],
	[[                       d$e]],
	[[                      d$$$b]],
	[[                    .$$" "$b]],
	[[                   .$$beec3$$]],
	[[              .ed$$$$""""""*$$$be.]],
	[[            e$$  d$$        J$$  $$e.]],
	[[  ^$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$P]],
	[[    *$. d$"   .$$"             *$c   "$b .$*]],
	[[     *$$$"   .$$"               *$c   ^$$$"]],
	[[      $$L   z$P                  *$e   J$$]],
	[[     4$P$b d$P                    "$b z$*$r]],
	[[     $$  $$$"                      "$$$" $$]],
	[[     $$ .$$$.                       $$$  $$]],
	[[     3$e$$ "$.                     $P"$$z$F]],
	[[      $$P   "$c                  .$P   $$$]],
	[[     d$$b    ^$b                .$"    d$$.]],
	[[    $$"^$$.    *$              z$"   .$$"*$c]],
	[[  .$$"   *$e    *$.           z$"   e$P   *$c]],
	[[  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$e]],
	[[             "*$$eJ$c      .d$b$$*"]],
	[[                 ""*$$$$$$$$P""]],
	[[                     *$   $P]],
	[[                      "$.$"]],
	[[                       "$"  ]],
}
settings["dashboard_image1"] = {
	[[               __....__]],
	[[           .gd$$$$$$$$$$bp.]],
	[[        .-"^^^T$$$$$$$$$$$$$p.]],
	[[      .'       "^T$$$$$$$$$$$$b.]],
	[[    .'            `T$$$$$$$$$$$$b.]],
	[[   /     .d$$b.     T$$$$$$$$$$$$$b]],
	[[  /     d$$$$$$b     $$$$$$$$$$$$$$b]],
	[[ :     :$$$$$$$$;    :$$$$$$$$$$$$$$;]],
	[[ ;      T$$$$$$P     :$$$$$$$$$$$$$$$]],
	[[:        "^$$^"      $$$$$$$$$$$$$$$$;]],
	[[;                   d$$$$$$$$$$$$$$$$$]],
	[[|                 .d$$$$$$$$$$$$$$$$$$]],
	[[;                d$$$$$$$$$$$$$$$$$$$$]],
	[[:               :$$$$$$P^""^T$$$$$$$$;]],
	[[ ;              $$$$$$P      T$$$$$$$]],
	[[ :              $$$$$$        $$$$$$;]],
	[[  \             :$$$$$b      d$$$$$P]],
	[[   \             T$$$$$bp..gd$$$$$P]],
	[[    `.            `T$$$$$$$$$$$$P']],
	[[      `.            "^$$$$$$$$P']],
	[[        "-.            "^^T$P']],
	[[           "--...____...--"]],
}

settings["dashboard_image1"] = {
	[[.-----------------------------------------------------------------------------.]],
	[[||Es| |F1 |F2 |F3 |F4 |F5 | |F6 |F7 |F8 |F9 |F10|                  C= AMIGA   |]],
	[[||__| |___|___|___|___|___| |___|___|___|___|___|                             |]],
	[[| _____________________________________________     ________    ___________   |]],
	[[||~  |! |" |§ |$ |% |& |/ |( |) |= |? |` || |<-|   |Del|Help|  |{ |} |/ |* |  |]],
	[[||`__|1_|2_|3_|4_|5_|6_|7_|8_|9_|0_|ß_|´_|\_|__|   |___|____|  |[ |]_|__|__|  |]],
	[[||<-  |Q |W |E |R |T |Z |U |I |O |P |Ü |* |   ||               |7 |8 |9 |- |  |]],
	[[||->__|__|__|__|__|__|__|__|__|__|__|__|+_|_  ||               |__|__|__|__|  |]],
	[[||Ctr|oC|A |S |D |F |G |H |J |K |L |Ö |Ä |^ |<'|               |4 |5 |6 |+ |  |]],
	[[||___|_L|__|__|__|__|__|__|__|__|__|__|__|#_|__|       __      |__|__|__|__|  |]],
	[[||^    |> |Y |X |C |V |B |N |M |; |: |_ |^     |      |A |     |1 |2 |3 |E |  |]],
	[[||_____|<_|__|__|__|__|__|__|__|,_|._|-_|______|    __||_|__   |__|__|__|n |  |]],
	[[|   |Alt|A  |                       |A  |Alt|      |<-|| |->|  |0    |. |t |  |]],
	[[|   |___|___|_______________________|___|___|      |__|V_|__|  |_____|__|e_|  |]],
	[[|                                                                             |]],
	[[`-----------------------------------------------------------------------------']],
}

settings["dashboard_image1"] = {
	[[                                     ,-.. _. ,. ,._]],
	[[                                  .-'         .     '.]],
	[[                                 /             .      /_./.]],
	[[                                '                        '.]],
	[[                               .                           ']],
	[[                              '            =\ : , \         \]],
	[[                             '            '` `   `  =        ']],
	[[                             |,.        _\           ',       \]],
	[[                             /   \    ."               ',.    /]],
	[[                            || ,' `  ,                  ' \_.']],
	[[                            |\ -. / ,       `'":,      /]],
	[[                          ,-= .   ,'       '_   `;.    |]],
	[[                         /  /  -'            "'`    ,:,]],
	[[                      _,/|,'    ,                   ']],
	[[               ___,--' | |                    (    /]],
	[[          _,-'`        . .      .            , '- _'          .-.]],
	[[        ,'              \        .       `,'"`';/.          ,'   )]],
	[[      ,`                 .'       :     /  ';\\   '.     ,'    .']],
	[[    ,'                   |.\       ';.'.,. .;.\\  ,..:_'_    .]],
	[[   /  .                    '.       .'';_:;'`  '_(        ' '-.]],
	[[   |   .                     '.'.,-'   ,       (    '" - ._    )]],
	[[  / .   `                      '.             _,'-._        ` (]],
	[[ /    .       [lf]             _ |   '      .' '.    ' .  _    )]],
	[[                              (:)          '      '        '   ']],
}

return require("modules.utils").extend_config(settings, "user.settings")
