local M = {}

function M.close()
  local api = require("mogra_toolchain.ui.instance")
  api.close()
end

function M.open()
  local api = require("mogra_toolchain.ui.instance")
  api.open()
end

---@param view string
function M.set_view(view)
  local api = require("mogra_toolchain.ui.instance")
  api.set_view(view)
end

---@param tag any
function M.set_sticky_cursor(tag)
  local api = require("mogra_toolchain.ui.instance")
  api.set_sticky_cursor(tag)
end

return M
