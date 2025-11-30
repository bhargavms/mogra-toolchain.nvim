-- Dummy tools for testing
-- These tools simulate real tools without actually installing anything

local M = {}

-- Track installation state for testing
M._installed = {}
M._install_calls = {}
M._update_calls = {}

-- Reset state between tests
function M.reset()
  M._installed = {}
  M._install_calls = {}
  M._update_calls = {}
end

-- Mark a tool as installed
function M.set_installed(name, installed)
  M._installed[name] = installed
end

-- Check if install was called
function M.was_install_called(name)
  return M._install_calls[name] or false
end

-- Check if update was called
function M.was_update_called(name)
  return M._update_calls[name] or false
end

-- Create a simple dummy tool
---@param opts { name: string, description: string, installed?: boolean, install_fails?: boolean, update_fails?: boolean }
---@return Tool
function M.create_tool(opts)
  local name = opts.name
  M._installed[name] = opts.installed or false

  return {
    name = name,
    description = opts.description or "A dummy tool for testing",

    is_installed = function()
      return M._installed[name] == true
    end,

    install_cmd = opts.install_fails and "exit 1" or "echo 'Installing " .. name .. "'",

    update_cmd = opts.update_fails and "exit 1" or "echo 'Updating " .. name .. "'",

    get_install_cmd = function()
      M._install_calls[name] = true
      if opts.install_fails then
        return nil, "Installation failed for " .. name
      end
      return "echo 'Installing " .. name .. "'"
    end,

    get_update_cmd = function()
      M._update_calls[name] = true
      if opts.update_fails then
        return nil, "Update failed for " .. name
      end
      return "echo 'Updating " .. name .. "'"
    end,
  }
end

-- Create a tool that simulates slow installation
---@param opts { name: string, description: string, delay_ms?: number }
---@return Tool
function M.create_slow_tool(opts)
  local name = opts.name
  local delay = opts.delay_ms or 1000
  M._installed[name] = false

  return {
    name = name,
    description = opts.description or "A slow tool for testing",

    is_installed = function()
      return M._installed[name] == true
    end,

    get_install_cmd = function()
      M._install_calls[name] = true
      -- Simulate slow install with sleep
      return string.format("sleep %d && echo 'Installed %s'", delay / 1000, name)
    end,

    get_update_cmd = function()
      M._update_calls[name] = true
      return string.format("sleep %d && echo 'Updated %s'", delay / 1000, name)
    end,
  }
end

-- Create a tool with dynamic command generation
---@param opts { name: string, version?: string }
---@return Tool
function M.create_versioned_tool(opts)
  local name = opts.name
  local version = opts.version or "1.0.0"
  M._installed[name] = false

  return {
    name = name,
    description = "Tool " .. name .. " v" .. version,

    is_installed = function()
      return M._installed[name] == true
    end,

    get_install_cmd = function()
      M._install_calls[name] = true
      return string.format("echo 'Installing %s version %s'", name, version)
    end,

    get_update_cmd = function()
      M._update_calls[name] = true
      return string.format("echo 'Updating %s to version %s'", name, version)
    end,
  }
end

-- Predefined dummy tools for common test scenarios
M.tools = {
  -- A tool that's already installed
  installed_tool = M.create_tool({
    name = "installed-tool",
    description = "A tool that is already installed",
    installed = true,
  }),

  -- A tool that's not installed
  available_tool = M.create_tool({
    name = "available-tool",
    description = "A tool available for installation",
    installed = false,
  }),

  -- A tool that fails to install
  failing_tool = M.create_tool({
    name = "failing-tool",
    description = "A tool that fails to install",
    installed = false,
    install_fails = true,
  }),

  -- A tool that fails to update
  update_failing_tool = M.create_tool({
    name = "update-failing-tool",
    description = "A tool that fails to update",
    installed = true,
    update_fails = true,
  }),
}

-- Get a list of all predefined tools
function M.get_all_tools()
  return {
    M.tools.installed_tool,
    M.tools.available_tool,
    M.tools.failing_tool,
    M.tools.update_failing_tool,
  }
end

-- Get a minimal set of tools for basic tests
function M.get_basic_tools()
  return {
    M.create_tool({
      name = "tool-a",
      description = "First test tool",
      installed = true,
    }),
    M.create_tool({
      name = "tool-b",
      description = "Second test tool",
      installed = false,
    }),
  }
end

-- ============================================
-- UI State Fixtures for Snapshot Testing
-- ============================================

-- Create a ToolState-like object for snapshot testing (without requiring the real module)
---@param opts { name: string, description: string, install_state: string, is_log_expanded?: boolean, tailed_output?: string }
---@return table
function M.create_tool_state(opts)
  return {
    name = opts.name,
    description = opts.description,
    install_state = opts.install_state or "not_installed",
    is_log_expanded = opts.is_log_expanded ~= false, -- default true
    tailed_output = opts.tailed_output or "",
    is_installed = function()
      return opts.install_state == "installed"
    end,
  }
end

-- Create initial UI state structure matching ToolchainUiState
---@param tools table[]
---@return table
function M.create_ui_state(tools)
  return {
    view = {
      is_showing_help = false,
      is_searching = false,
    },
    header = {
      title_prefix = "",
    },
    tools = {
      all = tools or {},
      checking_statuses = false,
      line_to_tool = {},
    },
    log = {
      open = false,
      lines = {},
    },
  }
end

-- Get state with tools in "checking" state (initial load)
function M.get_checking_state()
  return M.create_ui_state({
    M.create_tool_state({
      name = "ripgrep",
      description = "Fast grep alternative",
      install_state = "checking",
    }),
    M.create_tool_state({
      name = "fd",
      description = "Fast find alternative",
      install_state = "checking",
    }),
    M.create_tool_state({
      name = "fzf",
      description = "Fuzzy finder",
      install_state = "checking",
    }),
  })
end

-- Get state with all tools installed
function M.get_installed_state()
  return M.create_ui_state({
    M.create_tool_state({
      name = "ripgrep",
      description = "Fast grep alternative",
      install_state = "installed",
    }),
    M.create_tool_state({
      name = "fd",
      description = "Fast find alternative",
      install_state = "installed",
    }),
    M.create_tool_state({
      name = "fzf",
      description = "Fuzzy finder",
      install_state = "installed",
    }),
  })
end

-- Get state with mixed installation statuses
function M.get_mixed_state()
  return M.create_ui_state({
    M.create_tool_state({
      name = "ripgrep",
      description = "Fast grep alternative",
      install_state = "installed",
    }),
    M.create_tool_state({
      name = "fd",
      description = "Fast find alternative",
      install_state = "not_installed",
    }),
    M.create_tool_state({
      name = "fzf",
      description = "Fuzzy finder",
      install_state = "installed",
    }),
    M.create_tool_state({
      name = "bat",
      description = "Cat with syntax highlighting",
      install_state = "not_installed",
    }),
  })
end

-- Get state with a tool currently installing (with log output)
function M.get_installing_state()
  local install_log = table.concat({
    "$ brew install ripgrep",
    "==> Downloading https://homebrew.bintray.com/bottles/ripgrep-13.0.0.big_sur.bottle.tar.gz",
    "==> Installing ripgrep",
    "==> Pouring ripgrep-13.0.0.big_sur.bottle.tar.gz",
  }, "\n")

  return M.create_ui_state({
    M.create_tool_state({
      name = "ripgrep",
      description = "Fast grep alternative",
      install_state = "installing",
      is_log_expanded = true,
      tailed_output = install_log,
    }),
    M.create_tool_state({
      name = "fd",
      description = "Fast find alternative",
      install_state = "installed",
    }),
    M.create_tool_state({
      name = "fzf",
      description = "Fuzzy finder",
      install_state = "not_installed",
    }),
  })
end

-- Get state with a tool that failed to install
function M.get_failed_state()
  return M.create_ui_state({
    M.create_tool_state({
      name = "ripgrep",
      description = "Fast grep alternative",
      install_state = "failed",
      is_log_expanded = true,
      tailed_output = "$ brew install ripgrep\nError: ripgrep: Failed to download resource\n✗ Install failed (see output above)",
    }),
    M.create_tool_state({
      name = "fd",
      description = "Fast find alternative",
      install_state = "installed",
    }),
  })
end

-- Get state with installing tool log collapsed
function M.get_installing_collapsed_state()
  local install_log = table.concat({
    "$ brew install ripgrep",
    "==> Downloading https://homebrew.bintray.com/bottles/ripgrep-13.0.0.big_sur.bottle.tar.gz",
    "==> Installing ripgrep",
    "==> Pouring ripgrep-13.0.0.big_sur.bottle.tar.gz",
    "==> Summary",
    "🍺  /usr/local/Cellar/ripgrep/13.0.0: 6 files, 5.3MB",
  }, "\n")

  return M.create_ui_state({
    M.create_tool_state({
      name = "ripgrep",
      description = "Fast grep alternative",
      install_state = "installing",
      is_log_expanded = false,
      tailed_output = install_log,
    }),
  })
end

-- Get empty state (no tools configured)
function M.get_empty_state()
  return M.create_ui_state({})
end

return M
