local logger = require("mogra_toolchain.ui.core.log")
local settings = require("mogra_toolchain.settings")
local ui = require("mogra_toolchain.ui")
local command_runner = require("mogra_toolchain.ui.command_runner")

-- Helper to get install command from tool
local function get_tool_install_cmd(tool)
  if tool.get_install_cmd then
    local cmd, err = tool.get_install_cmd()
    if err then
      logger.error("Failed to get install command for " .. tool.name .. ": " .. err)
    end
    return cmd
  elseif tool.install_cmd then
    return tool.install_cmd
  end
  return nil
end

-- Helper to get update command from tool
local function get_tool_update_cmd(tool)
  if tool.get_update_cmd then
    local cmd, err = tool.get_update_cmd()
    if err then
      logger.error("Failed to get update command for " .. tool.name .. ": " .. err)
    end
    return cmd
  elseif tool.update_cmd then
    return tool.update_cmd
  end
  return nil
end

-- Install all tools (async, sequential)
local function install_all(callback)
  local tools_to_install = {}
  for _, tool in ipairs(settings.current.tools) do
    if not tool.is_installed() then
      local cmd = get_tool_install_cmd(tool)
      if cmd then
        table.insert(tools_to_install, { tool = tool, cmd = cmd })
      end
    end
  end

  local function install_next(index)
    if index > #tools_to_install then
      if callback then
        callback(true)
      end
      return
    end

    local item = tools_to_install[index]
    logger.info("Installing " .. item.tool.name .. "...")
    command_runner.run(item.cmd, nil, function(success)
      if success then
        logger.info("✓ Installed " .. item.tool.name)
      else
        logger.error("Failed to install " .. item.tool.name)
      end
      install_next(index + 1)
    end)
  end

  install_next(1)
end

-- Update all tools (async, sequential)
local function update_all(callback)
  local tools_to_update = {}
  for _, tool in ipairs(settings.current.tools) do
    if tool.is_installed() then
      local cmd = get_tool_update_cmd(tool)
      if cmd then
        table.insert(tools_to_update, { tool = tool, cmd = cmd })
      end
    end
  end

  local function update_next(index)
    if index > #tools_to_update then
      if callback then
        callback(true)
      end
      return
    end

    local item = tools_to_update[index]
    logger.info("Updating " .. item.tool.name .. "...")
    command_runner.run(item.cmd, nil, function(success)
      if success then
        logger.info("✓ Updated " .. item.tool.name)
      else
        logger.error("Failed to update " .. item.tool.name)
      end
      update_next(index + 1)
    end)
  end

  update_next(1)
end

vim.api.nvim_create_user_command("Mogra", function()
  ui.open()
end, { desc = "Open Mogra Tools UI" })

vim.api.nvim_create_user_command("MograInstallAll", function()
  install_all()
end, { desc = "Install all tools" })

vim.api.nvim_create_user_command("MograUpdateAll", function()
  update_all()
end, { desc = "Update all tools" })
