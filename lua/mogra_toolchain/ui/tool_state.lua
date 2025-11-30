---@alias InstallState "installed" | "not_installed" | "installing" | "failed" | "checking"

---@class ToolState
---@field name string
---@field description string
---@field is_installed fun(): boolean
---@field install_state InstallState Installation state: "installed", "not_installed", "installing", or "failed"
---@field install_cmd string? Optional install command string
---@field update_cmd string? Optional update command string
---@field get_install_cmd fun(): string?, string? Optional function that returns install command string or (nil, error_message)
---@field get_update_cmd fun(): string?, string? Optional function that returns update command string or (nil, error_message)
---@field is_log_expanded boolean Whether the log output is expanded
---@field tailed_output string Full log output
---@field short_tailed_output string? Last non-empty line for preview
local ToolState = {}
ToolState.__index = ToolState

---Create a new ToolState instance
---@param tool Tool The tool configuration to create state for
---@return ToolState
function ToolState.new(tool)
  local self = setmetatable({}, ToolState)

  self.name = tool.name
  self.description = tool.description
  self.is_installed = tool.is_installed
  self.install_state = "checking" -- Start in checking state, will be updated async
  self.install_cmd = tool.install_cmd
  self.update_cmd = tool.update_cmd
  self.get_install_cmd = tool.get_install_cmd
  self.get_update_cmd = tool.get_update_cmd
  self.is_log_expanded = false
  self.tailed_output = ""
  self.short_tailed_output = nil

  return self
end

---Install this tool
---@param mutate_state fun(fn: fun(state: ToolchainUiState))
function ToolState:install(mutate_state)
  -- Reset log state
  self.tailed_output = ""
  self.short_tailed_output = nil
  self.is_log_expanded = false

  local cmd = nil
  local err = nil

  if self.get_install_cmd then
    cmd, err = self.get_install_cmd()
  elseif self.install_cmd then
    cmd = self.install_cmd
  end

  if cmd then
    -- Set install_state to installing
    self.install_state = "installing"
    mutate_state(function(_) end) -- Trigger re-render to show installing section

    -- Add line to log
    local function add_output(line)
      if self.tailed_output ~= "" then
        self.tailed_output = self.tailed_output .. "\n" .. line
      else
        self.tailed_output = line
      end
      -- Update short_tailed_output with last non-empty line
      if not line:match("^%s*$") then
        self.short_tailed_output = line:gsub("^%s+", "")
      end
      -- Keep only last 100 lines
      local lines = vim.split(self.tailed_output, "\n")
      if #lines > 100 then
        self.tailed_output = table.concat(vim.list_slice(lines, #lines - 99, #lines), "\n")
      end
      mutate_state(function(_) end) -- Trigger re-render
    end

    add_output("$ " .. cmd)

    -- Run command with per-invocation output handler
    local command_runner = require("mogra_toolchain.ui.command_runner")
    command_runner.run(cmd, add_output, function(success)
      if success then
        add_output("✓ Install completed successfully")
        self.install_state = "installed"
      else
        add_output("✗ Install failed (see output above)")
        self.install_state = "failed"
      end
      mutate_state(function(_) end) -- Trigger final re-render
    end)
  elseif err then
    self.tailed_output = "✗ Cannot install: " .. tostring(err)
    self.short_tailed_output = self.tailed_output
    mutate_state(function(_) end)
  else
    self.tailed_output = "⚠ This tool doesn't have an install command configured."
    self.short_tailed_output = self.tailed_output
    mutate_state(function(_) end)
  end
end

---Update this tool
---@param mutate_state fun(fn: fun(state: ToolchainUiState))
function ToolState:update(mutate_state)
  -- Reset log state
  self.tailed_output = ""
  self.short_tailed_output = nil
  self.is_log_expanded = false

  local cmd = nil
  local err = nil

  if self.get_update_cmd then
    cmd, err = self.get_update_cmd()
  elseif self.update_cmd then
    cmd = self.update_cmd
  end

  if cmd then
    -- Set install_state to installing
    self.install_state = "installing"
    mutate_state(function(_) end) -- Trigger re-render to show installing section

    -- Add line to log
    local function add_output(line)
      if self.tailed_output ~= "" then
        self.tailed_output = self.tailed_output .. "\n" .. line
      else
        self.tailed_output = line
      end
      -- Update short_tailed_output with last non-empty line
      if not line:match("^%s*$") then
        self.short_tailed_output = line:gsub("^%s+", "")
      end
      -- Keep only last 100 lines
      local lines = vim.split(self.tailed_output, "\n")
      if #lines > 100 then
        self.tailed_output = table.concat(vim.list_slice(lines, #lines - 99, #lines), "\n")
      end
      mutate_state(function(_) end) -- Trigger re-render
    end

    add_output("$ " .. cmd)

    -- Run command with per-invocation output handler
    local command_runner = require("mogra_toolchain.ui.command_runner")
    command_runner.run(cmd, add_output, function(success)
      if success then
        add_output("✓ Update completed successfully")
        self.install_state = "installed"
      else
        add_output("✗ Update failed (see output above)")
        self.install_state = "failed"
      end
      mutate_state(function(_) end) -- Trigger final re-render
    end)
  elseif err then
    self.tailed_output = "✗ Cannot update: " .. tostring(err)
    self.short_tailed_output = self.tailed_output
    mutate_state(function(_) end)
  else
    self.tailed_output = "⚠ This tool doesn't have an update command configured."
    self.short_tailed_output = self.tailed_output
    mutate_state(function(_) end)
  end
end

return ToolState
