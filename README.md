# Mogra Toolchain

A Mason-like interface for managing development tools in Neovim. This plugin provides a simple and intuitive way to manage various development tools directly from Neovim.

## Features

- Interactive UI for tool management
- Easily configure and register new tools
- Abstract tools for common installation methods (tar balls, package managers)
- Fluent builder pattern API for tool configuration

## Installation

The plugin is designed to be used with [lazy.nvim](https://github.com/folke/lazy.nvim). Add the following to your Neovim configuration:

```lua
{
  "bhargavms/mogra_toolchain",
  name = "mogra_toolchain",
  lazy = false, -- Load immediately since it's a core tool
  opts = {
    ui = {
      title = "Toolchain",
      width = 60,
      height = 20,
      border = "rounded",
    },
    tools = {
      {
        name = "ripgrep",
        description = "A fast search tool",
        is_installed = function()
          return vim.fn.executable("rg") == 1
        end,
        install = function()
          os.execute("brew install ripgrep")
          return vim.fn.executable("rg") == 1
        end,
        update = function()
          os.execute("brew upgrade ripgrep")
          return vim.fn.executable("rg") == 1
        end,
      }
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
local tar_tool = require("mogra_toolchain.tools.tar")
local homebrew_tool = require("mogra_toolchain.tools.homebrew")

opts = {
  ui = {
    title = "Toolchain",    -- UI window title
    width = 60,             -- UI window width
    height = 20,            -- UI window height
    border = "rounded",     -- UI window border style
  },
  tools = {
    -- Example: Using the builder pattern for tar-based installation
    tar_tool.tool("fd")
      :description("A simple, fast and user-friendly alternative to 'find'")
      :version("8.7.0")
      :url("https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-apple-darwin.tar.gz")
      :install_dir(vim.fn.stdpath("data") .. "/tools/fd")
      :executable_dir(vim.fn.stdpath("data") .. "/bin")
      :post_install(function()
        -- Optional: Add any post-installation steps here
        return true
      end)
      :build(),

    -- Example: Using the builder pattern for Homebrew installation
    homebrew_tool.tool("ripgrep")
      :description("A fast search tool")
      :package_name("ripgrep") -- Optional: defaults to tool name
      :post_install(function()
        -- Optional: Add any post-installation steps here
        return true
      end)
      :post_update(function()
        -- Optional: Add any post-update steps here
        return true
      end)
      :build(),

    -- Example: Minimal configuration with defaults
    homebrew_tool.tool("jq")
      :description("Command-line JSON processor")
      :build(),
  }
}
```

=======
### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ui.title` | string | `"Toolchain"` | Title of the UI window |
| `ui.width` | number | `60` | Width of the UI window |
| `ui.height` | number | `20` | Height of the UI window |
| `ui.border` | string | `"rounded"` | Border style of the UI window |
| `tools` | Tool[] | `{}` | Array of tools to manage |

## License

MIT License - see LICENSE file for details
