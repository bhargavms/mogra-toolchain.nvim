-- Integration tests for mogra-toolchain plugin
local dummy_tools = require("dummy_tools")

describe("mogra_toolchain", function()
  local mogra_toolchain
  local settings

  before_each(function()
    -- Reset state
    dummy_tools.reset()

    -- Clear cached modules
    package.loaded["mogra_toolchain"] = nil
    package.loaded["mogra_toolchain.settings"] = nil
    package.loaded["mogra_toolchain.ui.tool_state"] = nil

    -- Load fresh modules
    settings = require("mogra_toolchain.settings")
    mogra_toolchain = require("mogra_toolchain")
  end)

  describe("setup", function()
    it("sets has_setup to true after setup", function()
      assert.is_false(mogra_toolchain.has_setup)

      mogra_toolchain.setup({
        tools = dummy_tools.get_basic_tools(),
      })

      assert.is_true(mogra_toolchain.has_setup)
    end)

    it("stores tools in settings", function()
      local tools = dummy_tools.get_basic_tools()

      mogra_toolchain.setup({
        tools = tools,
      })

      assert.equals(2, #settings.current.tools)
      assert.equals("tool-a", settings.current.tools[1].name)
      assert.equals("tool-b", settings.current.tools[2].name)
    end)

    it("can be called without options", function()
      assert.has_no.errors(function()
        mogra_toolchain.setup()
      end)
    end)

    it("merges options with defaults", function()
      mogra_toolchain.setup({
        tools = dummy_tools.get_basic_tools(),
        ui = {
          border = "rounded",
        },
      })

      assert.equals("rounded", settings.current.ui.border)
    end)
  end)

  describe("config proxy", function()
    it("provides access to config via M.config", function()
      mogra_toolchain.setup({
        tools = dummy_tools.get_basic_tools(),
      })

      assert.equals(2, #mogra_toolchain.config.tools)
    end)

    it("reflects current settings", function()
      mogra_toolchain.setup({
        tools = {},
      })

      assert.equals(0, #mogra_toolchain.config.tools)

      -- Modify settings directly
      settings.current.tools = dummy_tools.get_basic_tools()

      -- Config should reflect the change
      assert.equals(2, #mogra_toolchain.config.tools)
    end)
  end)

  describe("module metadata", function()
    it("has correct name", function()
      assert.equals("mogra_toolchain", mogra_toolchain.name)
    end)

    it("has version string", function()
      assert.is_string(mogra_toolchain.version)
      assert.matches("%d+%.%d+%.%d+", mogra_toolchain.version)
    end)

    it("has description", function()
      assert.is_string(mogra_toolchain.description)
    end)

    it("has author", function()
      assert.is_string(mogra_toolchain.author)
    end)

    it("has license", function()
      assert.equals("MIT", mogra_toolchain.license)
    end)
  end)
end)

describe("settings", function()
  local settings

  before_each(function()
    package.loaded["mogra_toolchain.settings"] = nil
    settings = require("mogra_toolchain.settings")
  end)

  describe("defaults", function()
    it("has empty tools list by default", function()
      assert.same({}, settings.current.tools)
    end)

    it("has log settings", function()
      assert.is_table(settings.current.log)
    end)

    it("has ui settings", function()
      assert.is_table(settings.current.ui)
    end)
  end)

  describe("setup", function()
    it("merges tools", function()
      local tools = dummy_tools.get_basic_tools()

      settings.setup({ tools = tools })

      assert.equals(2, #settings.current.tools)
    end)

    it("preserves defaults for unspecified options", function()
      settings.setup({ tools = {} })

      assert.is_table(settings.current.log)
      assert.is_table(settings.current.ui)
    end)

    it("allows overriding log level", function()
      settings.setup({
        log = {
          level = vim.log.levels.DEBUG,
        },
      })

      assert.equals(vim.log.levels.DEBUG, settings.current.log.level)
    end)
  end)
end)

describe("ToolState integration", function()
  local ToolState
  local settings

  before_each(function()
    dummy_tools.reset()
    package.loaded["mogra_toolchain.settings"] = nil
    package.loaded["mogra_toolchain.ui.tool_state"] = nil

    settings = require("mogra_toolchain.settings")
    ToolState = require("mogra_toolchain.ui.tool_state")
  end)

  it("creates ToolState from configured tools", function()
    local tools = dummy_tools.get_basic_tools()
    settings.setup({ tools = tools })

    local states = {}
    for _, tool in ipairs(settings.current.tools) do
      table.insert(states, ToolState.new(tool))
    end

    assert.equals(2, #states)
    assert.equals("tool-a", states[1].name)
    assert.equals("tool-b", states[2].name)
  end)

  it("reflects correct is_installed state", function()
    dummy_tools.set_installed("tool-a", true)
    dummy_tools.set_installed("tool-b", false)

    local tools = dummy_tools.get_basic_tools()
    settings.setup({ tools = tools })

    local states = {}
    for _, tool in ipairs(settings.current.tools) do
      table.insert(states, ToolState.new(tool))
    end

    assert.is_true(states[1].is_installed())
    assert.is_false(states[2].is_installed())
  end)
end)

describe("functional utilities integration", function()
  local _
  local ToolState
  local settings

  before_each(function()
    dummy_tools.reset()
    package.loaded["mogra_toolchain.ui.core.functional"] = nil
    package.loaded["mogra_toolchain.settings"] = nil
    package.loaded["mogra_toolchain.ui.tool_state"] = nil

    _ = require("mogra_toolchain.ui.core.functional")
    settings = require("mogra_toolchain.settings")
    ToolState = require("mogra_toolchain.ui.tool_state")
  end)

  it("can map tools to ToolStates using _.map", function()
    local tools = dummy_tools.get_basic_tools()
    settings.setup({ tools = tools })

    local states = _.map(ToolState.new, settings.current.tools)

    assert.equals(2, #states)
    assert.equals("tool-a", states[1].name)
    assert.equals("tool-b", states[2].name)
  end)

  it("can filter tools using _.filter", function()
    dummy_tools.set_installed("tool-a", true)
    dummy_tools.set_installed("tool-b", false)

    local tools = dummy_tools.get_basic_tools()
    settings.setup({ tools = tools })

    local states = _.map(ToolState.new, settings.current.tools)

    -- Manually set states to match is_installed
    states[1].install_state = "installed"
    states[2].install_state = "not_installed"

    local installed = _.filter(function(s)
      return s.install_state == "installed"
    end, states)

    assert.equals(1, #installed)
    assert.equals("tool-a", installed[1].name)
  end)

  it("can check if any tool is installing using _.any", function()
    local tools = dummy_tools.get_basic_tools()
    settings.setup({ tools = tools })

    local states = _.map(ToolState.new, settings.current.tools)

    -- Initially none are installing
    assert.is_false(_.any(function(s)
      return s.install_state == "installing"
    end, states))

    -- Set one to installing
    states[1].install_state = "installing"

    assert.is_true(_.any(function(s)
      return s.install_state == "installing"
    end, states))
  end)
end)

describe("EventEmitter", function()
  local EventEmitter

  before_each(function()
    package.loaded["mogra_toolchain.ui.core.EventEmitter"] = nil
    EventEmitter = require("mogra_toolchain.ui.core.EventEmitter")
  end)

  it("creates new instance", function()
    local emitter = EventEmitter:new()
    assert.is_table(emitter)
  end)

  it("emits and receives events", function()
    local emitter = EventEmitter:new()
    local received = nil

    emitter:on("test", function(data)
      received = data
    end)

    emitter:emit("test", "hello")

    assert.equals("hello", received)
  end)

  it("handles once listeners", function()
    local emitter = EventEmitter:new()
    local call_count = 0

    emitter:once("test", function()
      call_count = call_count + 1
    end)

    emitter:emit("test")
    emitter:emit("test")

    assert.equals(1, call_count)
  end)

  it("handles multiple listeners", function()
    local emitter = EventEmitter:new()
    local results = {}

    emitter:on("test", function()
      table.insert(results, "a")
    end)

    emitter:on("test", function()
      table.insert(results, "b")
    end)

    emitter:emit("test")

    assert.equals(2, #results)
  end)
end)

describe("state container", function()
  local state_module

  before_each(function()
    package.loaded["mogra_toolchain.ui.core.state"] = nil
    state_module = require("mogra_toolchain.ui.core.state")
  end)

  it("creates state container with initial state", function()
    local updates = {}
    local _, get = state_module.create_state_container({ count = 0 }, function(s)
      table.insert(updates, vim.deepcopy(s))
    end)

    assert.equals(0, get().count)
  end)

  it("mutates state and notifies subscriber", function()
    local updates = {}
    local mutate, get = state_module.create_state_container({ count = 0 }, function(s)
      table.insert(updates, vim.deepcopy(s))
    end)

    mutate(function(s)
      s.count = s.count + 1
    end)

    assert.equals(1, get().count)
    assert.equals(1, #updates)
    assert.equals(1, updates[1].count)
  end)

  it("preserves state between mutations", function()
    local mutate, get = state_module.create_state_container({ a = 1, b = 2 }, function() end)

    mutate(function(s)
      s.a = 10
    end)

    assert.equals(10, get().a)
    assert.equals(2, get().b)
  end)

  it("can unsubscribe from updates", function()
    local update_count = 0
    local mutate, get, unsubscribe = state_module.create_state_container({ count = 0 }, function()
      update_count = update_count + 1
    end)

    mutate(function(s)
      s.count = 1
    end)
    assert.equals(1, update_count)

    unsubscribe(true)

    mutate(function(s)
      s.count = 2
    end)
    assert.equals(1, update_count) -- Should not increase

    assert.equals(2, get().count) -- But state should still update
  end)
end)
