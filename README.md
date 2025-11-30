# mogra-toolchain.nvim

A Mason-inspired tool manager for Neovim. Define, install, and update development tools with a clean UI and live output.

## Features

- **Live installation output** — See command output in real-time while tools install
- **Flexible tool definitions** — Use simple command strings or dynamic functions
- **Built-in builders** — Helpers for Homebrew and tarball installations

## Installation

### lazy.nvim

```lua
{
  "mogra/mogra-toolchain.nvim",
  opts = {
    tools = {
      {
        name = "ripgrep",
        description = "Fast grep alternative",
        install_cmd = "brew install ripgrep",
        update_cmd = "brew upgrade ripgrep",
        is_installed = function()
          return vim.fn.executable("rg") == 1
        end,
      },
    },
  },
}
```

## Usage

| Command | Description |
|---------|-------------|
| `:Mogra` | Open the UI |
| `:MograInstallAll` | Install all tools |
| `:MograUpdateAll` | Update all tools |

### Keybinds

| Key | Action |
|-----|--------|
| `i` | Install tool under cursor |
| `u` | Update tool under cursor |
| `Enter` | Install tool under cursor |
| `j`/`k` | Navigate (native vim) |
| `q` / `Esc` | Close window |

## Configuration

```lua
opts = {
  ui = {
    title = "Toolchain",     -- Window title
    width = 0.8,             -- 80% of screen (or fixed number)
    height = 0.9,            -- 90% of screen (or fixed number)
    border = "rounded",      -- Border style
  },
  tools = { ... },
}
```

## Defining Tools

### Simple tool

```lua
{
  name = "ripgrep",
  description = "Fast grep alternative",
  install_cmd = "brew install ripgrep",
  update_cmd = "brew upgrade ripgrep",
  is_installed = function()
    return vim.fn.executable("rg") == 1
  end,
}
```

### Dynamic commands

Use `get_install_cmd` / `get_update_cmd` for runtime logic:

```lua
{
  name = "fd",
  description = "Fast find alternative",
  get_install_cmd = function()
    if vim.fn.executable("brew") == 1 then
      return "brew install fd"
    elseif vim.fn.executable("apt") == 1 then
      return "sudo apt install fd-find"
    end
    return nil, "No supported package manager"
  end,
  get_update_cmd = function()
    if vim.fn.executable("brew") == 1 then
      return "brew upgrade fd"
    end
    return nil, "No supported package manager"
  end,
  is_installed = function()
    return vim.fn.executable("fd") == 1
  end,
}
```

### Using builders

#### Homebrew

```lua
local homebrew = require("mogra_toolchain.plugins.homebrew")

homebrew.tool("jq")
  :description("Command-line JSON processor")
  :build()
```

#### Tarball from GitHub

```lua
local tar = require("mogra_toolchain.plugins.tar")

tar.tool("fd")
  :description("Fast find alternative")
  :version("10.2.0")
  :url("https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-apple-darwin.tar.gz")
  :install_dir(vim.fn.stdpath("data") .. "/tools/fd")
  :executable_dir(vim.fn.stdpath("data") .. "/bin")
  :build()
```

## Tool Definition Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✓ | Tool name |
| `description` | string | ✓ | Short description |
| `is_installed` | function | ✓ | Returns `true` if installed |
| `install_cmd` | string | | Shell command to install |
| `update_cmd` | string | | Shell command to update |
| `get_install_cmd` | function | | Returns `(cmd, err)` |
| `get_update_cmd` | function | | Returns `(cmd, err)` |

## Health Check

Run `:checkhealth mogra_toolchain` to see the status of all configured tools.

## License

MIT
