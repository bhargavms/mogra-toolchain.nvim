local logger = require("mogra_toolchain.ui.core.log")
local settings = require("mogra_toolchain.settings")
local ui = require("mogra_toolchain.ui")

-- Helper to get install command from tool
local function get_tool_install_cmd(tool)
  if tool.get_install_cmd then
    return tool.get_install_cmd()
  elseif tool.install_cmd then
    return tool.install_cmd
  end
  return nil
end

-- Helper to get update command from tool
local function get_tool_update_cmd(tool)
  if tool.get_update_cmd then
    return tool.get_update_cmd()
  elseif tool.update_cmd then
    return tool.update_cmd
  end
  return nil
end

-- Run a command asynchronously using vim.fn.jobstart
local function run_cmd_async(cmd, callback)
  if not cmd then
    if callback then
      callback(false)
    end
    return
  end

  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if callback then
        callback(exit_code == 0)
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
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
    run_cmd_async(item.cmd, function(success)
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
    run_cmd_async(item.cmd, function(success)
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
