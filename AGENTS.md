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

### Plugin Management
Managed via `lazy.nvim` commands inside Neovim:
-   `Lazy sync`: Sync/Update plugins.
-   `Lazy profile`: Check startup time.

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

## 6. Configuration

The configuration is split into three main layers:

### Core (`lua/core/`)
Handles the initialization of Neovim:
-   `init.lua`: Sets up paths, leader keys, environment (GUI, clipboard, shell), and loads other core components.
-   `pack.lua`: Bootstraps `lazy.nvim`. It dynamically discovers and loads plugins from both `lua/modules/plugins/*.lua` and `lua/user/plugins/*.lua`.
-   `global.lua`: Defines global variables and paths.
-   `options.lua` & `settings.lua`: Global editor options.

### Modules (`lua/modules/`)
Contains the bulk of the configuration, organized by functionality:
-   **Categories**: `completion`, `editor`, `lang`, `tool`, `ui`.
-   **Structure**:
    -   `plugins/`: Plugin declaration files (returning tables of plugin specs).
    -   `configs/`: Detailed configuration logic for each plugin.

### User (`lua/user/`)
The designated place for customization:
-   **Plugins**: Files in `lua/user/plugins/` are automatically detected and merged with the core plugins.
-   **Settings**: `lua/user/options.lua` and `lua/user/settings.lua` allow overriding global defaults.
-   **Keymaps**: `lua/user/keymap/` allows defining custom keybindings.

## 7. Customization & Extension Mechanisms

The project utilizes a custom module loading system to allow flexible configuration overrides.

### Plugin Loading (`lua/modules/utils/init.lua`)
-   **`load_plugin(plugin_name, opts)`**: This function is the standard way to configure plugins in `lua/modules/configs/`.
-   **Mechanism**:
    1.  It attempts to load a corresponding user configuration from `lua/user/configs/<plugin_config_filename>.lua`.
    2.  If the user config returns a **table**, it recursively merges (`tbl_recursive_merge`) the user options into the default options.
    3.  If the user config returns a **function**, it replaces the default configuration logic or allows for complete control.
    4.  Finally, it calls the plugin's `setup` function with the merged/modified options.

### Highlighting & Themes
-   **Palette System**: The project uses a central palette (defaulting to Catppuccin's palette) defined in `lua/modules/utils/init.lua`.
-   **Overrides**:
    -   Global highlights can be set via `set_global_hl`.
    -   Theme-specific overrides (e.g., for `catppuccin`) are handled in the respective theme configuration files (e.g., `lua/modules/configs/ui/catppuccin.lua`).
    -   **Important**: Some plugins (like `render-markdown`) may require explicit highlight group definitions (`vim.api.nvim_set_hl`) in their setup function to avoid inheriting unwanted default links (e.g., `ColorColumn` red background).
