local settings = require("mogra_toolchain.settings")

---@class MograToolchain
---@field name string
---@field version string
---@field description string
---@field author string
---@field license string
---@field config Config
---@field has_setup boolean
---@field setup fun(opts: Config?)
--- UI is exposed via require("mogra_toolchain.ui").open()
--- Installer/updater are implemented as commands: :MograInstallAll, :MograUpdateAll
local M = {}

M.name = "mogra_toolchain"
M.version = "0.1.0"
M.description = "A Mason-like interface for managing development tools"
M.author = "Bhargav Mogra"
M.license = "MIT"

-- Expose config getter for backward compatibility
M.config = setmetatable({}, {
  __index = function(_, _)
    return settings.current
  end,
})

M.has_setup = false

-- Configures the module and initializes the toolchain command interface.
-- @param opts Optional configuration table applied to the module before initialization. When provided, its fields are passed to the settings setup. The module's initialization state is set to true after this call.
function M.setup(opts)
  if opts then
    settings.setup(opts)
  end
  require("mogra_toolchain.api.command")
  M.has_setup = true
end

return M