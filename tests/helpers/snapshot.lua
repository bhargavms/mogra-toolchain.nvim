-- Snapshot testing utilities for mogra-toolchain UI
-- Usage:
--   local snapshot = require("helpers.snapshot")
--   snapshot.assert_match("my_snapshot", { lines = {...}, highlights = {...} })
--
-- To update snapshots, set UPDATE_SNAPSHOTS=1 environment variable
--
-- Snapshots are stored as JSON files in tests/snapshots/

-- luacheck: globals json

local M = {}

-- Get a JSON decoder function, with fallbacks for standalone mode
local function get_json_decoder()
  -- Prefer vim.json.decode if available
  if vim and vim.json and vim.json.decode then
    return vim.json.decode
  end

  -- Try cjson
  local ok, cjson = pcall(require, "cjson")
  if ok and cjson and cjson.decode then
    return cjson.decode
  end

  -- Try dkjson
  local ok2, dkjson = pcall(require, "dkjson")
  if ok2 and dkjson and dkjson.decode then
    return dkjson.decode
  end

  -- Try global json.decode
  ---@diagnostic disable-next-line: undefined-global
  if json and json.decode then
    ---@diagnostic disable-next-line: undefined-global
    return json.decode
  end

  return nil
end

-- Get the snapshots directory path
local function get_snapshots_dir()
  -- When running in Neovim, use vim.fn.getcwd()
  -- When running standalone, use debug.getinfo to find script path
  local cwd
  if vim and vim.fn and vim.fn.getcwd then
    cwd = vim.fn.getcwd()
  else
    local script_path = debug.getinfo(1, "S").source:sub(2)
    cwd = script_path:match("(.*/tests/)") or "./"
    cwd = cwd:gsub("/tests/$", "")
  end
  return cwd .. "/tests/snapshots"
end

-- Check if we should update snapshots
local function should_update()
  if vim and vim.env then
    return vim.env.UPDATE_SNAPSHOTS == "1"
  else
    return os.getenv("UPDATE_SNAPSHOTS") == "1"
  end
end

-- Deep equality check
local function deep_equal(a, b)
  if type(a) ~= type(b) then
    return false
  end

  if type(a) ~= "table" then
    return a == b
  end

  -- Check that a has all keys of b with same values
  for k, v in pairs(a) do
    if not deep_equal(v, b[k]) then
      return false
    end
  end

  -- Check that b doesn't have extra keys
  for k, _ in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

-- Generate a diff between two tables (for error messages)
local function generate_diff(expected, actual, path)
  path = path or ""
  local diffs = {}

  if type(expected) ~= type(actual) then
    table.insert(diffs, string.format("%s: type mismatch (expected %s, got %s)", path or "root", type(expected), type(actual)))
    return diffs
  end

  if type(expected) ~= "table" then
    if expected ~= actual then
      table.insert(diffs, string.format("%s: expected %q, got %q", path or "root", tostring(expected), tostring(actual)))
    end
    return diffs
  end

  -- Check for missing/extra keys
  for k, v in pairs(expected) do
    local new_path = path == "" and tostring(k) or (path .. "." .. tostring(k))
    if actual[k] == nil then
      table.insert(diffs, string.format("%s: missing in actual", new_path))
    else
      for _, d in ipairs(generate_diff(v, actual[k], new_path)) do
        table.insert(diffs, d)
      end
    end
  end

  for k, _ in pairs(actual) do
    local new_path = path == "" and tostring(k) or (path .. "." .. tostring(k))
    if expected[k] == nil then
      table.insert(diffs, string.format("%s: unexpected in actual", new_path))
    end
  end

  return diffs
end

-- Capture relevant data from RenderOutput for snapshot comparison
---@param render_output RenderOutput
---@return table
function M.capture(render_output)
  return {
    lines = render_output.lines,
    highlights = render_output.highlights,
  }
end

-- Get the path for a snapshot file
---@param name string
---@return string
function M.get_snapshot_path(name)
  return get_snapshots_dir() .. "/" .. name .. ".json"
end

-- Load a snapshot from JSON file
---@param name string
---@return table|nil, string|nil
function M.load(name)
  local path = M.get_snapshot_path(name)

  local file = io.open(path, "r")
  if not file then
    return nil, "Snapshot file not found: " .. path
  end

  local content = file:read("*all")
  file:close()

  -- Decode JSON
  local json_decode = get_json_decoder()
  if not json_decode then
    return nil, "No JSON decoder available (tried vim.json, cjson, dkjson, json)"
  end

  local ok, result = pcall(json_decode, content)
  if not ok then
    return nil, "Failed to parse JSON snapshot: " .. tostring(result)
  end

  return result
end

-- Pretty-print a Lua value as JSON with indentation
---@param value any
---@param indent number
---@return string
local function to_pretty_json(value, indent)
  indent = indent or 0
  local spaces = string.rep("  ", indent)
  local next_spaces = string.rep("  ", indent + 1)
  local t = type(value)

  if value == vim.NIL or value == nil then
    return "null"
  elseif t == "boolean" then
    return tostring(value)
  elseif t == "number" then
    return tostring(value)
  elseif t == "string" then
    -- Escape special characters for JSON
    local escaped = value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    return '"' .. escaped .. '"'
  elseif t == "table" then
    -- Check if it's an array (sequential integer keys starting from 1)
    local is_array = true
    local max_index = 0
    local count = 0
    for k, _ in pairs(value) do
      count = count + 1
      if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
        is_array = false
        break
      end
      max_index = math.max(max_index, k)
    end
    if is_array and max_index ~= count then
      is_array = false
    end

    local parts = {}

    if is_array then
      for _, v in ipairs(value) do
        local serialized = to_pretty_json(v, indent + 1)
        table.insert(parts, next_spaces .. serialized)
      end
      if #parts == 0 then
        return "[]"
      else
        return "[\n" .. table.concat(parts, ",\n") .. "\n" .. spaces .. "]"
      end
    else
      -- Sort keys for deterministic output
      local keys = {}
      for k in pairs(value) do
        table.insert(keys, k)
      end
      table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
      end)

      for _, k in ipairs(keys) do
        local v = value[k]
        local key_str = '"' .. tostring(k) .. '"'
        local serialized = to_pretty_json(v, indent + 1)
        table.insert(parts, next_spaces .. key_str .. ": " .. serialized)
      end
      if #parts == 0 then
        return "{}"
      else
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. spaces .. "}"
      end
    end
  else
    return '"' .. tostring(value) .. '"'
  end
end

-- Save a snapshot to JSON file
---@param name string
---@param data table
function M.save(name, data)
  local dir = get_snapshots_dir()

  -- Create directory if it doesn't exist
  if vim and vim.fn and vim.fn.mkdir then
    vim.fn.mkdir(dir, "p")
  else
    os.execute("mkdir -p '" .. dir:gsub("'", "'\\''") .. "'")
  end

  local path = M.get_snapshot_path(name)
  local pretty_json = to_pretty_json(data, 0)

  local file = io.open(path, "w")
  if not file then
    error("Failed to open snapshot file for writing: " .. path)
  end

  file:write(pretty_json)
  file:write("\n")
  file:close()
end

-- Assert that actual data matches the snapshot
-- If UPDATE_SNAPSHOTS=1, updates the snapshot instead of failing
---@param name string
---@param actual table
function M.assert_match(name, actual)
  if should_update() then
    M.save(name, actual)
    return true
  end

  local expected, err = M.load(name)
  if not expected then
    if err and err:find("not found") then
      -- Snapshot doesn't exist, create it
      M.save(name, actual)
      error(string.format("Snapshot '%s' did not exist. Created new snapshot. Run tests again to verify.", name))
    else
      error(string.format("Failed to load snapshot '%s': %s", name, tostring(err)))
    end
  end

  if not deep_equal(expected, actual) then
    local diffs = generate_diff(expected, actual)
    local diff_str = table.concat(diffs, "\n  ")
    error(string.format("Snapshot '%s' does not match.\n\nDifferences:\n  %s\n\nRun with UPDATE_SNAPSHOTS=1 to update.", name, diff_str))
  end

  return true
end

-- Utility to compare just the lines (ignoring highlights)
---@param name string
---@param lines string[]
function M.assert_lines_match(name, lines)
  return M.assert_match(name, { lines = lines })
end

return M
