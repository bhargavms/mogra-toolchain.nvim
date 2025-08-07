---@class MograToolchainModule
---@field register fun(self: Tool)
---@field setup fun(opts: Config)
local M = {}
local state = require("mogra_toolchain.state")

---@param tool Tool
function M.register(tool)
  if not tool then
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

return M
