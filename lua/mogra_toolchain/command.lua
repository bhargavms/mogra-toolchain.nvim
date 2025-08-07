--@tag mogra_toolchain.command
local M = {}

local state = require("mogra_toolchain.state")

-- Install tool
function M.install_tool()
  local tool = state.get_current_tool()
  if tool then
    tool.install()
    return true
  end
  return false
end

-- Update tool
function M.update_tool()
  local tool = state.get_current_tool()
  if tool then
    tool.update()
    return true
  end
  return false
end

-- Install all tools
function M.install_all()
  for _, tool in ipairs(state.tools) do
    if not tool.is_installed() then
      tool.install()
    end
  end
end

-- Update all tools
function M.update_all()
  for _, tool in ipairs(state.tools) do
    if tool.is_installed() then
      tool.update()
    end
  end
end

return M
