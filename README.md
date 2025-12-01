# mogra-toolchain.nvim

Define installation scripts for external tools as part of your Neovim configuration, making your entire setup portable—including all the programs needed to use it.

No more "clone dotfiles and hope everything works." Just open Neovim on a new machine, run `:Mogra`, and install everything you need.

## Features

- **Portable toolchain** — Define tools once in your config, install anywhere
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
    backdrop = 100,          -- Backdrop opacity (0-100, 100 = no backdrop)
  },
  log = {
    level = vim.log.levels.INFO,  -- Minimum log level (TRACE/DEBUG/INFO/WARN/ERROR)
    use_console = false,          -- Output to console ('sync', 'async', or false)
    use_file = false,             -- Write logs to file
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

> **Tip:** For tar-based tools where update is a reinstall, you can avoid duplication:
>
> ```lua
> get_update_cmd = function()
>   return tool_definition.get_install_cmd()
> end,
> ```

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

## Testing

The plugin uses [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing.

### Running Tests

```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests only
make test-integration

# Run snapshot tests only
make test-snapshot

# Run standalone tests (no Neovim required)
make test-standalone
```

### Snapshot Tests

The UI uses snapshot testing to verify rendered output. Snapshots are stored as JSON files in `tests/snapshots/`.

```bash
# Update snapshots when UI changes intentionally
make update-snapshots

# Or with environment variable
UPDATE_SNAPSHOTS=1 make test-snapshot
```

### Test Structure

```
tests/
├── fixtures/          # Test data and dummy tools
├── helpers/           # Test utilities (snapshot helper)
├── integration/       # Integration tests
├── mocks/             # Vim mock for standalone tests
├── snapshot/          # UI snapshot tests
├── snapshots/         # Stored snapshot files (.json)
├── unit/              # Unit tests
├── minimal_init.lua   # Test environment setup
└── run_standalone.lua # Standalone test runner
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
