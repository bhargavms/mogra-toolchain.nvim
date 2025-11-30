local logger = require("mogra_toolchain.ui.core.log")
local settings = require("mogra_toolchain.settings")
local ui = require("mogra_toolchain.ui")

-- Retrieve a tool's install command.
-- @param tool Table representing a tool; may provide a `get_install_cmd()` function or an `install_cmd` field.
-- @return The install command string if present, `nil` otherwise.
local function get_tool_install_cmd(tool)
  if tool.get_install_cmd then
    return tool.get_install_cmd()
  elseif tool.install_cmd then
    return tool.install_cmd
  end
  return nil
end

-- Retrieve a tool's update command.
-- Checks for a `get_update_cmd()` method first, then an `update_cmd` field.
-- @param tool Table representing a tool; may provide `get_update_cmd()` or `update_cmd`.
-- @return The update command string if available, `nil` otherwise.
local function get_tool_update_cmd(tool)
  if tool.get_update_cmd then
    return tool.get_update_cmd()
  elseif tool.update_cmd then
    return tool.update_cmd
  end
  return nil
end

-- Execute a shell command asynchronously and invoke a completion callback with the command's success status.
-- If `cmd` is nil the callback (if provided) is invoked immediately with `false`.
-- @param cmd Command to run (string or list compatible with `vim.fn.jobstart`).
-- @param callback Optional function called with `true` if the process exited with code 0, `false` otherwise.
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

-- Sequentially installs all tools that are not currently installed.
-- For each tool in `settings.current.tools` that reports not installed and provides an install command,
-- runs its install command and logs success or failure per tool.
-- When all queued installs have finished, invokes `callback(true)` if a callback is provided.
-- @param callback Optional. Function called after all installations complete; receives `true`.
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

  -- Advance the sequential installation queue by processing the tool at the given 1-based index.
  -- Processes the tool's install command, logs success or failure, then continues with the next item.
  -- Calls the outer `callback` with `true` when all tools have been processed.
  -- @param index number The 1-based index into the `tools_to_install` list to process next.
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

-- Updates all installed tools that provide an update command by running each update command sequentially.
-- @param callback Optional function called once all updates have been processed; receives `true` when processing completes.
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

  -- Process the pending tool-update queue sequentially starting from `index`.
  -- Continues updating each tool in order; when the end of the queue is reached, invokes the outer `callback` with `true`.
  -- @param index The 1-based position in `tools_to_update` to process next.
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