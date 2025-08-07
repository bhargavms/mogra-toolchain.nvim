local M = {}

local state = require("mogra_toolchain.state")
local command = require("mogra_toolchain.command")

---@class UI
---@field title string
---@field width integer
---@field height integer
---@field border string
M.ui = {}

---@param ui UI
function M.setup(ui)
  M.ui = ui
end

-- Create UI window
function M.open_ui()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
    state.buf = nil
    return
  end

  -- Create buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].modifiable = true
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].swapfile = false

  -- Create window
  local width = M.ui.width
  local height = M.ui.height
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = M.ui.border,
    title = M.ui.title,
    title_pos = "center",
  })

  -- Set up autocommand to clear state when window is closed
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = state.buf,
    callback = function()
      state.win = nil
      state.buf = nil
    end,
  })

  vim.wo[state.win].wrap = false
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].signcolumn = "no"

  -- Draw UI
  M.draw_ui()

  -- Set key mappings
  vim.keymap.set("n", "i", function()
    if command.install_tool() then
      M.draw_ui()
    end
  end, { buffer = state.buf })

  vim.keymap.set("n", "u", function()
    if command.update_tool() then
      M.draw_ui()
    end
  end, { buffer = state.buf })

  vim.keymap.set("n", "q", function()
    M.open_ui()
  end, { buffer = state.buf })

  vim.keymap.set("n", "<CR>", function()
    if command.install_tool() then
      M.draw_ui()
    end
  end, { buffer = state.buf })

  vim.keymap.set("n", "j", function()
    M.move_selection(1)
  end, { buffer = state.buf })

  vim.keymap.set("n", "k", function()
    M.move_selection(-1)
  end, { buffer = state.buf })
end

-- Draw UI
function M.draw_ui()
  local lines = {}
  local width = M.ui.width

  -- Header
  table.insert(lines, string.rep("─", width))
  table.insert(lines, " " .. M.ui.title)
  table.insert(lines, string.rep("─", width))
  table.insert(lines, "")

  -- Tools
  for i, tool in ipairs(state.tools) do
    local status = tool.is_installed() and "✓" or "✗"
    local line = string.format(" %s %s - %s", status, tool.name, tool.description)
    if i == state.selected then
      line = "> " .. line
    else
      line = "  " .. line
    end
    table.insert(lines, line)
  end

  -- Footer
  table.insert(lines, "")
  table.insert(lines, string.rep("─", width))
  table.insert(lines, " i: Install  u: Update  q: Quit")
  table.insert(lines, string.rep("─", width))

  -- Set buffer content
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
end

-- Move selection
function M.move_selection(delta)
  state.selected = math.max(1, math.min(#state.tools, state.selected + delta))
  M.draw_ui()
end

return M
