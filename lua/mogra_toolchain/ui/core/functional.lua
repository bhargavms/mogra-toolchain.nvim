-- Simplified functional utilities
local _ = {}

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

_.compose = function(...)
  local fns = { ... }
  return function(...)
    local result = ...
    for i = #fns, 1, -1 do
      result = fns[i](result)
    end
    return result
  end
end

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

_.keys = function(tbl)
  local result = {}
  for k in pairs(tbl) do
    table.insert(result, k)
  end
  return result
end

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
