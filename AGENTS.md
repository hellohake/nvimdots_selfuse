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
- **Bookmark Management**:
    -   **核心工具**: 使用 `LintaoAmons/bookmarks.nvim` (v3+)，基于 `extmarks` 实现标记随代码自动移动。
    -   **持久化**: 依赖 `kkharji/sqlite.lua` 将书签存储在 SQLite 数据库中（默认路径 `stdpath("data")`）。
    -   **项目隔离**: 
        -   通过 `Active List` 机制实现项目间隔离。
        -   自动化逻辑：监听 `VimEnter` 和 `DirChanged` 事件，根据当前 CWD 文件夹名自动切换或创建对应的 `Active List`。
    -   **交互优化**:
        -   实现 `_G.smart_toggle_bookmark` 函数。
        -   `mm`: 如果当前行无标记，弹出输入框支持自定义名称；如果当前行已有标记，直接静默取消，无需二次确认或输入。
    -   **快捷键规范**:
        -   `mm`: 智能静默切换标记。
        -   `mn`/`mp`: 基于行号顺序在当前文件中跳转。
        -   `<leader>m`: 调用内置 Telescope 选择器，支持实时代码预览。
    -   **边界 Case**:
        -   若 `sqlite3` 运行库缺失，插件将无法加载。
        -   Telescope 扩展加载：该插件不注册标准 Telescope 扩展名，需通过 Lua API 直接调用。
