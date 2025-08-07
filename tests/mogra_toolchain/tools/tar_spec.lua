local tar_tool = require("mogra_toolchain.tools.tar")

describe("tar tool", function()
  local test_config = {
    name = "test-tool",
    description = "A test tool",
    version = "1.0.0",
    url = "https://example.com/test.tar.gz",
    install_dir = "/test/install",
    executable_dir = "/test/bin",
    executable_name = "test-tool",
    archive_name = "test-tool",
  }

  describe("create_tar_tool", function()
    it("should create a valid tool object", function()
      local tool = tar_tool.create_tar_tool(test_config)
      assert.equals("test-tool", tool.name)
      assert.equals("A test tool", tool.description)
      assert.is_function(tool.is_installed)
      assert.is_function(tool.install)
      assert.is_function(tool.update)
    end)

    it("should error on missing required fields", function()
      local invalid_config = {
        name = "test-tool",
        -- missing description, version, url, install_dir, executable_dir
      }
      assert.has_error(function()
        tar_tool.create_tar_tool(invalid_config)
      end, "Missing required fields in TarToolConfig")
    end)

    it("should use default values for optional fields", function()
      local config = vim.deepcopy(test_config)
      config.executable_name = nil
      config.archive_name = nil

      local tool = tar_tool.create_tar_tool(config)
      assert.equals("test-tool", tool.name)
      assert.equals("A test tool", tool.description)
    end)
  end)

  describe("tool functions", function()
    local tool

    before_each(function()
      -- Mock vim.fn functions
      vim.fn.executable = function()
        return 0
      end -- luacheck: ignore
      vim.fn.tempname = function()
        return "/tmp/test"
      end -- luacheck: ignore
      vim.fn.mkdir = function() end -- luacheck: ignore

      -- Mock os.execute
      os.execute = function() -- luacheck: ignore
        return true
      end -- luacheck: ignore

      tool = tar_tool.create_tar_tool(test_config)
    end)

    it("should check if tool is installed", function()
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end
      assert.is_true(tool.is_installed())

      vim.fn.executable = function()
        return 0
      end -- luacheck: ignore
      assert.is_false(tool.is_installed())
    end)

    it("should handle installation process", function()
      -- Mock successful installation
      os.execute = function(cmd) -- luacheck: ignore
        if cmd:match("curl") or cmd:match("tar") or cmd:match("ln") then
          return true
        end
        return false
      end

      -- Mock executable check after installation
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end

      assert.is_true(tool.install())
    end)

    it("should handle installation failures", function()
      -- Mock failed download
      os.execute = function(cmd) -- luacheck: ignore
        if cmd:match("curl") then
          return false
        end
        return true
      end

      assert.is_false(tool.install())
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
        if cmd:match("curl") or cmd:match("tar") or cmd:match("ln") then
          return true
        end
        return false
      end

      -- Mock executable check after installation
      vim.fn.executable = function(cmd) -- luacheck: ignore
        if cmd == "test-tool" then
          return 1
        end
        return 0
      end

      tool = tar_tool.create_tar_tool(config)
      tool.install()

      assert.is_true(post_install_called)
    end)
  end)
end)
