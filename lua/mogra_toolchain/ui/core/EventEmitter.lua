local log = require("mogra_toolchain.ui.core.log")
---@class EventEmitter
---@field private __event_handlers table<any, table<fun(), fun()>>
---@field private __event_handlers_once table<any, table<fun(), fun()>>
local EventEmitter = {}
EventEmitter.__index = EventEmitter

-- Create a new EventEmitter instance with empty persistent and one-time handler registries.
-- @return The newly created EventEmitter instance.
function EventEmitter:new()
  local instance = {}
  setmetatable(instance, self)
  instance.__event_handlers = {}
  instance.__event_handlers_once = {}
  return instance
end

---@generic T
---@param obj T
-- Initialize a table as an EventEmitter instance.
-- Sets the EventEmitter metatable and prepares internal handler tables on the given object.
-- @param obj The table to initialize as an EventEmitter.
-- @return obj The same table now initialized as an EventEmitter.
function EventEmitter.init(obj)
  setmetatable(obj, EventEmitter)
  obj.__event_handlers = {}
  obj.__event_handlers_once = {}
  return obj
end

---@param event any
-- Invokes a handler with the provided arguments and logs a warning if the handler raises an error.
-- @param event any The event identifier associated with the handler (used in the log message).
-- @param handler fun(...): any The callback to invoke.
-- @param ... Arguments forwarded to the handler.
local function call_handler(event, handler, ...)
  local ok, err = pcall(handler, ...)
  if not ok then
    log.fmt_warn("EventEmitter handler failed for event %s with error %s", event, err)
  end
end

-- Emit an event to all registered handlers, including one-time handlers which are removed after invocation.
-- @param event The event key used to look up handlers.
-- @param ... Arguments forwarded to each handler.
-- @return The emitter instance (`self`) to allow method chaining.
function EventEmitter:emit(event, ...)
  if self.__event_handlers[event] then
    for handler in pairs(self.__event_handlers[event]) do
      call_handler(event, handler, ...)
    end
  end
  if self.__event_handlers_once[event] then
    local to_remove = {}
    for handler in pairs(self.__event_handlers_once[event]) do
      call_handler(event, handler, ...)
      to_remove[#to_remove + 1] = handler
    end
    for _, handler in ipairs(to_remove) do
      self.__event_handlers_once[event][handler] = nil
    end
  end
  return self
end

---@param event any
-- Registers a persistent handler for the specified event.
-- @param event The event identifier (used as lookup key for handlers).
-- @param handler Function invoked when the event is emitted; receives the emitted arguments.
-- @return The EventEmitter instance (`self`) for method chaining.
function EventEmitter:on(event, handler)
  if not self.__event_handlers[event] then
    self.__event_handlers[event] = {}
  end
  self.__event_handlers[event][handler] = handler
  return self
end

---@param event any
-- Registers a handler that will be invoked the next time `event` is emitted and then removed.
-- @param event The event key to listen for.
-- @param handler function(payload) Called with the emission arguments when the event occurs.
-- @return The EventEmitter instance (`self`).
function EventEmitter:once(event, handler)
  if not self.__event_handlers_once[event] then
    self.__event_handlers_once[event] = {}
  end
  self.__event_handlers_once[event][handler] = handler
  return self
end

---@param event any
-- Removes a previously registered handler for the given event from both persistent and one-time listener registries.
-- @param event The event key whose listener should be removed.
-- @param handler The handler function to remove.
-- @return The EventEmitter instance (self).
function EventEmitter:off(event, handler)
  if self.__event_handlers[event] then
    self.__event_handlers[event][handler] = nil
  end
  if self.__event_handlers_once[event] then
    self.__event_handlers_once[event][handler] = nil
  end
  return self
end

-- Clears all registered persistent and one-time event handlers on the instance.
-- After calling, no handlers will be invoked for any event until new handlers are registered.
-- @private
function EventEmitter:__clear_event_handlers()
  self.__event_handlers = {}
  self.__event_handlers_once = {}
end

return EventEmitter