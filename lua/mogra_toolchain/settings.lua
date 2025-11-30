local M = {}

---@class Tool
---@field name string
---@field description string
---@field is_installed fun(): boolean
---@field install_cmd string? Optional install command string
---@field update_cmd string? Optional update command string
---@field get_install_cmd fun(): string?, string? Optional function that returns install command string or (nil, error_message)
---@field get_update_cmd fun(): string?, string? Optional function that returns update command string or (nil, error_message)

---@class UIConfig
---@field title string
---@field width number Float 0-1 for percentage of screen, or integer > 1 for fixed width
---@field height number Float 0-1 for percentage of screen, or integer > 1 for fixed height
---@field border string

---@class Config
---@field ui UIConfig
---@field tools Tool[]
local DEFAULT_SETTINGS = {
  ui = {
    title = "Toolchain",
    width = 0.8, -- 80% of screen width (same as Mason)
    height = 0.9, -- 90% of screen height (same as Mason)
    border = "rounded",
  },
  tools = {},
}

M._DEFAULT_SETTINGS = DEFAULT_SETTINGS
M.current = vim.deepcopy(M._DEFAULT_SETTINGS)

---@param opts Config?
function M.setup(opts)
  if opts then
    M.current = vim.tbl_deep_extend("force", vim.deepcopy(M.current), opts)
  end
end

return M
