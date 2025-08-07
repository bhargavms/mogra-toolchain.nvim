local module = require("mogra_toolchain.module")
local ui = require("mogra_toolchain.ui")
local command = require("mogra_toolchain.command")

---@class Tool
---@field name string
---@field description string
---@field is_installed fun(self: Tool): boolean
---@field install fun(self: Tool): boolean
---@field update fun(self: Tool): boolean

---@class Config
---@field ui UI
---@field tools Tool[]
local config = {
  ui = {
    title = "Toolchain",
    width = 60,
    height = 20,
    border = "rounded",
  },
  tools = {},
}

---@class MograToolchain
---@field name string
---@field version string
---@field description string
---@field author string
---@field license string
---@field open_ui fun()
---@field install_all fun()
---@field update_all fun()
local M = {}

M.name = "mogra_toolchain"
M.version = "0.1.0"
M.description = "A Mason-like interface for managing development tools"
M.author = "Bhargav Mogra"
M.license = "MIT"

---@type Config
M.config = config

---@param opts Config?
function M.setup(opts)
  -- Merge user options with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  ui.setup(M.config.ui)
  for _, tool in ipairs(M.config.tools) do
    module.register(tool)
  end
end

function M.open_ui()
  ui.open_ui()
end

function M.install_all()
  command.install_all()
end

function M.update_all()
  command.update_all()
end

return M
