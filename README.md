# Mogra Toolchain

A Mason-like interface for managing development tools in Neovim. This plugin provides a simple and intuitive way to manage various development tools directly from Neovim.

## Features

- Interactive UI for tool management
- Easily configure and register new tools

## Installation

The plugin is designed to be used with [lazy.nvim](https://github.com/folke/lazy.nvim). Add the following to your Neovim configuration:

```lua
{
  "bhargavms/mogra-toolchain",
  name = "mogra-toolchain",
  lazy = false, -- Load immediately since it's a core tool
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

## TODO
- [] Provide guide on how to add and register tools

## License

MIT License - see LICENSE file for details
