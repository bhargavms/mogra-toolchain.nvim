---@alias OutputCallback fun(line: string): nil

---@class CommandRunner
---@field run fun(cmd: string, on_output: OutputCallback?, on_complete: fun(success: boolean)?): integer Run a shell command asynchronously and capture its output
local M = {}

---@class JobOptions
---@field on_stdout fun(channel: integer, data: string[], name: string)?
---@field on_stderr fun(channel: integer, data: string[], name: string)?
---@field on_exit fun(channel: integer, exit_code: integer, name: string)?
---@field stdout_buffered boolean?
---@field stderr_buffered boolean?
---@field pty boolean?

---Run a shell command asynchronously and capture its output
---@param cmd string Shell command to execute
---@param on_output OutputCallback? Per-invocation callback to handle output lines
---@param on_complete fun(success: boolean)? Optional callback called when command completes
---@return integer job_id Job ID from vim.fn.jobstart (0 or negative on error)
function M.run(cmd, on_output, on_complete)
  -- Wrap command in shell to ensure proper output capture
  ---@type string[]
  local shell_cmd = { "sh", "-c", cmd .. " 2>&1" }

  ---@type JobOptions
  local job_options = {
    ---@param _ integer channel
    ---@param data string[]
    ---@param _ string name
    on_stdout = function(_, data, _)
      if data then
        vim.schedule(function()
          for _, line in ipairs(data) do
            if line ~= "" then
              if on_output then
                on_output(line)
              end
            end
          end
        end)
      end
    end,
    ---@param _ integer channel
    ---@param data string[]
    ---@param _ string name
    on_stderr = function(_, data, _)
      if data then
        vim.schedule(function()
          for _, line in ipairs(data) do
            if line ~= "" then
              if on_output then
                on_output(line)
              end
            end
          end
        end)
      end
    end,
    ---@param _ integer channel
    ---@param exit_code integer
    ---@param _ string name
    on_exit = function(_, exit_code, _)
      vim.schedule(function()
        if on_output then
          on_output("")
          if exit_code == 0 then
            on_output("✓ Command completed successfully")
          else
            on_output("✗ Command failed with exit code: " .. exit_code)
          end
        end
        if on_complete then
          on_complete(exit_code == 0)
        end
      end)
    end,
    stdout_buffered = false,
    stderr_buffered = false,
    pty = false,
  }

  -- Use jobstart to run command asynchronously
  ---@type integer
  local job_id = vim.fn.jobstart(shell_cmd, job_options)

  if job_id <= 0 then
    if on_output then
      on_output("✗ Failed to start command")
    end
    if on_complete then
      on_complete(false)
    end
    return job_id
  end

  return job_id
end

return M
