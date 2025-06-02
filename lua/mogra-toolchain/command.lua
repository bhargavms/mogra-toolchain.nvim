--@tag mogra-toolchain.command
local M = {}

local state = require("mogra-toolchain.state")

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
