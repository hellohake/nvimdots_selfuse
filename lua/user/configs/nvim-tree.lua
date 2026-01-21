return function(opts)
	-- 关闭 update_root，防止打开软链接文件时自动跳转到真实物理目录
	opts.update_focused_file.update_root = false

	-- 保持 enable = true 可以让文件树高亮当前文件（如果在树中可见的话）
	opts.update_focused_file.enable = true

	return opts
end
