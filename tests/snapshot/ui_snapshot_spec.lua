-- Snapshot tests for mogra-toolchain UI
-- These tests capture the rendered output of UI components and compare against stored snapshots
--
-- To update snapshots: UPDATE_SNAPSHOTS=1 make test

local snapshot = require("helpers.snapshot")
local dummy_tools = require("fixtures.dummy_tools")
local display = require("mogra_toolchain.ui.core.display")
local Ui = require("mogra_toolchain.ui.core.ui")
local Header = require("mogra_toolchain.ui.components.header")
local Main = require("mogra_toolchain.ui.components.main")

-- Standard viewport context for consistent snapshots
local VIEWPORT = { win_width = 80 }

describe("UI Snapshots", function()
  before_each(function()
    dummy_tools.reset()
  end)

  describe("Header component", function()
    it("renders header correctly", function()
      local state = dummy_tools.get_empty_state()
      local view = Header(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("header", snapshot.capture(output))
    end)
  end)

  describe("Main component", function()
    it("renders empty state", function()
      local state = dummy_tools.get_empty_state()
      local view = Main(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("main_empty", snapshot.capture(output))
    end)

    it("renders tools in checking state", function()
      local state = dummy_tools.get_checking_state()
      local view = Main(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("main_checking", snapshot.capture(output))
    end)

    it("renders all tools installed", function()
      local state = dummy_tools.get_installed_state()
      local view = Main(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("main_installed", snapshot.capture(output))
    end)

    it("renders mixed installation states", function()
      local state = dummy_tools.get_mixed_state()
      local view = Main(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("main_mixed", snapshot.capture(output))
    end)

    it("renders installing tool with log output", function()
      local state = dummy_tools.get_installing_state()
      local view = Main(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("main_installing", snapshot.capture(output))
    end)

    it("renders installing tool with collapsed log", function()
      local state = dummy_tools.get_installing_collapsed_state()
      local view = Main(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("main_installing_collapsed", snapshot.capture(output))
    end)

    it("renders failed installation state", function()
      local state = dummy_tools.get_failed_state()
      local view = Main(state)
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("main_failed", snapshot.capture(output))
    end)
  end)

  describe("Full UI composition", function()
    it("renders complete UI with installed tools", function()
      local state = dummy_tools.get_installed_state()
      local view = Ui.Node({
        Header(state),
        Main(state),
      })
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("full_installed", snapshot.capture(output))
    end)

    it("renders complete UI with mixed states", function()
      local state = dummy_tools.get_mixed_state()
      local view = Ui.Node({
        Header(state),
        Main(state),
      })
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("full_mixed", snapshot.capture(output))
    end)

    it("renders complete UI with installing tool", function()
      local state = dummy_tools.get_installing_state()
      local view = Ui.Node({
        Header(state),
        Main(state),
      })
      local output = display._render_node(VIEWPORT, view)

      snapshot.assert_match("full_installing", snapshot.capture(output))
    end)
  end)
end)
