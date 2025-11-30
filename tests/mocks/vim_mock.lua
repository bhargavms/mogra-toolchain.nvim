-- Mock for vim global when running tests outside of Neovim
-- This provides a minimal implementation of vim APIs used by the plugin

local M = {}

-- Storage for mock state
M._state = {
  commands = {},
  autocmds = {},
  highlights = {},
  scheduled_fns = {},
  deferred_fns = {},
  timers = {},
  jobs = {},
  job_id_counter = 1,
}

-- Reset mock state between tests
function M.reset()
  M._state = {
    commands = {},
    autocmds = {},
    highlights = {},
    scheduled_fns = {},
    deferred_fns = {},
    timers = {},
    jobs = {},
    job_id_counter = 1,
  }
end

-- Create the vim mock table
function M.create_vim_mock()
  local mock = {}

  -- vim.log.levels
  mock.log = {
    levels = {
      TRACE = 0,
      DEBUG = 1,
      INFO = 2,
      WARN = 3,
      ERROR = 4,
    },
  }

  -- vim.fn
  mock.fn = {
    stdpath = function(what)
      if what == "log" then
        return "/tmp/nvim-test-logs"
      elseif what == "data" then
        return "/tmp/nvim-test-data"
      elseif what == "config" then
        return "/tmp/nvim-test-config"
      end
      return "/tmp/nvim-test"
    end,
    exists = function(_)
      return 0
    end,
    escape = function(str, _)
      return str
    end,
    getcwd = function()
      return "/tmp/test-cwd"
    end,
    jobstart = function(cmd, opts)
      local job_id = M._state.job_id_counter
      M._state.job_id_counter = M._state.job_id_counter + 1

      M._state.jobs[job_id] = {
        cmd = cmd,
        opts = opts,
        running = true,
      }

      -- Simulate async job completion
      if opts and opts.on_exit then
        table.insert(M._state.scheduled_fns, function()
          opts.on_exit(job_id, 0, "exit")
        end)
      end

      return job_id
    end,
    jobstop = function(job_id)
      if M._state.jobs[job_id] then
        M._state.jobs[job_id].running = false
      end
    end,
  }

  -- vim.api
  mock.api = {
    nvim_create_user_command = function(name, callback, opts)
      M._state.commands[name] = { callback = callback, opts = opts }
    end,
    nvim_create_autocmd = function(events, opts)
      local id = #M._state.autocmds + 1
      M._state.autocmds[id] = { events = events, opts = opts }
      return id
    end,
    nvim_del_autocmd = function(id)
      M._state.autocmds[id] = nil
    end,
    nvim_set_hl = function(ns, name, opts)
      M._state.highlights[name] = { ns = ns, opts = opts }
    end,
    nvim_out_write = function(_)
      -- No-op for tests
    end,
    nvim_create_namespace = function(_name)
      return 1
    end,
    nvim_buf_is_valid = function(_)
      return true
    end,
    nvim_win_is_valid = function(_)
      return true
    end,
    nvim_win_get_cursor = function(_)
      return { 1, 0 }
    end,
    nvim_win_set_cursor = function(_, _)
      -- No-op
    end,
    nvim_win_get_width = function(_)
      return 80
    end,
    nvim_buf_set_lines = function(_, _, _, _, _)
      -- No-op
    end,
    nvim_buf_clear_namespace = function(_, _, _, _)
      -- No-op
    end,
  }

  -- vim.schedule
  mock.schedule = function(fn)
    table.insert(M._state.scheduled_fns, fn)
  end

  -- vim.defer_fn
  mock.defer_fn = function(fn, delay)
    table.insert(M._state.deferred_fns, { fn = fn, delay = delay })
  end

  -- vim.schedule_wrap
  mock.schedule_wrap = function(fn)
    return function(...)
      local args = { ... }
      mock.schedule(function()
        fn(unpack(args))
      end)
    end
  end

  -- vim.in_fast_event
  mock.in_fast_event = function()
    return false
  end

  -- vim.cmd
  mock.cmd = function(_)
    -- No-op
  end

  -- vim.loop (libuv)
  mock.loop = {
    fs_stat = function(_)
      return nil
    end,
    new_timer = function()
      local timer = {
        _running = false,
        _callback = nil,
        start = function(self, _timeout, _interval, callback)
          self._running = true
          self._callback = callback
          table.insert(M._state.timers, self)
        end,
        stop = function(self)
          self._running = false
        end,
        close = function(self)
          self._running = false
          self._callback = nil
        end,
        is_active = function(self)
          return self._running
        end,
      }
      return timer
    end,
  }

  -- vim.deepcopy
  mock.deepcopy = function(tbl)
    if type(tbl) ~= "table" then
      return tbl
    end
    local copy = {}
    for k, v in pairs(tbl) do
      if type(v) == "table" then
        copy[k] = mock.deepcopy(v)
      else
        copy[k] = v
      end
    end
    -- Preserve metatable
    local mt = getmetatable(tbl)
    if mt then
      setmetatable(copy, mt)
    end
    return copy
  end

  -- vim.split
  mock.split = function(str, sep, opts)
    opts = opts or {}
    local result = {}
    local pattern = sep
    if not opts.plain then
      pattern = sep
    end

    local pos = 1
    while true do
      local start_pos, end_pos = string.find(str, pattern, pos, opts.plain)
      if not start_pos then
        table.insert(result, string.sub(str, pos))
        break
      end
      table.insert(result, string.sub(str, pos, start_pos - 1))
      pos = end_pos + 1
    end

    if opts.trimempty then
      while #result > 0 and result[1] == "" do
        table.remove(result, 1)
      end
      while #result > 0 and result[#result] == "" do
        table.remove(result)
      end
    end

    return result
  end

  -- vim.list_slice
  mock.list_slice = function(list, start_idx, end_idx)
    local result = {}
    end_idx = end_idx or #list
    for i = start_idx, end_idx do
      table.insert(result, list[i])
    end
    return result
  end

  -- vim.inspect
  mock.inspect = function(value)
    if type(value) == "table" then
      return "{...}"
    end
    return tostring(value)
  end

  -- vim.bo (buffer options)
  mock.bo = setmetatable({}, {
    __index = function(_, _)
      return {}
    end,
    __newindex = function(_, _, _)
      -- No-op
    end,
  })

  -- vim.opt
  mock.opt = {
    runtimepath = {
      prepend = function(_, _) end,
    },
    swapfile = false,
    termguicolors = true,
    hidden = true,
  }

  -- vim.diagnostic
  mock.diagnostic = {
    config = function(_) end,
    set = function(_, _, _, _) end,
    severity = {
      HINT = 1,
      INFO = 2,
      WARN = 3,
      ERROR = 4,
    },
  }

  -- vim.health
  mock.health = {
    start = function(_) end,
    ok = function(_) end,
    warn = function(_) end,
    error = function(_) end,
  }

  -- vim.notify
  mock.notify = function(_, _) end

  return mock
end

-- Helper to run scheduled functions (simulates vim.schedule execution)
function M.run_scheduled()
  local fns = M._state.scheduled_fns
  M._state.scheduled_fns = {}
  for _, fn in ipairs(fns) do
    fn()
  end
end

-- Helper to run deferred functions
function M.run_deferred()
  local fns = M._state.deferred_fns
  M._state.deferred_fns = {}
  for _, item in ipairs(fns) do
    item.fn()
  end
end

-- Helper to trigger timer callbacks
function M.tick_timers()
  for _, timer in ipairs(M._state.timers) do
    if timer._running and timer._callback then
      timer._callback()
    end
  end
end

-- Install the mock globally
function M.install()
  _G.vim = M.create_vim_mock()
end

-- Uninstall the mock
function M.uninstall()
  _G.vim = nil
end

return M
