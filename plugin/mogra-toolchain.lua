local plugin = require("mogra-toolchain")
-- Create user commands
vim.api.nvim_create_user_command("Toolchain", function()
  plugin.open_ui()
end, { desc = "Open Mogra Tools UI" })

vim.api.nvim_create_user_command("ToolchainInstallAll", function()
  plugin.install_all()
end, { desc = "Install all tools" })

vim.api.nvim_create_user_command("ToolchainUpdateAll", function()
  plugin.update_all()
end, { desc = "Update all tools" })
