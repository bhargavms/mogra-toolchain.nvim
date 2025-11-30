local M = {}

-- Closes the active UI instance.
function M.close()
  local api = require("mogra_toolchain.ui.instance")
  api.close()
end

-- Open the UI managed by the mogra_toolchain.ui.instance module.
function M.open()
  local api = require("mogra_toolchain.ui.instance")
  api.open()
end

-- Set the active UI view to the given view identifier.
-- @param view The view name or identifier to display.
function M.set_view(view)
  local api = require("mogra_toolchain.ui.instance")
  api.set_view(view)
end

-- Set the sticky cursor for the UI instance.
-- @param tag Arbitrary value used by the UI instance to identify or update the sticky cursor.
function M.set_sticky_cursor(tag)
  local api = require("mogra_toolchain.ui.instance")
  api.set_sticky_cursor(tag)
end

return M