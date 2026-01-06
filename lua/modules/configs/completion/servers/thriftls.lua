local nvim_lsp = require("lspconfig")
local target_dir = "/data00/home/lihao.hellohake/go/src/code.byted.org/ecom/service_rpc_idl/aweme/search/"

return {
	root_dir = function(fname)
		-- 优先检查是否在用户指定的目录下
		if fname:sub(1, #target_dir) == target_dir then
			return target_dir
		end
		-- 兜底逻辑：使用原有的 root_pattern
		return nvim_lsp.util.root_pattern(".git", "thrift.toml", "package.json", "go.mod")(fname)
	end,
	flags = {
		allow_incremental_sync = true,
		debounce_text_changes = 500,
	},
	settings = {
		thrift = {
			-- 将该目录加入包含路径，确保跨文件解析准确
			includeDirs = { target_dir },
		},
	},
}
