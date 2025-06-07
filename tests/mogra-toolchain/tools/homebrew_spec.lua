local homebrew_tool = require("mogra-toolchain.tools.homebrew")

describe("homebrew tool", function()
  local test_config = {
    name = "test-tool",
    description = "A test tool",
    package_name = "test-tool",
  }

  describe("create_homebrew_tool", function()
    it("should create a valid tool object", function()
      local tool = homebrew_tool.create_homebrew_tool(test_config)
      assert.equals("test-tool", tool.name)
      assert.equals("A test tool", tool.description)
      assert.is_function(tool.is_installed)
      assert.is_function(tool.install)
      assert.is_function(tool.update)
    end)

    it("should error on missing required fields", function()
      local invalid_config = {
        name = "test-tool",
        -- missing description and package_name
      }
      assert.has_error(function()
        homebrew_tool.create_homebrew_tool(invalid_config)
      end, "Missing required fields in HomebrewToolConfig")
    end)

    it("should error on missing package_name", function()
      local config = {
        name = "test-tool",
        description = "A test tool",
        -- missing package_name
      }

      assert.has_error(function()
        homebrew_tool.create_homebrew_tool(config)
      end, "Missing required fields in HomebrewToolConfig")
    end)
  end)

  describe("tool functions", function()
    local tool

    before_each(function()
      -- Mock vim.fn functions
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 1
        end
        return 0
      end

      -- Mock os.execute
      os.execute = function() -- luacheck: ignore
        return true
      end -- luacheck: ignore

      -- Mock vim.notify
      vim.notify = function() end -- luacheck: ignore

      tool = homebrew_tool.create_homebrew_tool(test_config)
    end)

    it("should check if tool is installed", function()
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 1
        end
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end
      assert.is_true(tool.is_installed())

      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 1
        end
        return 0
      end
      assert.is_false(tool.is_installed())
    end)

    it("should handle installation process", function()
      -- Mock successful installation
      os.execute = function(cmd) -- luacheck: ignore
        if cmd:match("brew install") then
          return true
        end
        return false
      end

      -- Mock executable check after installation
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 1
        end
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end

      assert.is_true(tool.install())
    end)

    it("should handle installation failures", function()
      -- Mock failed installation
      os.execute = function(cmd) -- luacheck: ignore
        if cmd:match("brew install") then
          return false
        end
        return true
      end

      assert.is_false(tool.install())
    end)

    it("should handle missing Homebrew", function()
      -- Mock Homebrew not installed
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 0
        end
        return 0
      end

      -- Should throw an error when Homebrew is not installed
      assert.has_error(function()
        tool.install()
      end, "Homebrew is not installed. Please install Homebrew first.")
    end)

    it("should run post-install hook if provided", function()
      local post_install_called = false
      local config = vim.deepcopy(test_config)
      config.post_install = function()
        post_install_called = true
        return true
      end

      -- Mock successful installation
      os.execute = function(cmd) -- luacheck: ignore
        if cmd:match("brew install") then
          return true
        end
        return false
      end

      -- Mock executable check after installation
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 1
        end
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end

      tool = homebrew_tool.create_homebrew_tool(config)
      tool.install()

      assert.is_true(post_install_called)
    end)

    it("should run post-update hook if provided", function()
      local post_update_called = false
      local config = vim.deepcopy(test_config)
      config.post_update = function()
        post_update_called = true
        return true
      end

      -- Mock successful update
      os.execute = function(cmd) -- luacheck: ignore
        if cmd:match("brew upgrade") then
          return true
        end
        return false
      end

      -- Mock executable check after update
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 1
        end
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end

      tool = homebrew_tool.create_homebrew_tool(config)
      tool.update()

      assert.is_true(post_update_called)
    end)
  end)
end)
