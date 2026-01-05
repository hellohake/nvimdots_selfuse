# Architecture Overview

This document provides a high-level overview of the `nvimdots` codebase, a modular and customizable Neovim configuration.

## 1. Project Overview

`nvimdots` is a feature-rich, modular Neovim configuration designed for performance and extensibility.

-   **Purpose**: To provide a fast, "out-of-the-box" usable Neovim environment that is easy to extend and customize.
-   **Plugin Manager**: Uses [lazy.nvim](https://github.com/folke/lazy.nvim) for efficient plugin management.
-   **Structure**:
    -   **Root**: `init.lua` acts as the entry point, delegating to the core module.
    -   **Core**: Essential settings, event handling, and package management logic.
    -   **Modules**: Categorized plugin configurations (Completion, Editor, Lang, Tool, UI).
    -   **User**: Dedicated directory for user customizations (gitignored).

## 2. Build & Commands

### Installation
The project provides automated installation scripts:

-   **Unix/Linux/macOS**: `bash scripts/install.sh`
-   **Windows**: `powershell -ExecutionPolicy ByPass -File scripts/install.ps1`

### Nix Integration
For NixOS or Nix users, the project uses a Flake-based setup:

-   **Flake**: `flake.nix` provides the environment configuration.
-   **NixOS Module**: Exports a `homeManagerModules.nvimdots` for integration into system configs.

## 3. Code Style

The project enforces code style using **StyLua**. Configuration is defined in `stylua.toml`:

-   **Column Width**: 120
-   **Indent**: Tabs (width 4)
-   **Quotes**: Auto-prefer double quotes
-   **Line Endings**: Unix

To format code: `stylua .`

## 4. Testing

Testing is primarily handled through Nix-based environment checks to ensure the configuration loads correctly in a reproducible environment.

-   **Environment**: Defined in `nixos/testEnv.nix`.
-   **Validation**: Installation scripts perform pre-flight checks for dependencies (Neovim version, git, etc.).

## 5. Security

-   **User Isolation**: All personal configurations, including secrets or private settings, should be placed in `lua/user/`. This directory is populated from `lua/user_template/` and is intended to be gitignored or managed separately.
-   **Plugin Sources**: Plugins are fetched from GitHub. `lua/core/pack.lua` handles the cloning logic, supporting both SSH and HTTPS based on user preference.

## 6. Configuration Layers

The configuration is split into three main layers:

### 6.1 Core (`lua/core/`)
Handles the initialization of Neovim:
-   `init.lua`: Sets up paths, leader keys (defualt `<Space>`), environment, and bootstrap sequence.
    -   **Leader Key**: 默认映射为空格。为防止冲突，需显式禁用空格在 Normal/Visual 模式下的默认位移行为 (`vim.api.nvim_set_keymap("n", "<Space>", "<Nop>", ...)` )。
-   `pack.lua`: Bootstraps `lazy.nvim`. It dynamically discovers and loads plugins from both `lua/modules/plugins/*.lua` and `lua/user/plugins/*.lua`.
-   `global.lua`: Defines global variables and paths.
-   `options.lua` & `settings.lua`: Global editor options. `timeoutlen` 建议保持在 500ms 左右以兼顾快捷键响应与 Which-key 弹出。

### 6.2 Modules (`lua/modules/`)
Contains the bulk of the configuration, organized by functionality:
-   **Categories**: `completion`, `editor`, `lang`, `tool`, `ui`.
-   **Structure**:
    -   `plugins/`: Plugin declaration files.
    -   `configs/`: Detailed configuration logic for each plugin.

### 6.3 User (`lua/user/`)
The designated place for customization:
-   **Plugins**: `lua/user/plugins/*.lua` 自动加载并与核心插件列表合并。
-   **Settings**: `lua/user/options.lua` 和 `lua/user/settings.lua` 允许覆盖全局默认值。
-   **Keymaps**: `lua/user/keymap/` 用于定义个人快捷键。
-   **System Config**: `lua/user/sys_cfg/` 存放 IDE 风格配置（如 vscode 键位/设置），供特定环境参考。

## 7. Customization & Extension Mechanisms

### 7.1 Plugin Loading (`lua/modules/utils/init.lua`)
-   **`load_plugin(plugin_name, opts)`**: 核心配置加载器。
-   **逻辑**:
    1.  尝试加载 `lua/user/configs/<filename>.lua`。
    2.  若返回 **table**：递归合并 (`tbl_recursive_merge`) 到默认配置。
    3.  若返回 **function**：完全接管配置逻辑，调用该函数并传入默认 `opts`。
    4.  最后调用插件的 `setup` 方法。

### 7.2 Highlighting & Themes
-   **Palette System**: 使用 `lua/modules/utils/init.lua` 定义的中央色板（默认 Catppuccin）。
-   **Overrides**: 支持全局高亮 (`set_global_hl`) 和主题特定覆盖。

## 8. LSP & Completion Architecture

### 8.1 LSP Setup (`lua/modules/configs/completion/`)
-   使用 `mason.nvim` 管理工具链，`mason-lspconfig.lua` 作为核心调度器。
-   **Server Configs**: 各语言服务器配置位于 `modules/configs/completion/servers/`。
-   **全局逻辑**: 在 `mason-lspconfig` 的 `opts` 中定义全局 `on_attach`。
    -   **Boundary Fix**: 为兼容 Neovim 0.10.x 及处理部分 LSP 返回能力不一致的问题，全局 `on_attach` 中通常会将 `semanticTokensProvider` 显式设为 `nil` 以禁用可能导致崩溃的语义着色功能。该补丁应优先于具体服务器配置执行。

## 9. Keymapping System

### 9.1 Binding Helpers (`lua/keymap/bind.lua`)
-   提供 `map_cr`, `map_cu`, `map_cmd`, `map_callback` 等辅助函数。
-   支持链式调用，如 `:with_silent():with_noremap():with_desc("...")`。
-   **分层设计**: 分为 `builtins` (核心内置) 和 `plugins` (插件相关)，便于管理和覆盖。

## 10. Common Boundary Cases & Best Practices

-   **Lazy Loading**:
    -   UI/Tool 类插件（如 `which-key`, `noice`）建议使用 `event = "VeryLazy"` 以确保不影响启动速度且能正确响应 Leader key。
    -   避免使用 `CursorHold` 作为首选加载事件，除非明确需要该触发时机，因为它依赖 `updatetime`。
-   **Neovim Versioning**:
    -   本配置主要针对 Neovim 0.10+。对于 0.11+ 版本，某些内置 Lua 错误（如语义令牌空指针）已在核心修复，但配置层面的防护性代码（如 `on_attach` 拦截）仍建议保留以保证多版本兼容性。
-   **Keymap Conflicts**:
    -   如果按下 Leader key 后光标位移而非弹出提示，通常是由于 `init.lua` 中未对空格键进行 `Nop` 映射，或插件加载过晚。
-   **Diagnostic Filtering**:
    -   根据“只关注正式文件”原则，在 `trouble.nvim` 中彻底排除 `_test.go` 文件，从而忽略测试包循环依赖。
    -   示例：在 `trouble` 的 `modes` 中使用 `all` 组合过滤器，确保正式文件中的循环依赖等错误不会被意外忽略。
- **Search & Telescope**:
    -   `<leader>fw` 使用 `live_grep_args`，支持传递原生 `ripgrep` 参数。
    -   **核心规范**: 恢复了 `auto_quoting = true` 以保证普通搜索体验。
    -   **快捷键优化**: 实现了自定义 `quote_prompt_with_postfix` 逻辑，**彻底解决了按下快捷键时出现双重转义（如 `\"`）的问题**。
    -   **搜索流程**:
        1. 输入关键词。
        2. 若需添加参数（如字面量搜索或过滤），直接按 `<C-g>` 或 `<C-i>`。
        3. 快捷键会自动判断当前是否已加引号，并智能追加参数，不会产生重复转义。
    -   **内置快捷键 (在搜索框内按)**:
        -   `<C-k>`: 智能添加双引号（若未添加）。
        -   `<C-g>`: 智能加引号并追加 `-F`（字面量搜索）。
        -   `<C-i>`: 智能加引号并追加 `--iglob`（过滤文件）。
    -   **忽略目录**: `kitex_gen/`、`build/` 等目录在 `telescope.lua` 中默认被忽略。若需搜索这些目录，需临时在搜索框后添加 `--no-ignore` 或从配置文件中移除对应项。

- **Bookmark Management**:
    -   **核心工具**: 使用 `LintaoAmons/bookmarks.nvim` (v3+)，基于 `extmarks` 实现标记随代码自动移动。
    -   **持久化**: 依赖 `kkharji/sqlite.lua` 将书签存储在 SQLite 数据库中（默认路径 `stdpath("data")`）。
    -   **冲突预防**: 由于多个插件可能使用相同的 Repo 名称（如 `crusj/bookmarks.nvim`），在 `lazy.nvim` 配置中显式指定 `name = "bookmarks"` 以确保加载正确的模块路径。
    -   **项目隔离**: 
        -   通过 `Active List` 机制实现项目间隔离。
        -   自动化逻辑：监听 `VimEnter` 和 `DirChanged` 事件，根据当前 CWD 文件夹名自动切换 or 创建对应的 `Active List`。
        -   **稳定性**: 使用 `vim.defer_fn(..., 100)` 延迟执行切换逻辑，避免在插件初始化尚未完成时调用 API 导致报错。
    -   **交互优化**:
        -   实现 `_G.smart_toggle_bookmark` 函数。
        -   `mm`: 智能静默切换。若当前行无标记，弹出输入框输入名称；若已有标记，直接删除（传入空字符串实现静默取消）。
        -   **预览显示**: 在 Telescope 预览框中使用 `fnamemodify(path, ":~")` 将绝对路径（如 `/data00/home/xxx`）优化为以 `~` 开头的友好路径。
    -   **开发规范**:
        -   **LSP 诊断清理**: 在 Lua 回调中，对未使用的参数使用 `_` 命名（如 `entry_display = function(bookmark, _)`），避免触发 `unused-local` 警告。
        -   **注释规范**: 避免在配置文件中使用会导致 LSP 报告 `undefined-doc-name` 的模糊类型注释（如 `Bookmarks.Node`）。
    -   **快捷键规范**:
        -   `mm`: 智能静默切换标记。
        -   `mn`/`mp`: 基于行号顺序在当前文件中跳转。
        -   `<leader>m`: 调用内置 Telescope 选择器，支持实时代码预览。

- **Session & Workflow Management (新增)**:
    -   **插件替换**: 使用 `auto-session` 替代内置的 `persisted.nvim`。需在 `user/settings.lua` 中将 `persisted.nvim` 加入 `disabled_plugins` 以彻底消除启动报错。
    -   **多分支隔离**: 启用 `git_use_branch_name = true`。会话文件命名采用 `项目路径 + 分支名` 的复合键，确保不同分支的窗口布局、缓冲区状态互不干扰。
    -   **项目感知搜索**: `<leader>ss` 调用 `session-lens` 时，通过 `default_text = fnamemodify(getcwd(), ":t")` 实现项目内隔离，默认仅显示当前项目的相关会话，按 `退格键` 可恢复全局搜索。
    -   **UI 兼容性补丁**: 
        -   **Path Display**: 为防止 Telescope 在某些三方插件（如 `git-worktree`）中由于 `truncate` 策略导致 `layout` 字段空指针崩溃，全局默认应设为 `smart`。
        -   **Highlight Fallback**: 针对非 Catppuccin 主题（如 `elflord`），需手动定义 `TelescopeResultsIdentifier` 等高亮组链接（Link to `Identifier`），避免 Finder 渲染时抛出 `hl_group: Expected Lua string` 错误。
    -   **猴子补丁 (Monkey Patch)**: 对于存在代码缺陷的三方插件（如 `git-worktree` 的 Telescope 扩展），应在 `user/plugins/` 的 `config` 回调中进行函数重写。核心逻辑是修复其 `make_display` 函数中的数据结构，确保传递给渲染器的是纯字符串而非含有 `nil` 高亮组的 table。
