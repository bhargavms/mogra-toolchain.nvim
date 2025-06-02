local M = {}

-- UI state
local state = {
  win = nil,
  buf = nil,
  tools = {},
  selected = 1,
}

-- Plugin metadata for lazy.nvim
M.name = "mogra-toolchain"
M.version = "0.1.0"
M.description = "A Mason-like interface for managing development tools"
M.author = "Bhargav Mogra"
M.license = "MIT"

-- Default configuration
M.config = {
  -- UI configuration
  ui = {
    title = "Toolchain",
    width = 60,
    height = 20,
    border = "rounded",
  },
  -- Tool configurations
  tools = {
    -- Add tool-specific configurations here if needed
  },
}

M.check = function()
  vim.health.start "mogra-toolchain"
  local tools = M.state.tools or {}

  if #tools == 0 then
    vim.health.warn "No tools registered in mogra-toolchain."
    return
  end

  for _, tool in ipairs(tools) do
    if tool.is_installed and tool.is_installed() then
      vim.health.ok(tool.name .. " is installed")
    else
      vim.health.error(tool.name .. " is NOT installed")
    end
  end
end

-- Register a tool
function M.register(tool)
  if not tool or type(tool) ~= "table" then
    vim.notify("Invalid tool object provided to register", vim.log.levels.ERROR)
    return
  end

  -- Validate required tool properties
  if not tool.name or not tool.description or not tool.install or not tool.update or not tool.is_installed then
    vim.notify("Tool object missing required properties (name, description, install, update, is_installed)", vim.log.levels.ERROR)
    return
  end

  -- Add tool to state
  table.insert(state.tools, tool)
end

-- Initialize the plugin
function M.setup(opts)
  -- Merge user options with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Create user commands
  vim.api.nvim_create_user_command("Toolchain", function()
    M.open_ui()
  end, { desc = "Open Mogra Tools UI" })

  vim.api.nvim_create_user_command("ToolchainInstallAll", function()
    M.install_all()
  end, { desc = "Install all tools" })

  vim.api.nvim_create_user_command("ToolchainUpdateAll", function()
    M.update_all()
  end, { desc = "Update all tools" })
end

-- Create UI window
function M.open_ui()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
    state.buf = nil
    return
  end

  -- Create buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].modifiable = true
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].swapfile = false

  -- Create window
  local width = M.config.ui.width
  local height = M.config.ui.height
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = M.config.ui.border,
    title = M.config.ui.title,
    title_pos = "center",
  })

  -- Set up autocommand to clear state when window is closed
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = state.buf,
    callback = function()
      state.win = nil
      state.buf = nil
    end,
  })

  vim.wo[state.win].wrap = false
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].signcolumn = "no"

  -- Draw UI
  M.draw_ui()

  -- Set key mappings
  vim.keymap.set("n", "i", function()
    M.install_tool()
  end, { buffer = state.buf })
  vim.keymap.set("n", "u", function()
    M.update_tool()
  end, { buffer = state.buf })
  vim.keymap.set("n", "q", function()
    M.open_ui()
  end, { buffer = state.buf })
  vim.keymap.set("n", "<CR>", function()
    M.install_tool()
  end, { buffer = state.buf })
  vim.keymap.set("n", "j", function()
    M.move_selection(1)
  end, { buffer = state.buf })
  vim.keymap.set("n", "k", function()
    M.move_selection(-1)
  end, { buffer = state.buf })
end

-- Draw UI
function M.draw_ui()
  local lines = {}
  local width = M.config.ui.width

  -- Header
  table.insert(lines, string.rep("─", width))
  table.insert(lines, " " .. M.config.ui.title)
  table.insert(lines, string.rep("─", width))
  table.insert(lines, "")

  -- Tools
  for i, tool in ipairs(state.tools) do
    local status = tool.is_installed() and "✓" or "✗"
    local line = string.format(" %s %s - %s", status, tool.name, tool.description)
    if i == state.selected then
      line = "> " .. line
    else
      line = "  " .. line
    end
    table.insert(lines, line)
  end

  -- Footer
  table.insert(lines, "")
  table.insert(lines, string.rep("─", width))
  table.insert(lines, " i: Install  u: Update  q: Quit")
  table.insert(lines, string.rep("─", width))

  -- Set buffer content
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
end

-- Move selection
function M.move_selection(delta)
  state.selected = math.max(1, math.min(#state.tools, state.selected + delta))
  M.draw_ui()
end

-- Get current tool
function M.get_current_tool()
  return state.tools[state.selected]
end

-- Install tool
function M.install_tool()
  local tool = M.get_current_tool()
  if tool then
    tool.install()
    M.draw_ui()
  end
end

-- Update tool
function M.update_tool()
  local tool = M.get_current_tool()
  if tool then
    tool.update()
    M.draw_ui()
  end
end

-- Install all tools
function M.install_all()
  for _, tool in ipairs(state.tools) do
    if not tool.is_installed() then
      tool.install()
    end
  end
  M.draw_ui()
end

-- Update all tools
function M.update_all()
  for _, tool in ipairs(state.tools) do
    if tool.is_installed() then
      tool.update()
    end
  end
  M.draw_ui()
end

return M
