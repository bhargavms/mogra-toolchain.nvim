local Ui = require("mogra_toolchain.ui.core.ui")

-- Spinner frames
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_frame = 0

-- Track current line number during render for line_to_tool mapping
-- Header takes 2 lines, so we start at offset 2
local HEADER_OFFSET = 2
local current_line = HEADER_OFFSET

---@param state ToolchainUiState
return function(state)
  local tools = state.tools.all

  -- Reset line tracking and line_to_tool map
  current_line = HEADER_OFFSET
  state.tools.line_to_tool = {}

  -- Group tools by status (preserving original order within each group)
  local installing = {}
  local installed = {}
  local available = {}

  for _, tool in ipairs(tools) do
    local install_state = tool.install_state or "not_installed"
    if install_state == "installing" then
      table.insert(installing, tool)
    elseif install_state == "installed" then
      table.insert(installed, tool)
    else
      table.insert(available, tool)
    end
  end

  -- Update spinner frame if any tool is installing or checking
  local any_installing_or_checking = #installing > 0 or state.tools.checking_statuses
  for _, tool in ipairs(tools) do
    if tool.install_state == "checking" then
      any_installing_or_checking = true
      break
    end
  end

  if any_installing_or_checking then
    spinner_frame = (spinner_frame + 1) % #spinner_frames
  end

  local items = {}

  -- Helper to add a line and track it
  local function add_line(node, tool)
    current_line = current_line + 1
    if tool then
      state.tools.line_to_tool[current_line] = tool
    end
    table.insert(items, node)
  end

  -- Helper to add an empty line
  local function add_empty_line()
    current_line = current_line + 1
    table.insert(items, Ui.EmptyLine())
  end

  -- Helper to render a tool line
  local function render_tool(tool, show_log)
    local install_state = tool.install_state or "not_installed"
    local is_installing = install_state == "installing"
    local is_checking = install_state == "checking"
    local is_failed = install_state == "failed"
    local status = (is_installing or is_checking) and spinner_frames[(spinner_frame % #spinner_frames) + 1]
      or (install_state == "installed" and "✓")
      or (is_failed and "x")
      or (install_state == "not_installed" and "✗")
      or "?"

    local status_hl = status == "✓" and "MograToolchainHighlight"
      or (status == "x" or status == "✗") and "MograToolchainError"
      or (is_installing or is_checking) and "MograToolchainMuted"
      or status == "?" and "MograToolchainMuted"
      or ""

    local line_parts = {
      { status .. " ", status_hl },
      { tool.name, "" },
      { " - " .. tool.description, "MograToolchainMuted" },
    }

    add_line(Ui.HlTextNode({ line_parts }), tool)

    -- Show log output for installing tools
    if show_log and is_installing and tool.tailed_output and tool.tailed_output ~= "" then
      local log_lines = vim.split(tool.tailed_output, "\n")
      -- Show last few lines of output
      local max_lines = 5
      local start_line = math.max(1, #log_lines - max_lines + 1)
      for i = start_line, #log_lines do
        local line = log_lines[i]
        if line and line ~= "" then
          local hl = "MograToolchainMuted"
          if line:match("^#") or line:match("^%[") then
            hl = "MograToolchainSecondaryHighlight"
          elseif line:match("[Ee]rror") or line:match("[Ff]ail") then
            hl = "MograToolchainError"
          elseif line:match("[Ss]uccess") or line:match("[Dd]one") then
            hl = "MograToolchainHighlight"
          end
          -- Log lines don't map to tools (can't select them)
          current_line = current_line + 1
          table.insert(
            items,
            Ui.HlTextNode({
              { { "  ▶ " .. line, hl } },
            })
          )
        end
      end
    end
  end

  -- Account for the initial EmptyLine in the return
  current_line = current_line + 1

  -- Section: Installing
  if #installing > 0 then
    add_line(
      Ui.HlTextNode({
        { { "Installing", "MograToolchainHeading" }, { " (" .. #installing .. ")", "MograToolchainMuted" } },
      }),
      nil
    )
    for _, tool in ipairs(installing) do
      render_tool(tool, true) -- show log for installing
    end
    add_empty_line()
  end

  -- Section: Installed
  if #installed > 0 then
    add_line(
      Ui.HlTextNode({
        { { "Installed", "MograToolchainHeading" }, { " (" .. #installed .. ")", "MograToolchainMuted" } },
      }),
      nil
    )
    for _, tool in ipairs(installed) do
      render_tool(tool, false)
    end
    add_empty_line()
  end

  -- Section: Available
  if #available > 0 then
    add_line(
      Ui.HlTextNode({
        { { "Available", "MograToolchainHeading" }, { " (" .. #available .. ")", "MograToolchainMuted" } },
      }),
      nil
    )
    for _, tool in ipairs(available) do
      render_tool(tool, false)
    end
  end

  -- Footer
  local footer_text = " i: Install  u: Update  q: Quit"

  return Ui.Node({
    Ui.EmptyLine(),
    Ui.CascadingStyleNode({ "INDENT" }, items),
    Ui.EmptyLine(),
    Ui.HlTextNode({
      { { footer_text, "MograToolchainComment" } },
    }),
  })
end
