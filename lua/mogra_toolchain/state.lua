local state = {
  win = nil,
  buf = nil,
  tools = {},
  selected = 1,
}

function state.get_current_tool()
  return state.tools[state.selected]
end

return state
