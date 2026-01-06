# Architecture & Expert Guide for Agents (Full Summary)

本文档为 `nvimdots` 及其关联的开发环境（Zsh, Tmux, Git, Go）提供专家级的架构总结、配置原则及 Agent 操作指南。

## 1. 配置哲学与核心架构

`nvimdots` 采用高度模块化的设计，旨在提供开箱即用且易于扩展的极致体验。

### 1.1 模块化分层
-   **Core (`lua/core/`)**: 负责环境初始化（Paths, Global Variables）、全局选项（Options）、事件系统（Autocmds）及插件引导（Pack/Lazy）。
-   **Modules (`lua/modules/`)**: 功能实现区，分为 `completion`, `editor`, `lang`, `tool`, `ui`。每个插件均有独立的 `plugins.lua` 声明和 `configs/` 详细配置。
-   **User (`lua/user/`)**: **Agent 与用户的核心工作区**。
    -   `configs/`: 存放覆盖默认插件配置的脚本。
    -   `plugins/`: 存放用户自定义的新插件。
    -   `sys_cfg/`: **核心同步区**。存放由 `sync_cfg` 自动从系统同步的 `.zshrc`, `.tmux.conf` 等。**Agent 修改系统配置后应确保同步至此。**

### 1.2 插件加载原则 (`load_plugin`)
-   **优先覆盖**：系统会自动检测 `user/configs/` 下同名文件。
-   **Monkey Patching**：若修复复杂逻辑，应在 `user/configs/` 返回一个 function 来完全接管 `setup`。

---

## 2. Shell & 终端环境优化 (专家级配置)

针对远程 SSH、大型单体仓库 (Monorepo) 及多面板协作进行了深度性能调优。

### 2.1 Zsh 极致性能与启动优化
-   **补全系统缓存**：使用 `compinit -C` 并配合 `extendedglob` 选项进行精准的 24 小时缓存检查，避免在远程 I/O 上扫描数千个补全脚本。
-   **环境加载缓存**：
    -   `brew shellenv` 结果缓存至 `~/.cache/zsh_brew_cache`，避免每次启动执行 Ruby 二进制文件。
    -   `thefuck` 等 Python 驱动的别名直接硬编码为 Zsh 函数，消除进程启动开销。
-   **NVM 懒加载**：通过函数封装实现 `node/npm/nvm` 按需加载，解决 Shell 启动延迟。
-   **路径校准与缩写**：显式校准 `$HOME` 为物理路径或一致的软链接路径，确保 `%~` 缩写正常（如 `~/.config/nvim`）及 LSP 根目录识别精准。
-   **Prompt 优化**：使用两行式 Prompt。第一行包含“用户、缩略路径（保留末级目录）、Git 分支、时间”；第二行固定为 `$ `。

### 2.2 Tmux 高级协作与并行化
-   **OSC 52 透传**：配置 `set-clipboard on` 和 `allow-passthrough on`，支持穿透 SSH 复制文本。
-   **并行刷新 (`sourceall`)**：使用 `xargs -P 4` 并行刷新所有 tmux 面板配置。通过 `SKIP_SYNC=1` 环境变量避免多面板同时刷新时的 I/O 竞争与卡顿。

### 2.3 自动配置同步 (`sync_cfg`)
-   `.zshrc` 中的 `sync_cfg` 具备幂等性，仅在文件有实际更新（`-nt` 检查）时同步。
-   同步路径：`~/.zshrc` -> `lua/user/sys_cfg/.zshrc`。

---

## 3. LSP 与 开发工具链

-   **Gopls 守护进程**：使用 `start_gopls.sh` 脚本管理 gopls 生命周期，提升多项目下的补全稳定性。
-   **Git 性能**：在大仓库中通过 `zstyle ':omz:plugins:git' status-ignore-submodules true` 禁用子模块检查，显著加速 Prompt 响应。

---

## 4. Agent 操作标准 (Best Practices)

### 4.1 核心操作守则
1.  **禁止直接修改 Core**：所有针对插件的修改必须在 `lua/user/configs/` 中通过覆盖实现。
2.  **Idempotency (幂等性)**：所有的 shell 脚本修改必须支持重复执行。
3.  **配置双向一致性**：修改 `~/.zshrc` 后，必须运行 `sync_cfg` 确保 nvim 仓库内的备份同步更新。

### 4.2 常用专家命令
-   **Leader Key**: `<Space>`
-   **Git Copy Branch**: `copygb` (带 OSC 52 支持)
-   **Reload All Configs**: `sourceall` (并行加速版)
-   **Gopls 控制**: `gostart`, `gorestart`, `gostatus`

---

## 5. 常见问题排查 (Troubleshooting)
-   **加载慢**：运行 `zprof` 分析。重点检查 `compinit` 和外部 `eval` 调用。
-   **路径显示错误**：检查 `HOME` 变量是否与当前 `pwd` 的路径前缀物理一致。
-   **并发冲突**：在多脚本操作同一文件时，使用 `SKIP_SYNC` 或临时文件锁定。
