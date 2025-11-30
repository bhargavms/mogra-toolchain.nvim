local settings = require("mogra_toolchain.settings")

local M = {}

---@param tool Tool
-- Validate a tool descriptor and report Neovim health errors for missing or invalid fields.
-- @param tool Table describing a tool. Expected keys: `name` (string), `description` (string), `is_installed` (function), and either `install_cmd` (string) or `get_install_cmd` (function).
-- @return `true` if the tool descriptor contains all required fields, `false` otherwise.
local function checkTool(tool)
  if not tool then
    vim.health.error("mogra_toolchain: Invalid tool object provided to register")
    return false
  end

  -- Validate required tool properties
  if not tool.name then
    vim.health.error("mogra_toolchain: Tool missing required property 'name'")
    return false
  end

  local name = tool.name or "<unknown>"

  if not tool.description then
    vim.health.error("mogra_toolchain: Tool '" .. name .. "' missing required property 'description'")
    return false
  end

  if not tool.is_installed then
    vim.health.error("mogra_toolchain: Tool '" .. name .. "' missing required property 'is_installed' (function)")
    return false
  end

  -- Check for install command (either install_cmd string or get_install_cmd function)
  local has_install = tool.install_cmd or tool.get_install_cmd
  if not has_install then
    vim.health.error("mogra_toolchain: Tool '" .. name .. "' missing install command. Add 'install_cmd' (string) or 'get_install_cmd' (function)")
    return false
  end

  return true
end

-- Run health checks for all configured mogra_toolchain tools and report their installation status.
-- 
-- If the Neovim health API is unavailable, posts an error notification and returns.
-- Starts a health section titled "Mogra Toolchain". If no tools are configured, logs a health warning and returns.
-- For each tool that passes validation, logs `ok` if the tool reports installed, otherwise logs a health warning that the tool is available but not installed.
function M.check()
  if not vim.health or not vim.health.start then
    vim.notify("Neovim health API not available", vim.log.levels.ERROR)
    return
  end

  vim.health.start("Mogra Toolchain")

  local tools = settings.current.tools or {}

  if #tools == 0 then
    vim.health.warn("No tools registered in mogra_toolchain.")
    return
  end

  for _, tool in ipairs(tools) do
    if checkTool(tool) then
      if tool.is_installed and tool.is_installed() then
        vim.health.ok(tool.name .. " is installed")
      else
        vim.health.warn(tool.name .. " is available but NOT installed")
      end
    end
  end
end

return M