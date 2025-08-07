local plugin = require("mogra_toolchain")

describe("mogra_toolchain", function()
  before_each(function()
    -- Reset plugin to initial state
    plugin.config = {
      ui = {
        title = "Toolchain",
        width = 60,
        height = 20,
        border = "rounded",
      },
      tools = {},
    }
  end)

  describe("setup", function()
    it("should merge user options with defaults", function()
      local custom_config = {
        ui = {
          title = "Custom Title",
          width = 80,
        },
        tools = {},
      }

      plugin.setup(custom_config)
      assert.equals("Custom Title", plugin.config.ui.title)
      assert.equals(80, plugin.config.ui.width)
      assert.equals(20, plugin.config.ui.height) -- default value should be preserved
      assert.equals("rounded", plugin.config.ui.border) -- default value should be preserved
    end)

    it("should handle nil options", function()
      plugin.setup(nil)
      assert.equals("Toolchain", plugin.config.ui.title)
      assert.equals(60, plugin.config.ui.width)
      assert.equals(20, plugin.config.ui.height)
      assert.equals("rounded", plugin.config.ui.border)
    end)
  end)

  describe("tool registration", function()
    it("should register valid tools", function()
      local test_tool = {
        name = "test-tool",
        description = "A test tool",
        is_installed = function()
          return false
        end,
        install = function()
          return true
        end,
        update = function()
          return true
        end,
      }

      plugin.setup({ tools = { test_tool } })
      -- Note: We can't directly test the internal state, but we can verify the setup didn't error
      assert(true)
    end)

    it("should handle invalid tool objects", function()
      local invalid_tool = {
        name = "invalid-tool",
        -- missing required properties
      }

      -- Capture vim.notify output
      local notifications = {}
      vim.notify = function(msg, level)
        table.insert(notifications, { msg = msg, level = level })
      end

      plugin.setup({ tools = { invalid_tool } })

      -- Verify error notification was shown
      assert.equals(1, #notifications)
      assert.equals(vim.log.levels.ERROR, notifications[1].level)
      assert.is_true(string.find(notifications[1].msg, "missing required properties") ~= nil)
    end)
  end)

  describe("plugin metadata", function()
    it("should have correct metadata", function()
      assert.equals("mogra_toolchain", plugin.name)
      assert.equals("0.1.0", plugin.version)
      assert.equals("A Mason-like interface for managing development tools", plugin.description)
      assert.equals("Bhargav Mogra", plugin.author)
      assert.equals("MIT", plugin.license)
    end)
  end)

  describe("plugin functions", function()
    it("should have required functions", function()
      assert.is_function(plugin.open_ui)
      assert.is_function(plugin.install_all)
      assert.is_function(plugin.update_all)
    end)
  end)
end)
