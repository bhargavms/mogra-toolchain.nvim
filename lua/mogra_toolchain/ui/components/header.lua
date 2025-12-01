local Ui = require("mogra_toolchain.ui.core.ui")
local p = require("mogra_toolchain.ui.palette")
local settings = require("mogra_toolchain.settings")

-- Lazy-load mogra_toolchain only for version
local function get_version()
  return require("mogra_toolchain").version
end

---@param _state ToolchainUiState
return function(_state)
  local config = settings.current
  return Ui.Node({
    Ui.CascadingStyleNode({ "CENTERED" }, {
      Ui.HlTextNode({
        {
          p.header(" " .. (config.ui.title or "Toolchain") .. " "),
          p.header(get_version() .. " "),
        },
        { p.Comment("https://github.com/bhargavms/mogra-toolchain.nvim") },
      }),
    }),
  })
end
