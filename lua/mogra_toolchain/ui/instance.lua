-- Adapted from Mason's UI instance for mogra-toolchain
local Ui = require("mogra_toolchain.ui.core.ui")
local _ = require("mogra_toolchain.ui.core.functional")
local display = require("mogra_toolchain.ui.core.display")

-- Use settings module directly to avoid circular dependency
local settings = require("mogra_toolchain.settings")
local ToolState = require("mogra_toolchain.ui.tool_state")

local Header = require("mogra_toolchain.ui.components.header")
local Main = require("mogra_toolchain.ui.components.main")

require("mogra_toolchain.ui.colors")

-- Create a UI node that registers global keybindings for window and tool actions.
-- @param _state The current toolchain UI state (accepted for component signature; not used).
-- @return A Ui.Node containing keybindings for closing the window (`q`, `<Esc>`),
-- installing a tool (`i`, `<CR>`), and updating a tool (`u`).
local function GlobalKeybinds(_state)
  return Ui.Node({
    Ui.Keybind("q", "CLOSE_WINDOW", nil, true),
    Ui.Keybind("<Esc>", "CLOSE_WINDOW", nil, true),
    Ui.Keybind("i", "INSTALL_TOOL", nil, true),
    Ui.Keybind("u", "UPDATE_TOOL", nil, true),
    Ui.Keybind("<CR>", "INSTALL_TOOL", nil, true),
  })
end

---@class ToolchainUiState
local INITIAL_STATE = {
  view = {
    is_showing_help = false,
    is_searching = false,
  },
  header = {
    title_prefix = "",
  },
  tools = {
    ---@type ToolState[]
    all = {},
    ---@type boolean
    checking_statuses = false,
    ---@type table<integer, ToolState> Maps line number to tool
    line_to_tool = {},
  },
  log = {
    open = false,
    lines = {},
  },
}

local window = display.new_view_only_win("mogra.nvim", "mogra_toolchain")

local mutate_state, get_state = window.state(INITIAL_STATE)

-- Initiates per-tool status checks and updates each tool's `install_state`.
-- 
-- This triggers a non-blocking, sequential check of every tool in `state.tools.all`.
-- It sets `tools.checking_statuses` to `true` for the duration of the operation and
-- clears it when finished or when the window is closed. For each tool found, the
-- function updates `install_state` to `"installed"` or `"not_installed"` unless the
-- tool's current `install_state` is `"installing"`. If a tool is removed while
-- checking is in progress or the window closes, the process stops or skips that tool.
local function check_tool_statuses()
  local state = get_state()
  local tool_count = #state.tools.all

  if tool_count == 0 then
    return
  end

  -- Mark that we're checking statuses
  mutate_state(function(s)
    s.tools.checking_statuses = true
  end)

  -- Check tools one at a time asynchronously to avoid blocking
  local function check_tool(index)
    local current_state = get_state()

    if index > #current_state.tools.all then
      -- All tools checked
      mutate_state(function(s)
        s.tools.checking_statuses = false
      end)
      return
    end

    if not window.is_open() then
      mutate_state(function(s)
        s.tools.checking_statuses = false
      end)
      return
    end

    local tool = current_state.tools.all[index]
    if tool then
      -- Schedule the check to run async
      vim.defer_fn(function()
        -- Check if window is still open
        if not window.is_open() then
          mutate_state(function(s)
            s.tools.checking_statuses = false
          end)
          return
        end

        -- Get fresh state to ensure we have the latest tool reference
        local fresh_state = get_state()
        local fresh_tool = fresh_state.tools.all[index]
        if not fresh_tool then
          -- Tool was removed, skip to next
          vim.defer_fn(function()
            check_tool(index + 1)
          end, 0)
          return
        end

        -- Perform the check
        local is_installed = fresh_tool.is_installed()
        -- Update install_state if not currently installing
        if fresh_tool.install_state ~= "installing" then
          local new_state = is_installed and "installed" or "not_installed"
          -- Update through mutate_state to ensure UI re-renders
          mutate_state(function(s)
            -- Find the tool in the current state and update it
            if s.tools.all[index] then
              s.tools.all[index].install_state = new_state
            end
          end)
        end

        -- Check next tool after a small delay
        vim.defer_fn(function()
          check_tool(index + 1)
        end, 50) -- 50ms delay between checks
      end, 0)
    else
      -- Skip to next tool immediately if this one doesn't exist
      vim.defer_fn(function()
        check_tool(index + 1)
      end, 0)
    end
  end

  -- Start checking from the first tool
  vim.schedule(function()
    check_tool(1)
  end)
end

-- Initialize UI tool states from configured tools and begin background status checks.
-- 
-- Replaces the state's tools list with new ToolState instances created from settings.current.tools,
-- then triggers an asynchronous sweep to determine each tool's installation status.
local function setup_tools()
  mutate_state(function(s)
    -- Convert Tool objects to ToolState
    s.tools.all = {}
    for _, tool in ipairs(settings.current.tools) do
      table.insert(s.tools.all, ToolState.new(tool))
    end
  end)
  -- Start checking tool statuses
  check_tool_statuses()
end

-- Refresh tools periodically (when UI is open)
local refresh_timer = nil

-- Stops and closes the active refresh timer, if one exists.
-- If a timer is running, this function stops it, closes its resources, and clears the internal reference.
local function stop_refresh_timer()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

-- Starts a repeating 100ms refresh timer that forces UI re-renders (used for spinner animation)
-- and checks whether the configured tools list changed; if it did, reinitializes tools.
-- Does nothing if a refresh timer is already active. The timer is stopped automatically when the window closes.
local function start_refresh_timer()
  if refresh_timer then
    return
  end

  refresh_timer = vim.loop.new_timer()
  refresh_timer:start(100, 100, function() -- Changed to 100ms for smoother spinner animation
    vim.schedule(function()
      if not window.is_open() then
        stop_refresh_timer()
        return
      end

      -- Trigger re-render for spinner animation
      mutate_state(function(_) end)

      -- Check if tools list changed
      local current_state = get_state()
      if #current_state.tools.all ~= #settings.current.tools then
        setup_tools()
      end
    end)
  end)
end

-- Closes the toolchain UI window and releases associated resources (stops timers and frees the window).
local function close_window()
  window.close()
end

-- Get the ToolState corresponding to the current cursor line.
-- @return The ToolState at the cursor line, or `nil` if no tool is mapped to that line.
local function get_tool_at_cursor()
  local state = get_state()
  local cursor = window.get_cursor()
  local line = cursor[1]
  return state.tools.line_to_tool[line]
end

-- Installs the tool under the cursor, if present.
-- If no tool is under the cursor, no action is taken.
local function install_tool(_event)
  local tool = get_tool_at_cursor()
  if tool then
    tool:install(mutate_state)
  end
end

-- Initiates an update of the tool currently under the cursor in the tool list.
-- If a tool is selected, invokes its update routine; does nothing if no tool is at the cursor.
local function update_tool(_event)
  local tool = get_tool_at_cursor()
  if tool then
    tool:update(mutate_state)
  end
end

local effects = {
  ["CLOSE_WINDOW"] = close_window,
  ["INSTALL_TOOL"] = install_tool,
  ["UPDATE_TOOL"] = update_tool,
}

window.view(
  ---@param state ToolchainUiState
  function(state)
    return Ui.Node({
      GlobalKeybinds(state),
      Header(state),
      Ui.When(not state.view.is_showing_help, function()
        return Main(state)
      end),
    })
  end
)

-- Determine the UI border style from settings with a capability-based fallback.
-- @return The border style string from `settings.current.ui.border`, or `"rounded"` if Neovim supports `&winborder`, otherwise `"none"`.
local function get_border()
  local config = settings.current
  local border = config.ui.border
  if border == nil then
    border = vim.fn.exists("&winborder") == 1 and "rounded" or "none"
  end
  return border
end

window.init({
  effects = effects,
  border = get_border(),
  winhighlight = {
    "NormalFloat:MograToolchainNormal",
  },
})

return {
  window = window,
  set_view = function(_view)
    mutate_state(function(_)
      -- Handle view changes if needed
    end)
  end,
  set_sticky_cursor = function(tag)
    window.set_sticky_cursor(tag)
  end,
  close = function()
    stop_refresh_timer()
    window.close()
  end,
  open = function()
    window.open()
    -- Refresh tools list when opening
    setup_tools()
    -- Start refresh timer
    start_refresh_timer()
  end,
  mutate_state = mutate_state,
  get_state = get_state,
}