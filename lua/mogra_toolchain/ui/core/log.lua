local settings = require("mogra_toolchain.settings")

-- Internal config (not user-facing)
local internal_config = {
  -- Name of the plugin. Prepended to log messages
  name = "mogra_toolchain",

  -- Should highlighting be used in console (using echohl)
  highlights = true,

  -- Level configuration
  modes = {
    { name = "trace", hl = "Comment", level = vim.log.levels.TRACE },
    { name = "debug", hl = "Comment", level = vim.log.levels.DEBUG },
    { name = "info", hl = "None", level = vim.log.levels.INFO },
    { name = "warn", hl = "WarningMsg", level = vim.log.levels.WARN },
    { name = "error", hl = "ErrorMsg", level = vim.log.levels.ERROR },
  },

  -- Can limit the number of decimals displayed for floats
  float_precision = 0.01,
}

-- Helper to get current log config (reads from settings at call time)
local function get_config()
  local log_settings = settings.current.log or {}
  return {
    name = internal_config.name,
    highlights = internal_config.highlights,
    modes = internal_config.modes,
    float_precision = internal_config.float_precision,
    level = (log_settings.level ~= nil) and log_settings.level or vim.log.levels.INFO,
    use_console = (log_settings.use_console ~= nil) and log_settings.use_console or false,
    use_file = (log_settings.use_file ~= nil) and log_settings.use_file or false,
  }
end

local log = {
  outfile = vim.fn.stdpath("log") .. "/mogra_toolchain.log",
}

-- Cached file handle for efficient logging
local log_file_handle = nil

-- Get or create the cached file handle
local function get_log_file_handle()
  if log_file_handle == nil then
    log_file_handle = io.open(log.outfile, "a")
    if log_file_handle then
      -- Close the handle when Neovim exits
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if log_file_handle then
            log_file_handle:close()
            log_file_handle = nil
          end
        end,
        once = true,
      })
    else
      -- Mark as attempted to avoid repeated open failures
      log_file_handle = false
      vim.schedule(function()
        vim.notify("mogra_toolchain: Failed to open log file: " .. log.outfile, vim.log.levels.WARN)
      end)
    end
  end
  return log_file_handle
end

-- selene: allow(incorrect_standard_library_use)
local unpack = unpack or table.unpack

do
  local round = function(x, increment)
    increment = increment or 1
    x = x / increment
    return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
  end

  local tbl_has_tostring = function(tbl)
    local mt = getmetatable(tbl)
    return mt and mt.__tostring ~= nil
  end

  local make_string = function(...)
    local config = get_config()
    local t = {}
    for i = 1, select("#", ...) do
      local x = select(i, ...)

      if type(x) == "number" and config.float_precision then
        x = tostring(round(x, config.float_precision))
      elseif type(x) == "table" and not tbl_has_tostring(x) then
        x = vim.inspect(x)
      else
        x = tostring(x)
      end

      t[#t + 1] = x
    end
    return table.concat(t, " ")
  end

  -- Map string level names to numeric vim.log.levels equivalents
  local level_name_to_num = {
    trace = vim.log.levels.TRACE,
    debug = vim.log.levels.DEBUG,
    info = vim.log.levels.INFO,
    warn = vim.log.levels.WARN,
    error = vim.log.levels.ERROR,
  }

  local function normalize_level(level)
    if type(level) == "number" then
      return level
    elseif type(level) == "string" then
      return level_name_to_num[level:lower()] or vim.log.levels.INFO
    else
      return vim.log.levels.INFO
    end
  end

  local log_at_level = function(level_config, message_maker, ...)
    local config = get_config()
    -- Ensure config.level is numeric before comparing
    local effective_level = normalize_level(config.level)
    -- Return early if we're below the configured log level threshold
    if level_config.level < effective_level then
      return
    end
    local nameupper = level_config.name:upper()

    local msg = message_maker(...)
    local info = debug.getinfo(3, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    if config.use_console then
      local log_to_console = function()
        local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date("%H:%M:%S"), lineinfo, msg)

        if config.highlights and level_config.hl then
          vim.cmd(string.format("echohl %s", level_config.hl))
        end

        local split_console = vim.split(console_string, "\n")
        for _, v in ipairs(split_console) do
          local formatted_msg = string.format("[%s] %s", config.name, vim.fn.escape(v, [["\]]))
          local ok = pcall(vim.cmd, string.format([[echom "%s"]], formatted_msg))
          if not ok then
            vim.api.nvim_out_write(formatted_msg .. "\n")
          end
        end

        if config.highlights and level_config.hl then
          vim.cmd("echohl NONE")
        end
      end
      if config.use_console == "sync" and not vim.in_fast_event() then
        log_to_console()
      else
        vim.schedule(log_to_console)
      end
    end

    -- Output to log file
    if config.use_file then
      local fp = get_log_file_handle()
      if fp then
        local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
        fp:write(str)
        fp:flush() -- Ensure log is written immediately
      end
    end
  end

  for _, x in ipairs(internal_config.modes) do
    log[x.name] = function(...)
      return log_at_level(x, make_string, ...)
    end

    log[("fmt_%s"):format(x.name)] = function(...)
      return log_at_level(x, function(...)
        local passed = { ... }
        local fmt = table.remove(passed, 1)
        local inspected = {}
        for _, v in ipairs(passed) do
          if type(v) == "table" then
            if tbl_has_tostring(v) then
              table.insert(inspected, v)
            else
              table.insert(inspected, vim.inspect(v))
            end
          else
            table.insert(inspected, tostring(v))
          end
        end
        return string.format(fmt, unpack(inspected))
      end, ...)
    end
  end
end

return log
