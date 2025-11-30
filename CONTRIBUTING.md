# Contributing to mogra-toolchain.nvim

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/mogra-toolchain.nvim
   cd mogra-toolchain.nvim
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feat/my-feature
   ```

## Development Environment

### Requirements

- Neovim 0.9+ (for running tests)
- Lua 5.1+ or LuaJIT (for standalone tests)
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (installed automatically by test runner)

### Project Structure

```text
mogra-toolchain.nvim/
├── lua/mogra_toolchain/
│   ├── api/              # User-facing API
│   ├── plugins/          # Tool builders (homebrew, tar, etc.)
│   ├── ui/
│   │   ├── components/   # UI components (header, main)
│   │   └── core/         # Core UI utilities (display, state, etc.)
│   ├── health.lua        # Health check
│   ├── init.lua          # Plugin entry point
│   └── settings.lua      # Configuration
├── tests/
│   ├── fixtures/         # Test data and dummy tools
│   ├── helpers/          # Test utilities
│   ├── integration/      # Integration tests
│   ├── mocks/            # Vim mock for standalone tests
│   ├── snapshot/         # UI snapshot tests
│   ├── snapshots/        # Stored snapshot files (.json)
│   └── unit/             # Unit tests
├── Makefile
└── README.md
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run specific test suites
make test-unit          # Unit tests only
make test-integration   # Integration tests only
make test-snapshot      # Snapshot tests only

# Run without Neovim (uses vim mock)
make test-standalone
```

### Writing Tests

Tests use [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) which provides a busted-like syntax:

```lua
describe("my feature", function()
  before_each(function()
    -- Setup
  end)

  it("does something", function()
    assert.equals(expected, actual)
    assert.is_true(condition)
    assert.same(expected_table, actual_table)
  end)
end)
```

### Snapshot Testing

UI components use snapshot testing to catch unintended visual changes:

1. **Snapshots are JSON files** stored in `tests/snapshots/`
2. **To update snapshots** when you intentionally change the UI:
   ```bash
   make update-snapshots
   ```
3. **Review the diff** before committing:
   ```bash
   git diff tests/snapshots/
   ```

#### Adding New Snapshot Tests

```lua
local snapshot = require("helpers.snapshot")
local display = require("mogra_toolchain.ui.core.display")

it("renders my component", function()
  local state = create_test_state()
  local view = MyComponent(state)
  local output = display._render_node({ win_width = 80 }, view)

  snapshot.assert_match("my_component_name", snapshot.capture(output))
end)
```

## Code Style

### General Guidelines

- Follow existing code patterns and conventions
- Use descriptive variable and function names
- Keep functions focused and small (single responsibility)
- Prefer composition over inheritance

### Lua Style

- Use 2-space indentation
- Add type annotations with LuaCATS comments:
  ```lua
  ---@param name string The tool name
  ---@param opts? table Optional configuration
  ---@return Tool
  function M.create_tool(name, opts)
  ```
- Use `local` for all variables and functions unless exporting
- Return module tables at the end of files

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules | `snake_case` | `tool_state.lua` |
| Functions | `snake_case` | `create_tool()` |
| Local variables | `snake_case` | `tool_name` |
| Constants | `UPPER_SNAKE_CASE` | `INITIAL_STATE` |
| Classes/Types | `PascalCase` | `ToolState` |

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `test` | Adding or updating tests |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `style` | Formatting, missing semicolons, etc. |
| `perf` | Performance improvement |
| `chore` | Maintenance tasks |

### Examples

```
feat: add cargo builder for Rust tools

fix: resolve spinner animation freeze on window resize

docs: add snapshot testing documentation

test: add unit tests for functional utilities

refactor: extract log rendering into separate function
```

## Pull Request Process

1. **Before submitting:**
   - Ensure all tests pass: `make test`
   - Update snapshots if UI changed: `make update-snapshots`
   - Update documentation if needed

2. **PR description should include:**
   - What the change does
   - Why the change is needed
   - Any breaking changes
   - Screenshots for UI changes

3. **After submitting:**
   - Respond to review feedback
   - Keep the PR focused (one feature/fix per PR)

## Adding New Features

### New Tool Builder

To add a new builder plugin (like `homebrew.lua` or `tar.lua`):

1. Create the plugin file:
   ```lua
   -- lua/mogra_toolchain/plugins/mybuilder.lua
   local M = {}

   function M.tool(name)
     local builder = {
       _name = name,
       _description = "",
     }

     function builder:description(desc)
       self._description = desc
       return self
     end

     function builder:build()
       return {
         name = self._name,
         description = self._description,
         is_installed = function() ... end,
         get_install_cmd = function() ... end,
         get_update_cmd = function() ... end,
       }
     end

     return builder
   end

   return M
   ```

2. Add tests in `tests/unit/` or `tests/integration/`
3. Document usage in the README

### New UI Component

1. Create component in `lua/mogra_toolchain/ui/components/`
2. Follow the pattern of existing components (return a function that takes state)
3. Add snapshot tests for the component
4. Update `instance.lua` to include the component if needed

## Questions?

If you have questions or need help:

1. Check existing issues and discussions
2. Open a new issue with the `question` label
3. Reach out to maintainers

Thank you for contributing!
