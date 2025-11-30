local M = {}

---@class HomebrewToolBuilder
---@field _name string
---@field _description string?
---@field _package_name string?
---@field _post_install function?
---@field _post_update function?
local HomebrewToolBuilder = {}
HomebrewToolBuilder.__index = HomebrewToolBuilder

---@param name string
---@return HomebrewToolBuilder
function M.tool(name)
  local builder = setmetatable({
    _name = name,
    _description = nil,
    _package_name = nil,
    _post_install = nil,
    _post_update = nil,
  }, HomebrewToolBuilder)
  return builder
end

---@param description string
---@return HomebrewToolBuilder
function HomebrewToolBuilder:description(description)
  self._description = description
  return self
end

---@param package_name string
---@return HomebrewToolBuilder
function HomebrewToolBuilder:package_name(package_name)
  self._package_name = package_name
  return self
end

---@param post_install function
---@return HomebrewToolBuilder
function HomebrewToolBuilder:post_install(post_install)
  self._post_install = post_install
  return self
end

---@param post_update function
---@return HomebrewToolBuilder
function HomebrewToolBuilder:post_update(post_update)
  self._post_update = post_update
  return self
end

---@return Tool
function HomebrewToolBuilder:build()
  if not self._name or not self._description then
    error("Missing required fields: name and description are required")
  end

  local config = {
    name = self._name,
    description = self._description,
    package_name = self._package_name or self._name,
    post_install = self._post_install,
    post_update = self._post_update,
  }

  return M.create_homebrew_tool(config)
end

---@class HomebrewToolConfig
---@field name string Name of the tool (required)
---@field description string Description of the tool (required)
---@field package_name string Name of the Homebrew package (required)
---@field post_install function? Optional function to run after installation
---@field post_update function? Optional function to run after update

---@param config HomebrewToolConfig
-- Create a Homebrew-backed tool descriptor from the provided configuration.
-- @param config Table with required fields:
--   - name (string): tool executable name.
--   - description (string): short description of the tool.
--   - package_name (string): Homebrew package name to install/upgrade.
--   - post_install? (function): optional callback to run after installation (not invoked by this function).
--   - post_update? (function): optional callback to run after update (not invoked by this function).
-- @return Tool A table with:
--   - name (string)
--   - description (string)
--   - is_installed (function): returns `true` if the tool executable is available in PATH, `false` otherwise.
--   - get_install_cmd (function): returns `"<brew install ...>"` if Homebrew is available, otherwise `nil, "Homebrew is not installed"`.
--   - get_update_cmd (function): returns `"<brew upgrade ...>"` if Homebrew is available, otherwise `nil, "Homebrew is not installed"`.
function M.create_homebrew_tool(config)
  if not config.name or not config.description or not config.package_name then
    error("Missing required fields in HomebrewToolConfig")
  end

  -- Helper function to check if tool is installed
  local function is_installed()
    return vim.fn.executable(config.name) == 1
  end

  -- Checks whether Homebrew is available on the system.
  -- @return `true` if the `brew` executable is available in PATH, `false` otherwise.
  local function is_homebrew_installed()
    return vim.fn.executable("brew") == 1
  end

  -- Builds a Homebrew CLI command string for the configured package.
  -- @param command The Homebrew subcommand to run (for example, "install" or "upgrade").
  -- @return The full `brew` command string targeting the builder's package (e.g., "brew install <package>").
  local function get_brew_command(command)
    return string.format("brew %s %s", command, config.package_name)
  end

  local tool = {
    name = config.name,
    description = config.description,
    is_installed = is_installed,
    -- Get the install command string dynamically (checks Homebrew availability at call time)
    get_install_cmd = function()
      if not is_homebrew_installed() then
        return nil, "Homebrew is not installed"
      end
      return get_brew_command("install")
    end,
    -- Get the update command string dynamically (checks Homebrew availability at call time)
    get_update_cmd = function()
      if not is_homebrew_installed() then
        return nil, "Homebrew is not installed"
      end
      return get_brew_command("upgrade")
    end,
  }

  return tool
end

return M