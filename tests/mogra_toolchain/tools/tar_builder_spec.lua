local tar_tool = require("mogra_toolchain.tools.tar")

describe("tar tool builder", function()
  before_each(function()
    -- Mock vim.fn functions
    vim.fn.executable = function()
      return 0
    end -- luacheck: ignore
    vim.fn.tempname = function()
      return "/tmp/test"
    end -- luacheck: ignore
    vim.fn.mkdir = function() end -- luacheck: ignore
    vim.fn.stdpath = function(what) -- luacheck: ignore
      if what == "data" then
        return "/test/data"
      end
      return "/test"
    end

    -- Mock os.execute
    os.execute = function() -- luacheck: ignore
      return true
    end -- luacheck: ignore
  end)

  describe("builder pattern", function()
    it("should create a tool using builder pattern", function()
      local tool = tar_tool
        .tool("fd")
        :description("A simple, fast alternative to 'find'")
        :version("8.7.0")
        :url("https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-apple-darwin.tar.gz")
        :build()

      assert.equals("fd", tool.name)
      assert.equals("A simple, fast alternative to 'find'", tool.description)
      assert.is_function(tool.is_installed)
      assert.is_function(tool.install)
      assert.is_function(tool.update)
    end)

    it("should use default values for optional fields", function()
      local tool = tar_tool.tool("test-tool"):description("A test tool"):version("1.0.0"):url("https://example.com/test.tar.gz"):build()

      assert.equals("test-tool", tool.name)
      assert.equals("A test tool", tool.description)
    end)

    it("should allow setting custom install and executable directories", function()
      local tool = tar_tool
        .tool("custom-tool")
        :description("A custom tool")
        :version("1.0.0")
        :url("https://example.com/custom.tar.gz")
        :install_dir("/custom/install")
        :executable_dir("/custom/bin")
        :executable_name("custom-exec")
        :archive_name("custom-archive")
        :build()

      assert.equals("custom-tool", tool.name)
      assert.equals("A custom tool", tool.description)
    end)

    it("should allow setting post-install and post-update hooks", function()
      local post_install_called = false
      local post_update_called = false

      local tool = tar_tool
        .tool("hook-tool")
        :description("A tool with hooks")
        :version("1.0.0")
        :url("https://example.com/hook.tar.gz")
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
        if cmd == "hook-tool" then
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
        tar_tool.tool("incomplete-tool"):description("Missing version and url"):build()
      end, "Missing required fields: name, description, version, and url are required")
    end)

    it("should error on missing description", function()
      assert.has_error(function()
        tar_tool.tool("no-desc-tool"):version("1.0.0"):url("https://example.com/test.tar.gz"):build()
      end, "Missing required fields: name, description, version, and url are required")
    end)
  end)

  describe("method chaining", function()
    it("should return builder instance for method chaining", function()
      local builder = tar_tool.tool("chain-tool")

      assert.equals(builder, builder:description("Test description"))
      assert.equals(builder, builder:version("1.0.0"))
      assert.equals(builder, builder:url("https://example.com/test.tar.gz"))
      assert.equals(builder, builder:install_dir("/test/install"))
      assert.equals(builder, builder:executable_dir("/test/bin"))
      assert.equals(builder, builder:executable_name("chain-exec"))
      assert.equals(builder, builder:archive_name("chain-archive"))
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
end)
