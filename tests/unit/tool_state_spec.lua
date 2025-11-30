-- Unit tests for lua/mogra_toolchain/ui/tool_state.lua
local dummy_tools = require("dummy_tools")

describe("ToolState", function()
  local ToolState

  before_each(function()
    -- Reset dummy tools state
    dummy_tools.reset()
    -- Clear module cache to get fresh ToolState
    package.loaded["mogra_toolchain.ui.tool_state"] = nil
    ToolState = require("mogra_toolchain.ui.tool_state")
  end)

  describe("new", function()
    it("creates a new ToolState from tool config", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
        installed = false,
      })

      local state = ToolState.new(tool)

      assert.equals("test-tool", state.name)
      assert.equals("A test tool", state.description)
      assert.equals("checking", state.install_state)
      assert.is_function(state.is_installed)
    end)

    it("starts with log expanded by default", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })

      local state = ToolState.new(tool)

      assert.is_true(state.is_log_expanded)
    end)

    it("starts with empty tailed_output", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })

      local state = ToolState.new(tool)

      assert.equals("", state.tailed_output)
      assert.is_nil(state.short_tailed_output)
    end)

    it("preserves is_installed function", function()
      dummy_tools.set_installed("check-tool", true)
      local tool = dummy_tools.create_tool({
        name = "check-tool",
        description = "Tool to check",
        installed = true,
      })

      local state = ToolState.new(tool)

      assert.is_true(state.is_installed())
    end)

    it("preserves get_install_cmd function", function()
      local tool = dummy_tools.create_tool({
        name = "cmd-tool",
        description = "Tool with command",
      })

      local state = ToolState.new(tool)

      assert.is_function(state.get_install_cmd)
      local cmd = state.get_install_cmd()
      assert.is_string(cmd)
      assert.matches("Installing cmd%-tool", cmd)
    end)

    it("preserves get_update_cmd function", function()
      local tool = dummy_tools.create_tool({
        name = "update-tool",
        description = "Tool with update command",
      })

      local state = ToolState.new(tool)

      assert.is_function(state.get_update_cmd)
      local cmd = state.get_update_cmd()
      assert.is_string(cmd)
      assert.matches("Updating update%-tool", cmd)
    end)
  end)

  describe("toggle_log", function()
    it("toggles is_log_expanded from true to false", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)
      assert.is_true(state.is_log_expanded)

      state:toggle_log()

      assert.is_false(state.is_log_expanded)
    end)

    it("toggles is_log_expanded from false to true", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)
      state.is_log_expanded = false

      state:toggle_log()

      assert.is_true(state.is_log_expanded)
    end)

    it("can be toggled multiple times", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)
      local initial = state.is_log_expanded

      state:toggle_log()
      state:toggle_log()

      assert.equals(initial, state.is_log_expanded)
    end)
  end)

  describe("install_state transitions", function()
    it("starts in checking state", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })

      local state = ToolState.new(tool)

      assert.equals("checking", state.install_state)
    end)

    it("can be set to installed", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)

      state.install_state = "installed"

      assert.equals("installed", state.install_state)
    end)

    it("can be set to not_installed", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)

      state.install_state = "not_installed"

      assert.equals("not_installed", state.install_state)
    end)

    it("can be set to installing", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)

      state.install_state = "installing"

      assert.equals("installing", state.install_state)
    end)

    it("can be set to failed", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)

      state.install_state = "failed"

      assert.equals("failed", state.install_state)
    end)
  end)

  describe("tailed_output", function()
    it("can accumulate log lines", function()
      local tool = dummy_tools.create_tool({
        name = "test-tool",
        description = "A test tool",
      })
      local state = ToolState.new(tool)

      state.tailed_output = "line 1"
      state.tailed_output = state.tailed_output .. "\n" .. "line 2"
      state.tailed_output = state.tailed_output .. "\n" .. "line 3"

      assert.matches("line 1", state.tailed_output)
      assert.matches("line 2", state.tailed_output)
      assert.matches("line 3", state.tailed_output)
    end)
  end)
end)

describe("ToolState with multiple tools", function()
  local ToolState

  before_each(function()
    dummy_tools.reset()
    package.loaded["mogra_toolchain.ui.tool_state"] = nil
    ToolState = require("mogra_toolchain.ui.tool_state")
  end)

  it("creates independent states for different tools", function()
    local tools = dummy_tools.get_basic_tools()
    local states = {}

    for _, tool in ipairs(tools) do
      table.insert(states, ToolState.new(tool))
    end

    assert.equals(2, #states)
    assert.equals("tool-a", states[1].name)
    assert.equals("tool-b", states[2].name)

    -- Modifying one shouldn't affect the other
    states[1].install_state = "installed"
    states[2].install_state = "not_installed"

    assert.equals("installed", states[1].install_state)
    assert.equals("not_installed", states[2].install_state)
  end)

  it("toggling log on one tool doesn't affect others", function()
    local tools = dummy_tools.get_basic_tools()
    local states = {}

    for _, tool in ipairs(tools) do
      table.insert(states, ToolState.new(tool))
    end

    states[1]:toggle_log()

    assert.is_false(states[1].is_log_expanded)
    assert.is_true(states[2].is_log_expanded)
  end)
end)
