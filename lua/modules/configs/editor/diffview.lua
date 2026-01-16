return function()
	local function hex_to_rgb(hex)
		hex = hex:gsub("#", "")
		if #hex ~= 6 then return nil end
		return {
			r = tonumber(hex:sub(1, 2), 16),
			g = tonumber(hex:sub(3, 4), 16),
			b = tonumber(hex:sub(5, 6), 16),
		}
	end

	local function rgb_to_hex(rgb)
		return string.format("#%02x%02x%02x", rgb.r, rgb.g, rgb.b)
	end

	-- alpha: 0..1, 越大越偏向 fg
	local function blend(fg, bg, alpha)
		local f, b = hex_to_rgb(fg), hex_to_rgb(bg)
		if not f or not b then return fg end
		local function ch(c1, c2)
			return math.floor((alpha * c1) + ((1 - alpha) * c2) + 0.5)
		end
		return rgb_to_hex({ r = ch(f.r, b.r), g = ch(f.g, b.g), b = ch(f.b, b.b) })
	end

	local function apply_diff_highlights()
		local ok, palettes = pcall(require, "catppuccin.palettes")
		if not ok or type(palettes.get_palette) ~= "function" then return end
		local cp = palettes.get_palette()
		if type(cp) ~= "table" or not cp.base then return end

		-- 目标：在 diffview 里让变更块边界非常清晰（背景更明显，但不刺眼）
		local set_hl = function(name, spec)
			vim.api.nvim_set_hl(0, name, spec)
		end

		local add_bg = blend(cp.green, cp.base, 0.22)
		local del_bg = blend(cp.red, cp.base, 0.22)
		local chg_bg = blend(cp.yellow, cp.base, 0.18)
		local txt_bg = blend(cp.blue, cp.base, 0.28)

		-- 原生 diff 高亮（diffview 的主 diff 区域也会复用这些组）
		set_hl("DiffAdd", { bg = add_bg })
		set_hl("DiffDelete", { bg = del_bg })
		set_hl("DiffChange", { bg = chg_bg })
		set_hl("DiffText", { bg = txt_bg, bold = true })

		-- diffview 专用组（覆盖 catppuccin integration 的默认值，提升区分度）
		set_hl("DiffviewDiffAdd", { link = "DiffAdd" })
		set_hl("DiffviewDiffDelete", { link = "DiffDelete" })
		set_hl("DiffviewDiffChange", { link = "DiffChange" })
		set_hl("DiffviewDiffText", { link = "DiffText" })
		set_hl("DiffviewDiffAddAsDelete", { bg = del_bg })

		-- 文件面板更清晰
		set_hl("DiffviewFilePanelInsertions", { fg = cp.green, bold = true })
		set_hl("DiffviewFilePanelDeletions", { fg = cp.red, bold = true })
		set_hl("DiffviewStatusAdded", { fg = cp.green })
		set_hl("DiffviewStatusModified", { fg = cp.yellow })
		set_hl("DiffviewStatusDeleted", { fg = cp.red })
	end

	require("modules.utils").load_plugin("diffview", {
		diff_binaries = false, -- Show diffs for binaries
		enhanced_diff_hl = true, -- 更细粒度的 diff 高亮（配合下方 override 更清晰）
		git_cmd = { "git" }, -- The git executable followed by default args.
		hg_cmd = { "hg" }, -- The hg executable followed by default args.
		use_icons = true, -- Requires nvim-web-devicons
		show_help_hints = true, -- Show hints for how to open the help panel
		watch_index = true, -- Update views and index buffers when the git index changes.
	})

	apply_diff_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("DiffviewHighContrast", { clear = true }),
		callback = apply_diff_highlights,
	})
end
