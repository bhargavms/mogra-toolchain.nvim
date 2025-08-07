-- Example configuration demonstrating the new builder pattern API
local tar_tool = require("mogra_toolchain.tools.tar")
local homebrew_tool = require("mogra_toolchain.tools.homebrew")

return {
  ui = {
    title = "Development Toolchain",
    width = 80,
    height = 25,
    border = "rounded",
  },
  tools = {
    -- Tar-based installations with builder pattern
    tar_tool
      .tool("fd")
      :description("A simple, fast and user-friendly alternative to 'find'")
      :version("8.7.0")
      :url("https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-apple-darwin.tar.gz")
      :post_install(function()
        print("fd installed successfully!")
        return true
      end)
      :build(),

    tar_tool
      .tool("bat")
      :description("A cat clone with wings")
      :version("0.24.0")
      :url("https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-apple-darwin.tar.gz")
      :executable_name("bat")
      :build(),

    -- Homebrew-based installations with builder pattern
    homebrew_tool.tool("ripgrep"):description("A fast search tool"):build(), -- Uses "ripgrep" as package name by default

    homebrew_tool
      .tool("node")
      :description("JavaScript runtime")
      :package_name("node@18") -- Custom package name
      :post_install(function()
        print("Node.js installed! Version:", vim.fn.system("node --version"))
        return true
      end)
      :build(),

    homebrew_tool
      .tool("jq")
      :description("Command-line JSON processor")
      :post_install(function()
        -- Verify installation
        local version = vim.fn.system("jq --version")
        if version and version ~= "" then
          print("jq installed successfully:", version:gsub("\n", ""))
          return true
        end
        return false
      end)
      :build(),

    -- Minimal configuration - just name and description required
    homebrew_tool.tool("tree"):description("Display directories as trees"):build(),
  },
}
