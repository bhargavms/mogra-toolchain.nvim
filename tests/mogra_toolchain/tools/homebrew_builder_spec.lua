local homebrew_tool = require("mogra_toolchain.tools.homebrew")

describe("homebrew tool builder", function()
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
    end

    -- Mock vim.notify
    vim.notify = function() end -- luacheck: ignore
  end)

  describe("builder pattern", function()
    it("should create a tool using builder pattern", function()
      local tool = homebrew_tool.tool("ripgrep"):description("A fast search tool"):build()

      assert.equals("ripgrep", tool.name)
      assert.equals("A fast search tool", tool.description)
      assert.is_function(tool.is_installed)
      assert.is_function(tool.install)
      assert.is_function(tool.update)
    end)

    it("should use tool name as default package name", function()
      local tool = homebrew_tool.tool("fd"):description("A simple, fast alternative to 'find'"):build()

      assert.equals("fd", tool.name)
      assert.equals("A simple, fast alternative to 'find'", tool.description)
    end)

    it("should allow setting custom package name", function()
      local tool = homebrew_tool.tool("node"):description("JavaScript runtime"):package_name("node@18"):build()

      assert.equals("node", tool.name)
      assert.equals("JavaScript runtime", tool.description)
    end)

    it("should allow setting post-install and post-update hooks", function()
      local post_install_called = false
      local post_update_called = false

      local tool = homebrew_tool
        .tool("test-tool")
        :description("A test tool")
        :post_install(function()
          post_install_called = true
          return true
        end)
        :post_update(function()
          post_update_called = true
          return true
        end)
        :build()

      -- Mock successful installation
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "brew" then
          return 1
        end
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end

      tool.install()
      assert.is_true(post_install_called)
      assert.is_false(post_update_called)
    end)

    it("should error on missing required fields", function()
      assert.has_error(function()
        homebrew_tool.tool("incomplete-tool"):build()
      end, "Missing required fields: name and description are required")
    end)

    it("should error on missing description", function()
      assert.has_error(function()
        homebrew_tool.tool("no-desc-tool"):package_name("some-package"):build()
      end, "Missing required fields: name and description are required")
    end)
  end)

  describe("method chaining", function()
    it("should return builder instance for method chaining", function()
      local builder = homebrew_tool.tool("chain-tool")

      assert.equals(builder, builder:description("Test description"))
      assert.equals(builder, builder:package_name("custom-package"))
      assert.equals(
        builder,
        builder:post_install(function()
          return true
        end)
      )
      assert.equals(
        builder,
        builder:post_update(function()
          return true
        end)
      )
    end)
  end)

  describe("tool functionality", function()
    local tool

    before_each(function()
      tool = homebrew_tool.tool("test-tool"):description("A test tool"):package_name("test-package"):build()
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
  end)
end)
