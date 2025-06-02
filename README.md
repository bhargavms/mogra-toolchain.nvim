# Mogra Toolchain

A Mason-like interface for managing development tools in Neovim. This plugin provides a simple and intuitive way to manage various development tools directly from Neovim.

## Features

- Interactive UI for tool management
- Support for multiple tool categories:
  - Go tools
  - NPM packages
  - LuaRocks modules
- Easy installation and updates
- User-level installations (no sudo required)

## Installation

The plugin is designed to be used with [lazy.nvim](https://github.com/folke/lazy.nvim). Add the following to your Neovim configuration:

```lua
{
  dir = vim.fn.stdpath "config" .. "/toolchain",
  name = "toolchain",
  lazy = false, -- Load immediately since it's a core tool
  dev = true,
  opts = {
    ui = {
      title = "Toolchain",
      width = 60,
      height = 20,
      border = "rounded",
    },
    tools = {
      -- Tool configurations will be registered by the plugin
    }
  },
  dependencies = {
    "nvim-lua/plenary.nvim", -- For utility functions
  },
}
```

## Usage

### Commands

- `:Toolchain` - Open the tools UI
- `:ToolchainInstallAll` - Install all tools
- `:ToolchainUpdateAll` - Update all tools

### UI Controls

- `i` - Install selected tool
- `u` - Update selected tool
- `j/k` - Navigate through tools
- `q` - Quit UI
- `<CR>` - Install selected tool

## Tool Categories

### Go Tools
Tools are loaded from `mogra.toolchain.tools.go` module.

### NPM Tools
Tools are loaded from `mogra.toolchain.tools.npm` module.

### LuaRocks Tools
Tools are loaded from `mogra.toolchain.tools.luarocks` module.

## Configuration

The plugin can be configured through the `opts` table in your lazy.nvim configuration:

```lua
opts = {
  ui = {
    title = "Toolchain",    -- UI window title
    width = 60,             -- UI window width
    height = 20,            -- UI window height
    border = "rounded",     -- UI window border style
  },
  tools = {
    -- Tool-specific configurations
  }
}
```

## Development

### Project Structure

```
toolchain/
├── init.lua      # Main plugin file
└── README.md     # This file
```

### Adding New Tools

To add new tools:
1. Create a new module in `mogra.toolchain.tools`
2. Implement the required tool interface
3. Register the tools in the module's `get_tools()` function

## License

MIT License - see LICENSE file for details
