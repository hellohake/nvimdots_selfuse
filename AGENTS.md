# Architecture & Expert Guide for Agents (Full Summary)

> **并发修改协议 (Concurrent Modification Protocol)**:
>
> 1. **共享感知**: 本项目采用 Git Worktree 模式，核心文件（如 `AGENTS.md`, `.coco/`, `.ai_doc/`）通过软链接 (Symlink) 在各工作区间共享。
> 2. **原子编辑**: 修改共享文件前必须先 `Read` 全量内容。严禁盲目 `Write` 覆盖，必须使用 `Edit` 工具进行局部精准替换。
> 3. **精简闭环**: 严禁无脑追加内容。Agent 有责任在修改时合并重复项、精简描述，确保文档结构清晰。

本文档为 `nvimdots` 及其开发环境提供专家级架构总结、配置原则及 Agent 操作指南。

---

## 1. 配置哲学与核心架构

`nvimdots` 采用高度模块化的设计，支持开箱即用的扩展。

### 1.1 模块化分层

- **Core (`lua/core/`)**: 环境初始化、全局选项、插件引导。
- **Modules (`lua/modules/`)**: 插件声明与详细配置（`configs/`）。
- **User (`lua/user/`)**: **Agent 核心工作区**。
  - `configs/`: 覆盖/扩展默认插件配置。
  - `plugins/`: 用户自定义插件。
  - `sys_cfg/`: 存放系统同步的 `.zshrc`, `.tmux.conf` 等（由 `sync_cfg` 维护）。

### 1.2 插件加载与 Monkey Patching

- 系统优先检测 `user/configs/` 下同名文件。
- 对于复杂逻辑（如 `git-worktree` 的 Telescope 扩展修复），应在 `user/configs/` 中通过返回 function 接管 `setup`。

---

## 2. Git Worktree 专家级架构

本项目推荐采用 **Bare Repository + Worktree** 的平级管理模式。

### 2.1 物理结构标准

```text
<project_root>/
├── .bare/          # 物理 Git 数据（原 .git）
├── .git            # 指向 .bare 的指针文件
├── main/           # 主工作区 (master 分支)
├── feat-xxx/       # 特性工作区
├── .coco/          # [根部存储] 共享工具配置 (软链接至各子目录)
├── .ai_doc/        # [根部存储] 共享文档 (软链接至各子目录)
└── AGENTS.md       # [根部存储] 专家手册 (软链接至各子目录)
```

### 2.2 操作规范

- **新建 Worktree**: 在 Neovim 中路径应填 `../分支名`，以确保平级目录结构。
- **自动化钩子**: 插件已配置 `on_tree_change` 钩子，创建新工作区时会自动为上述共享文件建立软链接。
- **强制 CD**: 切换工作区已配置 `vim.schedule` 强制跳转，防止 CWD 被其他插件拦截。
- **切换前自动保存**: 切换工作区会自动执行 `silent! wa`，避免因未保存导致切换失败。

---

## 3. Shell & 终端环境优化

### 3.1 Zsh & Tmux

- **OSC 52**: 支持穿透 SSH 复制。
- **并行刷新**: `sourceall` 使用 `xargs -P 4` 并行刷新所有 tmux 面板。
- **NVM 懒加载**: 解决 Shell 启动延迟。
- **误关保护 (Ctrl-d)**: 在 `.zshrc` 中配置 `setopt IGNORE_EOF` 以防止误按 `Ctrl-d` 导致 tmux 面板关闭，同时不干扰 Vim/Lazygit 等应用的翻页功能。
- **Tmux 动态信息**: 状态栏动态获取 IP 地址 (`#(hostname -I | awk "{print \$1}")`)。

### 3.2 自动同步与备份

- **sync_cfg**: 核心机制。每次 Zsh 启动或手动执行时，自动将 `~/.zshrc` 和 `~/.tmux.conf` 同步至仓库路径 `lua/user/sys_cfg/`。
- **配置一致性**: Agent 修改系统配置后，应同时更新 `~/` 路径和仓库备份路径，并执行 `sourceall` 或 `Prefix + r`。

---

## 4. LSP 与 开发维护

- **Gopls 守护进程**: 使用 `start_gopls.sh` 管理。在删除或移动 Worktree 后，若出现 `no package metadata` 报错，应执行 `:gorestart` 或 `:LspRestart`。
- **Git 性能**: 大仓库禁用子模块状态检查以加速 Prompt。

---

## 5. 常用专家命令 (Keymaps)

- **Leader Key**: `<Space>`
- **Tmux 控制**:
  - `C-f` (Prefix): 设置为 `C-f` 以避免与 Vim 的 `C-b` 冲突。
  - `Prefix + r`: 重新加载 `~/.tmux.conf` 配置。
  - `Prefix + v / S`: 左右/上下分屏（保持当前 CWD）。
- **Worktree 管理**:
  - `<leader>gn`: 创建新工作区 (Path 需加 `../`)
  - `<leader>gw`: 切换/管理工作区 (Telescope 界面)
  - `<C-d>` (Telescope 列表内): 删除选中工作区
- **代码与 Shell 控制**:
  - `copygb`: 复制当前 Git 分支名（支持 OSC 52）。
  - `sourceall`: 强制所有 tmux 面板重新加载 shell 配置。
- **LSP 控制**: `gostart`, `gorestart`, `gostatus`

---

## 6. 常见问题 (Troubleshooting)

- **快捷键失效**: 检查 tmux 运行时绑定 (`tmux list-keys`)，必要时使用 `unbind-key` 清理残留拦截。
- **切换失败**: 检查是否有未保存缓冲区，或路径是否使用了正确的相对路径。
- **共享文件冲突**: 遵循顶部的 **并发修改协议**，使用分片文件或原子编辑。
- **LSP 报错**: 运行 `git worktree prune` 清理无效记录后重启 LSP。

## 7. 文档规范

- **AI 辅助文档**: 所有 AI 生成的技术方案、分析报告存放在根目录 `./.ai_doc/` 目录下。
- **Git 管理**: `./.ai_doc/` 目录已配置 Git 忽略，严禁上传至代码仓库。
