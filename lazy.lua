-- Example lazy.nvim configuration for mogra-toolchain
-- Place this in your lazy.nvim plugins configuration

local tar_tool = require("mogra-toolchain.tools.tar")
local homebrew_tool = require("mogra-toolchain.tools.homebrew")

return {
  "bhargavms/mogra-toolchain",
  name = "mogra-toolchain",
  lazy = false, -- Load immediately since it's a core development tool
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for async operations and utilities
  },
  keys = {
    { "<leader>tc", "<cmd>Toolchain<cr>", desc = "Open Toolchain UI" },
    { "<leader>ti", "<cmd>ToolchainInstallAll<cr>", desc = "Install All Tools" },
    { "<leader>tu", "<cmd>ToolchainUpdateAll<cr>", desc = "Update All Tools" },
  },
  opts = {
    ui = {
      title = "Development Toolchain",
      width = 80,
      height = 25,
      border = "rounded",
    },
    tools = {
      -- Essential command-line tools via Homebrew
      homebrew_tool.tool("ripgrep"):description("A fast search tool that respects .gitignore"):build(),

      homebrew_tool.tool("fd"):description("A simple, fast alternative to 'find'"):build(),

      homebrew_tool.tool("bat"):description("A cat clone with syntax highlighting"):build(),

      homebrew_tool.tool("jq"):description("Command-line JSON processor"):build(),

      homebrew_tool.tool("tree"):description("Display directories as trees"):build(),

      homebrew_tool
        .tool("fzf")
        :description("A command-line fuzzy finder")
        :post_install(function()
          -- Install fzf shell integration
          local fzf_install = vim.fn.expand("$(brew --prefix)/opt/fzf/install")
          if vim.fn.executable(fzf_install) == 1 then
            os.execute(fzf_install .. " --all")
          end
          return true
        end)
        :build(),

      -- Node.js with specific version
      homebrew_tool
        .tool("node")
        :description("JavaScript runtime environment")
        :package_name("node@18")
        :post_install(function()
          local version = vim.fn.system("node --version"):gsub("\n", "")
          vim.notify("Node.js installed: " .. version, vim.log.levels.INFO)
          return true
        end)
        :build(),

      -- Language servers and tools via tar (for platforms without package managers)
      tar_tool
        .tool("lua-language-server")
        :description("Lua Language Server for better Lua development")
        :version("3.7.4")
        :url("https://github.com/LuaLS/lua-language-server/releases/download/3.7.4/lua-language-server-3.7.4-darwin-x64.tar.gz")
        :executable_name("lua-language-server")
        :post_install(function()
          -- Make the binary executable
          local install_dir = vim.fn.stdpath("data") .. "/tools/lua-language-server"
          os.execute("chmod +x " .. install_dir .. "/bin/lua-language-server")
          vim.notify("Lua Language Server installed successfully!", vim.log.levels.INFO)
          return true
        end)
        :build(),

      -- Example of a tool with custom installation directory
      tar_tool
        .tool("stylua")
        :description("An opinionated Lua code formatter")
        :version("0.19.1")
        :url("https://github.com/JohnnyMorganz/StyLua/releases/download/v0.19.1/stylua-macos.zip")
        :install_dir(vim.fn.stdpath("data") .. "/formatters/stylua")
        :executable_dir(vim.fn.stdpath("data") .. "/bin")
        :executable_name("stylua")
        :post_install(function()
          -- Verify installation
          local stylua_path = vim.fn.stdpath("data") .. "/bin/stylua"
          if vim.fn.executable(stylua_path) == 1 then
            vim.notify("StyLua formatter installed successfully!", vim.log.levels.INFO)
            return true
          end
          return false
        end)
        :build(),
    },
  },
}
