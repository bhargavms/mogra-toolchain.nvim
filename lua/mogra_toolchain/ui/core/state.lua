local M = {}

---@generic T : table
---@param initial_state T
-- Create a state container that holds an isolated copy of `initial_state` and notifies `subscriber` after mutations.
-- @param initial_state table The initial state to deep-copy and store internally.
-- @param subscriber fun(state: table) Function called with the internal state after each mutation when not unsubscribed.
-- @return fun(mutate_fn: fun(current_state: table)) A mutator function that applies `mutate_fn` to the internal state and invokes `subscriber` if not unsubscribed.
-- @return fun() table A getter that returns the current internal state.
-- @return fun(val: boolean) A setter to mark the container as unsubscribed when called with `true` (prevents future subscriber notifications).
function M.create_state_container(initial_state, subscriber)
  -- we do deepcopy to make sure instances of state containers doesn't mutate the initial state
  local state = vim.deepcopy(initial_state)
  local has_unsubscribed = false

  ---@param mutate_fn fun(current_state: table)
  return function(mutate_fn)
    mutate_fn(state)
    if not has_unsubscribed then
      subscriber(state)
    end
  end, function()
    return state
  end, function(val)
    has_unsubscribed = val
  end
end

return M