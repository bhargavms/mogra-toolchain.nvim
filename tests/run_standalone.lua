#!/usr/bin/env lua
-- Standalone test runner using vim mock
-- Run with: lua tests/run_standalone.lua

-- Add project root to package path
local script_path = debug.getinfo(1, "S").source:sub(2)
local tests_dir = script_path:match("(.*/)")
if not tests_dir then
  tests_dir = "./"
end
local project_root = tests_dir:gsub("tests/$", "")
if project_root == "" then
  project_root = "./"
end

package.path = project_root
  .. "lua/?.lua;"
  .. project_root
  .. "lua/?/init.lua;"
  .. tests_dir
  .. "?.lua;"
  .. tests_dir
  .. "?/init.lua;"
  .. tests_dir
  .. "mocks/?.lua;"
  .. tests_dir
  .. "fixtures/?.lua;"
  .. package.path

-- Install vim mock before loading any modules
local vim_mock = require("vim_mock")
vim_mock.install()

-- Simple test framework
local tests_passed = 0
local tests_failed = 0

local function describe(name, fn)
  print("\n" .. name)
  fn()
end

local function it(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("  ✓ " .. name)
    tests_passed = tests_passed + 1
  else
    print("  ✗ " .. name)
    print("    Error: " .. tostring(err))
    tests_failed = tests_failed + 1
  end
end

local function assert_equals(expected, actual)
  if expected ~= actual then
    error(string.format("Expected %s but got %s", tostring(expected), tostring(actual)))
  end
end

local function assert_true(value)
  if not value then
    error("Expected true but got " .. tostring(value))
  end
end

local function assert_false(value)
  if value then
    error("Expected false but got " .. tostring(value))
  end
end

local function assert_table(value)
  if type(value) ~= "table" then
    error("Expected table but got " .. type(value))
  end
end

-- Run tests
print("=== Mogra Toolchain Standalone Tests ===")

-- Test functional utilities
describe("functional utilities", function()
  local _ = require("mogra_toolchain.ui.core.functional")

  it("identity returns same value", function()
    assert_equals(5, _.identity(5))
    assert_equals("hello", _.identity("hello"))
  end)

  it("map transforms elements", function()
    local result = _.map(function(x)
      return x * 2
    end, { 1, 2, 3 })
    assert_equals(2, result[1])
    assert_equals(4, result[2])
    assert_equals(6, result[3])
  end)

  it("filter keeps matching elements", function()
    local result = _.filter(function(x)
      return x > 2
    end, { 1, 2, 3, 4, 5 })
    assert_equals(3, #result)
    assert_equals(3, result[1])
  end)

  it("any returns true if any match", function()
    assert_true(_.any(function(x)
      return x > 3
    end, { 1, 2, 3, 4, 5 }))
    assert_false(_.any(function(x)
      return x > 10
    end, { 1, 2, 3 }))
  end)

  it("compose works right to left", function()
    local add1 = function(x)
      return x + 1
    end
    local double = function(x)
      return x * 2
    end
    local composed = _.compose(add1, double)
    assert_equals(7, composed(3)) -- add1(double(3)) = add1(6) = 7
  end)

  it("partial pre-fills arguments", function()
    local add = function(a, b)
      return a + b
    end
    local add5 = _.partial(add, 5)
    assert_equals(8, add5(3))
  end)

  it("prop returns property accessor", function()
    local getName = _.prop("name")
    assert_equals("test", getName({ name = "test" }))
  end)

  it("keys returns all keys", function()
    local result = _.keys({ a = 1, b = 2 })
    assert_equals(2, #result)
  end)

  it("size counts keys", function()
    assert_equals(3, _.size({ a = 1, b = 2, c = 3 }))
  end)
end)

-- Test dummy tools
describe("dummy tools", function()
  local dummy_tools = require("dummy_tools")

  it("creates tool with correct properties", function()
    local tool = dummy_tools.create_tool({
      name = "test-tool",
      description = "A test tool",
    })

    assert_equals("test-tool", tool.name)
    assert_equals("A test tool", tool.description)
  end)

  it("tracks installation state", function()
    dummy_tools.reset()
    dummy_tools.set_installed("my-tool", true)

    local tool = dummy_tools.create_tool({
      name = "my-tool",
      description = "My tool",
      installed = true,
    })

    assert_true(tool.is_installed())
  end)

  it("generates install command", function()
    local tool = dummy_tools.create_tool({
      name = "cmd-tool",
      description = "Tool with command",
    })

    local cmd = tool.get_install_cmd()
    assert_true(cmd:find("Installing") ~= nil)
  end)
end)

-- Test ToolState
describe("ToolState", function()
  local dummy_tools = require("dummy_tools")
  dummy_tools.reset()

  local ToolState = require("mogra_toolchain.ui.tool_state")

  it("creates state from tool", function()
    local tool = dummy_tools.create_tool({
      name = "test",
      description = "Test tool",
    })

    local state = ToolState.new(tool)

    assert_equals("test", state.name)
    assert_equals("Test tool", state.description)
    assert_equals("checking", state.install_state)
  end)

  it("starts with log expanded", function()
    local tool = dummy_tools.create_tool({
      name = "test",
      description = "Test tool",
    })

    local state = ToolState.new(tool)

    assert_true(state.is_log_expanded)
  end)

  it("toggles log state", function()
    local tool = dummy_tools.create_tool({
      name = "test",
      description = "Test tool",
    })

    local state = ToolState.new(tool)
    assert_true(state.is_log_expanded)

    state:toggle_log()
    assert_false(state.is_log_expanded)

    state:toggle_log()
    assert_true(state.is_log_expanded)
  end)
end)

-- Test settings
describe("settings", function()
  local settings = require("mogra_toolchain.settings")

  it("has default tools as empty", function()
    assert_table(settings.current.tools)
    assert_equals(0, #settings.current.tools)
  end)

  it("has log settings", function()
    assert_table(settings.current.log)
  end)

  it("has ui settings", function()
    assert_table(settings.current.ui)
  end)
end)

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Passed: %d", tests_passed))
print(string.format("Failed: %d", tests_failed))

if tests_failed > 0 then
  os.exit(1)
else
  print("\nAll tests passed!")
  os.exit(0)
end
