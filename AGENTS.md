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
    -   `sys_cfg/`: **重要**。存放由 `sync_cfg` 自动同步的外部系统配置（.zshrc, .tmux.conf 等）。

### 1.2 插件加载原则 (`load_plugin`)
Agent 必须理解 `lua/modules/utils/init.lua` 中的加载逻辑：
-   **优先覆盖**：系统会自动检测 `user/configs/` 下同名文件。
-   **Monkey Patching**：若修复复杂逻辑（如修复 Telescope 渲染 Bug），应在 `user/configs/` 返回一个 function 来完全接管 `setup`。

---

## 2. Shell & 终端环境优化 (专家级配置)

针对远程 SSH、大型单体仓库 (Monorepo) 及多面板协作进行了深度调优。

### 2.1 Zsh 极致性能
-   **补全系统缓存**：使用 `compinit -C` 并配合 24 小时缓存检查，避免在远程 I/O 上扫描数千个补全脚本。
-   **NVM 懒加载**：通过函数封装实现 `node/npm/nvm` 按需加载，解决 Shell 启动超过 1 分钟的性能顽疾。
-   **幂等加载**：插件加载均包含 `(( $+functions[...] ))` 检查，彻底杜绝 `maximum nested function level` 递归报错。
-   **路径校准**：显式校准物理路径 `$HOME`，确保 `%~` 缩写正常及 LSP 根目录识别精准。

### 2.2 Tmux 高级协作
-   **OSC 52 透传**：配置 `set-clipboard on` 和 `allow-passthrough on`，支持穿透 SSH 复制文本到本地 Mac 剪贴板。
-   **全局同步 (`sourceall`)**：一键刷新所有 tmux 面板配置，具备自动跳过非 Shell 程序及当前面板的智能过滤逻辑。

### 2.3 自动配置同步 (`sync_cfg`)
`.zshrc` 中的 `sync_cfg` 函数在每次 Shell 启动或 `source` 时运行，自动将 `~/.zshrc`, `~/.tmux.conf`, `~/start_gopls.sh` 同步至 `lua/user/sys_cfg/`，确保环境配置随代码仓库一同进行版本管理。

---

## 3. LSP 与 开发工具链 (Golang 示例)

-   **Gopls 守护进程**：使用 `start_gopls.sh` 脚本管理 gopls 生命周期，提升多项目下的补全稳定性。
-   **快捷键管理**：统一使用 `lua/keymap/bind.lua` 的辅助函数（`map_cr`, `map_cu` 等），支持链式描述和静默执行。

---

## 4. Agent 操作标准 (Best Practices)

### 4.1 核心操作守则
1.  **禁止直接修改 Core**：所有针对插件的修改必须在 `lua/user/configs/` 中通过覆盖实现。
2.  **绝对路径安全**：在配置文件中优先使用 `$HOME` 或物理路径，避免依赖可能导致缩写失效的软链接。
3.  **Idempotency (幂等性)**：所有的 shell 脚本写入必须可重复执行且不产生副作用。

### 4.2 常用专家快捷键
-   **Leader Key**: `<Space>`
-   **Git Copy Branch**: `copygb` (Shell 命令，带 OSC 52 支持)
-   **Reload All Configs**: `sourceall` (Shell 命令)
-   **Gopls 控制**: `gostart`, `gorestart`, `gostatus`

---

## 5. 常见问题排查 (Troubleshooting)

-   **加载慢**：运行 `zprof` 分析 `compinit` 或外部 `eval` 调用。
-   **复制失败**：检查 iTerm2 的 `Applications may access clipboard` 设置及 tmux 的 `allow-passthrough`。
-   **路径显示错误**：对比 `pwd` 结果与 `$HOME` 导出路径是否完全一致。
