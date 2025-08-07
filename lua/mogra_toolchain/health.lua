local state = require("mogra_toolchain.state")

local M = {}

function M.check()
  if not vim.health or not vim.health.start then
    vim.notify("Neovim health API not available", vim.log.levels.ERROR)
    return
  end

  vim.health.start("Mogra Toolchain")

  local tools = state.tools or {}

  if #tools == 0 then
    vim.health.warn("No tools registered in mogra_toolchain.")
    return
  end

  for _, tool in ipairs(tools) do
    if tool.is_installed and tool.is_installed() then
      vim.health.ok(tool.name .. " is installed")
    else
      vim.health.warn(tool.name .. " is available but NOT installed")
    end
  end
end

return M
