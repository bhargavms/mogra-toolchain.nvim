local _ = require("mogra_toolchain.ui.core.functional")
local M = {}

---@alias NodeType
---| '"NODE"'
---| '"CASCADING_STYLE"'
---| '"VIRTUAL_TEXT"'
---| '"DIAGNOSTICS"'
---| '"HL_TEXT"'
---| '"KEYBIND_HANDLER"'
---| '"STICKY_CURSOR"'

---@alias INode Node | HlTextNode | CascadingStyleNode | VirtualTextNode | KeybindHandlerNode | DiagnosticsNode | StickyCursorNode

-- Creates a generic container node that holds child nodes.
-- @param children Array of child nodes to include in the container.
-- @return A Node table with `type = "NODE"` and `children` set to the provided array.
function M.Node(children)
  ---@class Node
  local node = {
    type = "NODE",
    children = children,
  }
  return node
end

-- Create an HlTextNode representing one or more lines of highlighted text.
-- @param lines_with_span_tuples Either:
--   - a list of lines, where each line is a list of span tuples `{ text, highlight }`, or
--   - a single-line list of span tuples (convenience form).
-- @return table HlTextNode with fields `type = "HL_TEXT"` and `lines` set to the provided (or normalized) lines structure.
function M.HlTextNode(lines_with_span_tuples)
  if type(lines_with_span_tuples[1]) == "string" then
    -- this enables a convenience API for just rendering a single line (with just a single span)
    lines_with_span_tuples = { { lines_with_span_tuples } }
  end
  ---@class HlTextNode
  local node = {
    type = "HL_TEXT",
    lines = lines_with_span_tuples,
  }
  return node
end

local create_unhighlighted_lines = function(lines)
  return _.map(function(line)
    return { { line, "" } }
  end, lines)
end

-- Create an HlTextNode from plain strings with no highlights.
-- @param lines List of lines to render; each string becomes one unhighlighted line.
-- @return HlTextNode whose lines are unhighlighted spans corresponding to the provided strings.
function M.Text(lines)
  return M.HlTextNode(create_unhighlighted_lines(lines))
end

---@alias CascadingStyle
---| '"INDENT"'
---| '"CENTERED"'

---@param styles CascadingStyle[]
-- Wraps a collection of child nodes with style flags that cascade to their descendants.
-- @param styles Table of style flags or attributes to apply to descendant nodes.
-- @param children Array of child nodes that the styles will apply to.
-- @return CascadingStyleNode A node containing the provided styles and children.
function M.CascadingStyleNode(styles, children)
  ---@class CascadingStyleNode
  local node = {
    type = "CASCADING_STYLE",
    styles = styles,
    children = children,
  }
  return node
end

-- Creates a virtual text node that holds inline text segments with per-segment highlights.
-- @param virt_text List of tuples `{text, highlight}` where `text` is a string and `highlight` is a highlight group name (may be an empty string).
-- @return A VirtualTextNode table with fields `type = "VIRTUAL_TEXT"` and `virt_text` set to the provided tuples.
function M.VirtualTextNode(virt_text)
  ---@class VirtualTextNode
  local node = {
    type = "VIRTUAL_TEXT",
    virt_text = virt_text,
  }
  return node
end

-- Create a diagnostics node that encapsulates a diagnostic object for rendering or processing.
-- @param diagnostic Table with diagnostic information. Fields:
--   message (string): diagnostic message text.
--   severity (integer): numeric severity level.
--   source (string, optional): optional source identifier.
-- @return DiagnosticsNode A node with `type = "DIAGNOSTICS"` and the provided `diagnostic` table.
function M.DiagnosticsNode(diagnostic)
  ---@class DiagnosticsNode
  local node = {
    type = "DIAGNOSTICS",
    diagnostic = diagnostic,
  }
  return node
end

---@param condition boolean
---@param node INode | fun(): INode
-- Resolve and return a UI node based on a condition.
-- @param condition Value checked for truthiness to decide which node to return.
-- @param node A node value or a zero-argument function (thunk) that returns a node; used when `condition` is truthy.
-- @param default_val Optional value returned when `condition` is falsy; if omitted, an empty `NODE` is returned.
-- @return The resolved node: `node` (or `node()` if `node` is a function) when `condition` is truthy, otherwise `default_val` or an empty `NODE`.
function M.When(condition, node, default_val)
  if condition then
    if type(node) == "function" then
      return node()
    else
      return node
    end
  end
  return default_val or M.Node({})
end

---@param key string The keymap to register to. Example: "<CR>".
---@param effect string The effect to call when keymap is triggered by the user.
---@param payload any The payload to pass to the effect handler when triggered.
-- Creates a keybind handler node that associates a key with an effect and optional payload.
-- @param key string The key sequence or key identifier to bind.
-- @param effect function|string The effect to invoke when the key is triggered; typically a callback function or an effect identifier.
-- @param payload any Optional payload passed to the effect when invoked.
-- @param is_global boolean? Whether the keybind applies to all lines in the buffer; defaults to `false`.
-- @return KeybindHandlerNode A node table with fields `type = "KEYBIND_HANDLER"`, `key`, `effect`, `payload`, and `is_global`.
function M.Keybind(key, effect, payload, is_global)
  ---@class KeybindHandlerNode
  local node = {
    type = "KEYBIND_HANDLER",
    key = key,
    effect = effect,
    payload = payload,
    is_global = is_global or false,
  }
  return node
end

-- Creates a node that represents a single empty (blank) line.
-- @return A node containing one unhighlighted empty string line.
function M.EmptyLine()
  return M.Text({ "" })
end

-- Build a right-padded table as a highlighted text node.
-- Pads each column so all entries in that column share the same display width and adds one space of separation.
-- @param rows string[][][] A list of rows; each row is a list of span tuples where each span is `{ text, highlight }`.
-- @return HlTextNode A highlighted-text node containing the table with padded column contents.
function M.Table(rows)
  local col_maxwidth = {}
  for i = 1, #rows do
    local row = rows[i]
    for j = 1, #row do
      local col = row[j]
      local content = col[1]
      col_maxwidth[j] = math.max(vim.api.nvim_strwidth(content), col_maxwidth[j] or 0)
    end
  end

  local new_rows = {}
  for i = 1, #rows do
    local row = rows[i]
    local new_row = {}
    for j = 1, #row do
      local col = row[j]
      local content = col[1]
      -- Shallow copy the column table with padded content
      local new_col = {}
      for k, v in pairs(col) do
        new_col[k] = v
      end
      new_col[1] = content .. string.rep(" ", col_maxwidth[j] - vim.api.nvim_strwidth(content) + 1) -- +1 for default minimum padding
      new_row[j] = new_col
    end
    new_rows[i] = new_row
  end

  return M.HlTextNode(new_rows)
end

-- Creates a sticky-cursor node that identifies a persistent cursor position by id.
-- @param opts Table of options.
-- @param opts.id Unique identifier for the sticky cursor; used to correlate and restore cursor position across renders.
-- @return StickyCursorNode A node with `type = "STICKY_CURSOR"` and the given `id`.
function M.StickyCursor(opts)
  ---@class StickyCursorNode
  local node = {
    type = "STICKY_CURSOR",
    id = opts.id,
  }
  return node
end

---Makes it possible to create stateful animations by progressing from the start of a range to the end.
---This is done in "ticks", in accordance with the provided options.
-- Creates a reusable tick-based animation starter configured by `opts`.
-- The returned starter, when invoked, runs `opts[1]` for each tick from `range[1]` to `range[2]` and returns a cancel function to stop the run.
-- @param opts Table configuring the animation. Required fields:
--   opts[1] (function): callback invoked each tick with the current tick (integer).
--   range (integer[2]): two-element array {start_tick, end_tick} defining the inclusive tick range.
--   delay_ms (integer): milliseconds between successive ticks.
--   start_delay_ms (integer|nil): optional delay before the first tick when a run starts.
--   iteration_delay_ms (integer|nil): optional delay between consecutive full-range iterations; if provided, a new run will start after this delay when a run completes.
-- @returns function: a `start_animation()` function. When called, it begins the animation run (unless already running) and returns a `cancel()` function that stops the animation and invalidates any pending callbacks.
function M.animation(opts)
  local animation_fn = opts[1]
  local start_tick, end_tick = opts.range[1], opts.range[2]
  local is_animating = false
  local epoch = 0 -- Start an animation run that advances the configured animation function across the specified tick range.
  -- The function sets `is_animating`, increments an internal epoch to ignore stale deferred callbacks, schedules per-tick invocations using `opts.delay_ms`, respects `opts.start_delay_ms` (default 0) for the initial start, and optionally restarts after `opts.iteration_delay_ms` when the range completes.
  -- @return A cancel function; when called it stops the animation and increments the epoch to invalidate any pending deferred callbacks.

  local function start_animation()
    if is_animating then
      return
    end
    local tick, start

    -- Increment epoch for this animation run; capture it for callbacks
    epoch = epoch + 1
    local current_epoch = epoch

    tick = function(current_tick)
      -- Bail out if this callback is from a stale epoch
      if current_epoch ~= epoch then
        return
      end
      animation_fn(current_tick)
      if current_tick < end_tick then
        vim.defer_fn(function()
          if current_epoch ~= epoch then
            return
          end
          tick(current_tick + 1)
        end, opts.delay_ms)
      else
        is_animating = false
        if opts.iteration_delay_ms then
          start(opts.iteration_delay_ms)
        end
      end
    end

    start = function(delay_ms)
      is_animating = true
      if delay_ms then
        vim.defer_fn(function()
          if current_epoch ~= epoch then
            return
          end
          tick(start_tick)
        end, delay_ms)
      else
        tick(start_tick)
      end
    end

    start(opts.start_delay_ms or 0)

    -- Stops the running animation and invalidates any pending deferred callbacks.
    -- Sets `is_animating` to false and increments `epoch` so stale deferred ticks are ignored.
    local function cancel()
      is_animating = false
      -- Increment epoch to invalidate all pending deferred callbacks
      epoch = epoch + 1
    end

    return cancel
  end

  return start_animation
end

return M