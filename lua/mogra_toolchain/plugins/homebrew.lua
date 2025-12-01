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
---@return Tool
function M.create_homebrew_tool(config)
  if not config.name or not config.description or not config.package_name then
    error("Missing required fields in HomebrewToolConfig")
  end

  -- Helper function to check if tool is installed
  local function is_installed()
    return vim.fn.executable(config.name) == 1
  end

  local function is_homebrew_installed()
    return vim.fn.executable("brew") == 1
  end

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
    -- Hooks to run after installation/update completes
    post_install = config.post_install,
    post_update = config.post_update,
  }

  return tool
end

return M
