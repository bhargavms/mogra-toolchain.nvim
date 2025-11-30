local EventEmitter = require("mogra_toolchain.ui.core.EventEmitter")
local log = require("mogra_toolchain.ui.core.log")
local state = require("mogra_toolchain.ui.core.state")

-- Use settings module directly to avoid circular dependency
local settings = require("mogra_toolchain.settings")

local M = {}

---@generic T
---@param debounced_fn fun(arg1: T)
-- Creates a wrapper that coalesces rapid calls into a single future invocation.
-- The returned function accepts one argument; repeated calls before the scheduled
-- invocation replace the pending argument so only the most recent value is delivered.
-- @param debounced_fn Function to be invoked once with the latest argument.
-- @return A function that takes one argument and schedules a single call to `debounced_fn` with the last provided argument.
local function debounced(debounced_fn)
  local queued = false
  local last_arg = nil
  return function(a)
    last_arg = a
    if queued then
      return
    end
    queued = true
    vim.schedule(function()
      debounced_fn(last_arg)
      queued = false
      last_arg = nil
    end)
  end
end

---@param line string
-- Compute the indentation (in spaces) for a given line based on the active block styles and viewport width.
-- @param line The text of the line used to compute length for centering.
-- @param render_context Table with rendering context; expects `applied_block_styles` (array of style arrays) and `viewport_context.win_width` for CENTERED calculations.
-- @return A table with field `indentation` set to the number of leading spaces to apply. CENTERED overrides prior INDENT accumulations.
local function get_styles(line, render_context)
  local indentation = 0

  for i = 1, #render_context.applied_block_styles do
    local styles = render_context.applied_block_styles[i]
    for j = 1, #styles do
      local style = styles[j]
      if style == "INDENT" then
        indentation = indentation + 2
      elseif style == "CENTERED" then
        local padding = math.floor((render_context.viewport_context.win_width - #line) / 2)
        indentation = math.max(0, padding) -- CENTERED overrides any already applied indentation
      end
    end
  end

  return {
    indentation = indentation,
  }
end

---@param viewport_context ViewportContext
---@param node INode
---@param opt_render_context RenderContext?
-- Render an abstract UI node tree into a render output structure for buffer display.
-- Converts node types (VIRTUAL_TEXT, HL_TEXT, NODE, CASCADING_STYLE, KEYBIND_HANDLER, DIAGNOSTICS, STICKY_CURSOR)
-- into a cumulative RenderOutput containing lines, virtual texts, highlights, keybinds, diagnostics, and sticky cursor mappings.
-- @param viewport_context ViewportContext The current viewport metrics (e.g., width) used for styling decisions.
-- @param node table The node to render; expected to include a `type` field and type-specific fields (e.g., `lines`, `children`, `styles`, `virt_text`, `key`, `effect`, `diagnostic`, `id`).
-- @param opt_render_context RenderContext? Optional rendering context to carry viewport_context and a stack of applied block styles; if omitted a new context is created.
-- @param opt_output RenderOutput? Optional output accumulator to append results into; if omitted a new output object is created and returned.
-- @return RenderOutput The accumulated rendering result with fields:
--   - lines: array of buffer lines (strings).
--   - virt_texts: array of {line = number, content = table} for extmarks/virtual text.
--   - highlights: array of highlight entries {hl_group, line, col_start, col_end}.
--   - keybinds: array of keybind entries {line, key, effect, payload}.
--   - diagnostics: array of diagnostics {line, message, severity, source}.
--   - sticky_cursors: tables `line_map` (number -> id) and `id_map` (id -> number) mapping sticky cursor tags to lines.
local function render_node(viewport_context, node, opt_render_context, opt_output)
  ---@class RenderContext
  ---@field viewport_context ViewportContext
  ---@field applied_block_styles CascadingStyle[]
  local render_context = opt_render_context or {
    viewport_context = viewport_context,
    applied_block_styles = {},
  }
  ---@class RenderHighlight
  ---@field hl_group string
  ---@field line number
  ---@field col_start number
  ---@field col_end number

  ---@class RenderKeybind
  ---@field line number
  ---@field key string
  ---@field effect string
  ---@field payload any

  ---@class RenderDiagnostic
  ---@field line number
  ---@field diagnostic {message: string, severity: integer, source: string|nil}

  ---@class RenderOutput
  ---@field lines string[]: The buffer lines.
  ---@field virt_texts {line: integer, content: table}[]: List of tuples.
  ---@field highlights RenderHighlight[]
  ---@field keybinds RenderKeybind[]
  ---@field diagnostics RenderDiagnostic[]
  ---@field sticky_cursors { line_map: table<number, string>, id_map: table<string, number> }
  local output = opt_output or {
    lines = {},
    virt_texts = {},
    highlights = {},
    keybinds = {},
    diagnostics = {},
    sticky_cursors = { line_map = {}, id_map = {} },
  }

  if node.type == "VIRTUAL_TEXT" then
    output.virt_texts[#output.virt_texts + 1] = {
      line = #output.lines - 1,
      content = node.virt_text,
    }
  elseif node.type == "HL_TEXT" then
    for i = 1, #node.lines do
      local line = node.lines[i]
      local line_highlights = {}
      local full_line = ""
      for j = 1, #line do
        local span = line[j]
        local content, hl_group = span[1], span[2]
        local col_start = #full_line
        full_line = full_line .. content
        if hl_group ~= "" then
          line_highlights[#line_highlights + 1] = {
            hl_group = hl_group,
            line = #output.lines,
            col_start = col_start,
            col_end = col_start + #content,
          }
        end
      end

      -- only apply cascading styles to non-empty lines
      if string.len(full_line) > 0 then
        local active_styles = get_styles(full_line, render_context)
        full_line = (" "):rep(active_styles.indentation) .. full_line
        for j = 1, #line_highlights do
          local highlight = line_highlights[j]
          highlight.col_start = highlight.col_start + active_styles.indentation
          highlight.col_end = highlight.col_end + active_styles.indentation
          output.highlights[#output.highlights + 1] = highlight
        end
      end

      output.lines[#output.lines + 1] = full_line
    end
  elseif node.type == "NODE" or node.type == "CASCADING_STYLE" then
    if node.type == "CASCADING_STYLE" then
      render_context.applied_block_styles[#render_context.applied_block_styles + 1] = node.styles
    end
    for i = 1, #node.children do
      render_node(viewport_context, node.children[i], render_context, output)
    end
    if node.type == "CASCADING_STYLE" then
      render_context.applied_block_styles[#render_context.applied_block_styles] = nil
    end
  elseif node.type == "KEYBIND_HANDLER" then
    output.keybinds[#output.keybinds + 1] = {
      line = node.is_global and -1 or #output.lines,
      key = node.key,
      effect = node.effect,
      payload = node.payload,
    }
  elseif node.type == "DIAGNOSTICS" then
    output.diagnostics[#output.diagnostics + 1] = {
      line = #output.lines,
      message = node.diagnostic.message,
      severity = node.diagnostic.severity,
      source = node.diagnostic.source,
    }
  elseif node.type == "STICKY_CURSOR" then
    output.sticky_cursors.id_map[node.id] = #output.lines
    output.sticky_cursors.line_map[#output.lines] = node.id
  end

  return output
end

-- exported for tests
M._render_node = render_node

---@alias WindowOpts { effects?: table<string, fun()>, winhighlight?: string[], border?: string|table }

---@param size number
-- Compute an absolute dimension from a size specification and a viewport extent.
-- If `size` is greater than 1 it is treated as an absolute count and capped to `viewport`.
-- If `size` is between 0 and 1 (inclusive of 0, less than or equal to 1) it is treated as a fraction of `viewport`; the resulting value is floored.
-- @param size Number that is either an absolute size (>1) or a fraction of the viewport (0..1).
-- @param viewport Integer total available extent (rows or columns).
-- @return Integer resolved size constrained to the viewport.
local function calc_size(size, viewport)
  return size > 1 and math.min(size, viewport) or math.floor(size * viewport)
end

---@param opts WindowOpts
-- Compute a centered popup window layout (size and screen position) based on editor dimensions and current UI settings.
-- @param opts Table of window options; at minimum `opts.border` may influence centering adjustments.
-- @param sizes_only boolean If true, omit window decoration fields (e.g., `border`) from the returned layout.
-- @return table A window layout table containing `height`, `width`, `row`, `col`, `relative`, `style`, and `zindex`. Includes `border` when `sizes_only` is false.
local function create_popup_window_opts(opts, sizes_only)
  local lines = vim.o.lines - vim.o.cmdheight
  local columns = vim.o.columns
  local config = settings.current
  local height = calc_size(config.ui.height or 20, lines)
  local width = calc_size(config.ui.width or 60, columns)
  local row = math.floor((lines - height) / 2)
  local col = math.floor((columns - width) / 2)
  if opts.border ~= "none" and opts.border ~= "" then
    row = math.max(row - 1, 0)
    col = math.max(col - 1, 0)
  end

  local popup_layout = {
    height = height,
    width = width,
    row = row,
    col = col,
    relative = "editor",
    style = "minimal",
    zindex = 45,
  }

  if not sizes_only then
    popup_layout.border = opts.border
  end

  return popup_layout
end

-- Builds window options for a full-screen, non-focusable backdrop window that covers the entire editor.
-- @return A table of window options with fields:
--   - `relative`: `"editor"`
--   - `width`: current editor column count (`vim.o.columns`)
--   - `height`: current editor line count (`vim.o.lines`)
--   - `row`: `0`
--   - `col`: `0`
--   - `style`: `"minimal"`
--   - `focusable`: `false`
--   - `border`: `"none"`
--   - `zindex`: `44`
local function create_backdrop_window_opts()
  return {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    border = "none",
    zindex = 44,
  }
end

---@param name string Human readable identifier.
-- Create a view-only floating window instance with its own namespace, event surface, and rendering lifecycle.
-- Configures a dedicated buffer/window, diagnostics namespace, rendering loop, keybind/effect dispatching, and optional backdrop.
-- @param name The logical name used to create the window's namespace and identifiers.
-- @param filetype The buffer filetype to set for the view buffer.
-- @return table An instance with the following fields and methods:
--   - events: EventEmitter for subscribing to instance-level events.
--   - view(new_renderer): register a renderer function that maps state -> view.
--   - effects(new_effects): register effect handlers used by keybinds.
--   - state(initial_state): initialize a debounced state container; returns (mutate_state, get_state).
--   - init(opts): provide WindowOpts to configure window behaviour (must be called after view/state).
--   - open(): open the floating window (scheduled); asserts init was called.
--   - close(): close the window and teardown autocommands (scheduled); asserts init was called.
--   - set_cursor(pos): set the window cursor (row, col); asserts window is open.
--   - get_cursor(): get the current window cursor (row, col); asserts window is open.
--   - is_open(): boolean indicating whether the window is currently open.
--   - set_sticky_cursor(tag): attempt to set a sticky cursor by logical tag if present in the last render.
--   - get_win_config(): return the current window configuration; asserts window is open.
function M.new_view_only_win(name, filetype)
  local namespace = vim.api.nvim_create_namespace(("installer_%s"):format(name))
  local bufnr, backdrop_bufnr, renderer, mutate_state, get_state, unsubscribe
  local win_id, backdrop_win_id, window_mgmt_augroup, autoclose_augroup
  local registered_keymaps, registered_keybinds, registered_effect_handlers, sticky_cursor
  local has_initiated = false
  ---@type WindowOpts
  local window_opts = {}

  local events = EventEmitter:new()

  vim.diagnostic.config({
    virtual_text = {
      severity = { min = vim.diagnostic.severity.HINT, max = vim.diagnostic.severity.ERROR },
    },
    right_align = false,
    underline = false,
    signs = false,
    virtual_lines = false,
  }, namespace)

  -- Schedule closing of the view's floating window if it is currently valid.
  -- The actual close is deferred (scheduled) and will no-op when the window is already gone.
  local function close_window()
    -- We queue the win_buf to be deleted in a schedule call, otherwise when used with folke/which-key (and
    -- set timeoutlen=0) we run into a weird segfault.
    -- It should probably be unnecessary once https://github.com/neovim/neovim/issues/15548 is resolved
    vim.schedule(function()
      if win_id and vim.api.nvim_win_is_valid(win_id) then
        log.trace("Deleting window")
        vim.api.nvim_win_close(win_id, true)
      end
    end)
  end

  ---@param line number
  -- Invoke the registered effect handler associated with `key` for a specific line.
  -- @param line The line number whose keybinds should be checked.
  -- @param key The key identifier to match against registered keybinds.
  -- @return `true` if a matching effect handler was found and invoked, `false` otherwise.
  local function call_effect_handler(line, key)
    local line_keybinds = registered_keybinds[line]
    if line_keybinds then
      local keybind = line_keybinds[key]
      if keybind then
        local effect_handler = registered_effect_handlers[keybind.effect]
        if effect_handler then
          log.fmt_trace("Calling handler for effect %s on line %d for key %s", keybind.effect, line, key)
          effect_handler({ payload = keybind.payload })
          return true
        end
      end
    end
    return false
  end

  -- Invoke effect handlers bound to the current cursor line and global handlers for a given key.
  -- @param key The key identifier for the effect to dispatch; handlers registered for the current cursor line and for the global line (-1) will be invoked.
  local function dispatch_effect(key)
    local line = vim.api.nvim_win_get_cursor(0)[1]
    log.fmt_trace("Dispatching effect on line %d, key %s, bufnr %s", line, key, bufnr)
    call_effect_handler(line, key) -- line keybinds
    call_effect_handler(-1, key) -- global keybinds
  end

  local output
  local draw = function(view)
    local win_valid = win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
    local buf_valid = bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)

    if not win_valid or not buf_valid then
      -- the window has been closed or the buffer is somehow no longer valid
      unsubscribe(true)
      log.trace("Buffer or window is no longer valid", win_id, bufnr)
      return
    end

    local win_width = vim.api.nvim_win_get_width(win_id)
    ---@class ViewportContext
    local viewport_context = {
      win_width = win_width,
    }
    local cursor_pos_pre_render = vim.api.nvim_win_get_cursor(win_id)
    if output then
      sticky_cursor = output.sticky_cursors.line_map[cursor_pos_pre_render[1]]
    end

    output = render_node(viewport_context, view)
    local lines, virt_texts, highlights, keybinds, diagnostics = output.lines, output.virt_texts, output.highlights, output.keybinds, output.diagnostics

    -- set line contents
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false

    -- restore sticky cursor position
    if sticky_cursor then
      local new_sticky_cursor_line = output.sticky_cursors.id_map[sticky_cursor]
      if new_sticky_cursor_line and new_sticky_cursor_line ~= cursor_pos_pre_render[1] then
        vim.api.nvim_win_set_cursor(win_id, { new_sticky_cursor_line, cursor_pos_pre_render[2] })
      end
    end

    -- set virtual texts
    for i = 1, #virt_texts do
      local virt_text = virt_texts[i]
      vim.api.nvim_buf_set_extmark(bufnr, namespace, virt_text.line, 0, {
        virt_text = virt_text.content,
      })
    end

    -- set diagnostics
    vim.diagnostic.set(
      namespace,
      bufnr,
      vim.tbl_map(function(diagnostic)
        return {
          lnum = diagnostic.line - 1,
          col = 0,
          message = diagnostic.message,
          severity = diagnostic.severity,
          source = diagnostic.source,
        }
      end, diagnostics),
      {
        signs = false,
      }
    )

    -- set highlights
    for i = 1, #highlights do
      local highlight = highlights[i]
      vim.api.nvim_buf_add_highlight(bufnr, namespace, highlight.hl_group, highlight.line, highlight.col_start, highlight.col_end)
    end

    -- set keybinds
    registered_keybinds = {}
    for i = 1, #keybinds do
      local keybind = keybinds[i]
      if not registered_keybinds[keybind.line] then
        registered_keybinds[keybind.line] = {}
      end
      registered_keybinds[keybind.line][keybind.key] = keybind
      if not registered_keymaps[keybind.key] then
        registered_keymaps[keybind.key] = true
        vim.keymap.set("n", keybind.key, function()
          dispatch_effect(keybind.key)
        end, {
          buffer = bufnr,
          nowait = true,
          silent = true,
        })
      end
    end
  end

  -- Open the configured view-only floating window, optionally create a translucent backdrop, and install lifecycle autocommands.
  -- Initializes the buffer and window options, registers autocmds for resizing, command-line search events, automatic close behavior, and backdrop cleanup.
  -- @return The window id of the created floating window.
  local function open()
    bufnr = vim.api.nvim_create_buf(false, true)
    win_id = vim.api.nvim_open_win(bufnr, true, create_popup_window_opts(window_opts, false))

    local normal_hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = "Normal" })
    local is_nvim_transparent = normal_hl and normal_hl.bg == nil

    local backdrop = settings.current.ui.backdrop or 100
    if backdrop ~= 100 and vim.o.termguicolors and not is_nvim_transparent then
      backdrop_bufnr = vim.api.nvim_create_buf(false, true)
      backdrop_win_id = vim.api.nvim_open_win(backdrop_bufnr, false, create_backdrop_window_opts())

      vim.wo[backdrop_win_id].winhighlight = "Normal:MograToolchainBackdrop"
      vim.wo[backdrop_win_id].winblend = backdrop
      vim.bo[backdrop_bufnr].buftype = "nofile"
      -- https://github.com/folke/lazy.nvim/issues/1399
      vim.bo[backdrop_bufnr].filetype = "mogra_toolchain_backdrop"
      vim.bo[backdrop_bufnr].bufhidden = "wipe"
    end

    vim.api.nvim_create_autocmd("CmdLineEnter", {
      buffer = bufnr,
      callback = function()
        if vim.v.event.cmdtype == "/" or vim.v.event.cmdtype == "?" then
          events:emit("search:enter")
        end
      end,
    })

    vim.api.nvim_create_autocmd("CmdLineLeave", {
      buffer = bufnr,
      callback = function(_args)
        if vim.v.event.cmdtype == "/" or vim.v.event.cmdtype == "?" then
          events:emit("search:leave", vim.fn.getcmdline())
        end
      end,
    })

    registered_effect_handlers = window_opts.effects
    registered_keybinds = {}
    registered_keymaps = {}

    local buf_opts = {
      modifiable = false,
      swapfile = false,
      textwidth = 0,
      buftype = "nofile",
      bufhidden = "wipe",
      buflisted = false,
      filetype = filetype,
      undolevels = -1,
    }

    local win_opts = {
      number = false,
      relativenumber = false,
      wrap = false,
      spell = false,
      foldenable = false,
      signcolumn = "no",
      colorcolumn = "",
      cursorline = true,
    }

    -- window options
    for key, value in pairs(win_opts) do
      vim.wo[win_id][key] = value
    end

    if window_opts.winhighlight then
      vim.wo[win_id].winhighlight = table.concat(window_opts.winhighlight, ",")
    end

    -- buffer options
    for key, value in pairs(buf_opts) do
      vim.bo[bufnr][key] = value
    end

    vim.cmd([[ syntax clear ]])

    window_mgmt_augroup = vim.api.nvim_create_augroup("MograToolchainWindowMgmt", {})
    autoclose_augroup = vim.api.nvim_create_augroup("MograToolchainWindow", {})

    vim.api.nvim_create_autocmd({ "VimResized" }, {
      group = window_mgmt_augroup,
      buffer = bufnr,
      callback = function()
        if win_id and vim.api.nvim_win_is_valid(win_id) then
          draw(renderer(get_state()))
          vim.api.nvim_win_set_config(win_id, create_popup_window_opts(window_opts, true))
        end
        if backdrop_win_id and vim.api.nvim_win_is_valid(backdrop_win_id) then
          vim.api.nvim_win_set_config(backdrop_win_id, create_backdrop_window_opts())
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "WinClosed" }, {
      once = true,
      pattern = tostring(win_id),
      callback = function()
        if backdrop_win_id and vim.api.nvim_win_is_valid(backdrop_win_id) then
          vim.api.nvim_win_close(backdrop_win_id, true)
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "BufHidden", "BufUnload" }, {
      group = autoclose_augroup,
      buffer = bufnr,
      -- This is for instances where the window remains but the buffer is no longer visible, for example when
      -- loading another buffer into it (this is basically imitating 'winfixbuf', which was added in 0.10.0).
      callback = close_window,
    })

    -- This autocmd is responsible for closing the Mason window(s) when the user focuses another window. It
    -- essentially behaves as WinLeave except it keeps the Mason window(s) open under certain circumstances.
    local win_enter_aucmd
    win_enter_aucmd = vim.api.nvim_create_autocmd({ "WinEnter" }, {
      group = autoclose_augroup,
      pattern = "*",
      callback = function()
        local buftype = vim.bo[0].buftype
        -- This allows us to keep the floating window open for things like diagnostic popups, UI inputs á la dressing.nvim, etc.
        if buftype ~= "prompt" and buftype ~= "nofile" then
          close_window()
          vim.api.nvim_del_autocmd(win_enter_aucmd)
        end
      end,
    })

    return win_id
  end

  return {
    events = events,
    ---@param new_renderer fun(state: table): table
    view = function(new_renderer)
      renderer = new_renderer
    end,
    ---@param new_effects table<string, fun()>
    effects = function(new_effects)
      window_opts.effects = new_effects
    end,
    ---@generic T : table
    ---@param initial_state T
    ---@return fun(mutate_fn: fun(current_state: T)), fun(): T
    state = function(initial_state)
      mutate_state, get_state, unsubscribe = state.create_state_container(
        initial_state,
        debounced(function(new_state)
          draw(renderer(new_state))
        end)
      )

      -- we don't need to subscribe to state changes until the window is actually opened
      unsubscribe(true)

      return mutate_state, get_state
    end,
    ---@param opts WindowOpts
    init = function(opts)
      assert(renderer ~= nil, "No view function has been registered. Call .view() before .init().")
      assert(unsubscribe ~= nil, "No state has been registered. Call .state() before .init().")
      window_opts = opts
      has_initiated = true
    end,
    open = vim.schedule_wrap(function()
      log.trace("Opening window")
      assert(has_initiated, "Display has not been initiated, cannot open.")
      if win_id and vim.api.nvim_win_is_valid(win_id) then
        -- window is already open
        return
      end
      unsubscribe(false)
      open()
      draw(renderer(get_state()))
    end),
    ---@type fun()
    close = vim.schedule_wrap(function()
      assert(has_initiated, "Display has not been initiated, cannot close.")
      unsubscribe(true)
      log.fmt_trace("Closing window win_id=%s, bufnr=%s", win_id, bufnr)
      close_window()
      vim.api.nvim_del_augroup_by_id(window_mgmt_augroup)
      vim.api.nvim_del_augroup_by_id(autoclose_augroup)
    end),
    ---@param pos number[]: (row, col) tuple
    set_cursor = function(pos)
      assert(win_id ~= nil, "Window has not been opened, cannot set cursor.")
      return vim.api.nvim_win_set_cursor(win_id, pos)
    end,
    ---@return number[]: (row, col) tuple
    get_cursor = function()
      assert(win_id ~= nil, "Window has not been opened, cannot get cursor.")
      return vim.api.nvim_win_get_cursor(win_id)
    end,
    is_open = function()
      return win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
    end,
    ---@param tag any
    set_sticky_cursor = function(tag)
      if not win_id or not vim.api.nvim_win_is_valid(win_id) then
        return
      end
      if output then
        local new_sticky_cursor_line = output.sticky_cursors.id_map[tag]
        if new_sticky_cursor_line then
          sticky_cursor = tag
          local cursor = vim.api.nvim_win_get_cursor(win_id)
          vim.api.nvim_win_set_cursor(win_id, { new_sticky_cursor_line, cursor[2] })
        end
      end
    end,
    get_win_config = function()
      assert(win_id ~= nil, "Window has not been opened, cannot get config.")
      return vim.api.nvim_win_get_config(win_id)
    end,
  }
end

return M