-- Simplified functional utilities
-- NOTE: List helpers (map, filter, each) expect array-like tables (1..n, no holes).
-- They use ipairs, so non-numeric keys are ignored and iteration stops at the first nil.
local _ = {}

-- Lua 5.1/LuaJIT compatibility
local unpack = table.unpack or unpack

_.identity = function(x)
  return x
end

_.map = function(fn, list)
  local result = {}
  for i, v in ipairs(list) do
    result[i] = fn(v)
  end
  return result
end

_.filter = function(fn, list)
  local result = {}
  for _, v in ipairs(list) do
    if fn(v) then
      table.insert(result, v)
    end
  end
  return result
end

_.each = function(fn, list)
  for _, v in ipairs(list) do
    fn(v)
  end
end

-- Returns true if predicate returns truthy for any element in list.
_.any = function(fn, list)
  for _, v in ipairs(list) do
    if fn(v) then
      return true
    end
  end
  return false
end

-- Composes functions right-to-left, supporting multiple args/returns through the chain.
_.compose = function(...)
  local fns = { ... }
  return function(...)
    local result = { ... }
    for i = #fns, 1, -1 do
      result = { fns[i](unpack(result)) }
    end
    return unpack(result)
  end
end

-- Left-partial application: pre-fills the first N arguments of fn.
_.partial = function(fn, ...)
  local args = { ... }
  return function(...)
    local all_args = {}
    for _, v in ipairs(args) do
      table.insert(all_args, v)
    end
    for _, v in ipairs({ ... }) do
      table.insert(all_args, v)
    end
    return fn(unpack(all_args))
  end
end

_.prop = function(key)
  return function(obj)
    return obj[key]
  end
end

-- Returns all keys in tbl. Uses pairs(), so order is unspecified.
-- Sort the result at call sites if deterministic ordering is needed.
_.keys = function(tbl)
  local result = {}
  for k in pairs(tbl) do
    table.insert(result, k)
  end
  return result
end

-- Counts all keys (hash and array) via pairs(). This is "number of keys",
-- not "max numeric index". For array length, use #tbl instead.
_.size = function(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

_.T = function()
  return true
end
_.F = function()
  return false
end
_.always = function(x)
  return function()
    return x
  end
end

return _
