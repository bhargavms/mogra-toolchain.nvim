local M = {}

---@class TarToolBuilder
---@field _name string
---@field _description string?
---@field _version string?
---@field _url string?
---@field _install_dir string?
---@field _executable_dir string?
---@field _executable_name string?
---@field _archive_name string?
---@field _post_install function?
---@field _post_update function?
local TarToolBuilder = {}
TarToolBuilder.__index = TarToolBuilder

---@param name string
---@return TarToolBuilder
function M.tool(name)
  local builder = setmetatable({
    _name = name,
    _description = nil,
    _version = nil,
    _url = nil,
    _install_dir = nil,
    _executable_dir = nil,
    _executable_name = nil,
    _archive_name = nil,
    _post_install = nil,
    _post_update = nil,
  }, TarToolBuilder)
  return builder
end

---@param description string
---@return TarToolBuilder
function TarToolBuilder:description(description)
  self._description = description
  return self
end

---@param version string
---@return TarToolBuilder
function TarToolBuilder:version(version)
  self._version = version
  return self
end

---@param url string
---@return TarToolBuilder
function TarToolBuilder:url(url)
  self._url = url
  return self
end

---@param install_dir string
---@return TarToolBuilder
function TarToolBuilder:install_dir(install_dir)
  self._install_dir = install_dir
  return self
end

---@param executable_dir string
---@return TarToolBuilder
function TarToolBuilder:executable_dir(executable_dir)
  self._executable_dir = executable_dir
  return self
end

---@param executable_name string
---@return TarToolBuilder
function TarToolBuilder:executable_name(executable_name)
  self._executable_name = executable_name
  return self
end

---@param archive_name string
---@return TarToolBuilder
function TarToolBuilder:archive_name(archive_name)
  self._archive_name = archive_name
  return self
end

---@param post_install function
---@return TarToolBuilder
function TarToolBuilder:post_install(post_install)
  self._post_install = post_install
  return self
end

---@param post_update function
---@return TarToolBuilder
function TarToolBuilder:post_update(post_update)
  self._post_update = post_update
  return self
end

---@return Tool
function TarToolBuilder:build()
  if not self._name or not self._description or not self._version or not self._url then
    error("Missing required fields: name, description, version, and url are required")
  end

  local config = {
    name = self._name,
    description = self._description,
    version = self._version,
    url = self._url,
    install_dir = self._install_dir or (vim.fn.stdpath("data") .. "/tools/" .. self._name),
    executable_dir = self._executable_dir or (vim.fn.stdpath("data") .. "/bin"),
    executable_name = self._executable_name or self._name,
    archive_name = self._archive_name or self._name,
    post_install = self._post_install,
    post_update = self._post_update,
  }

  return M.create_tar_tool(config)
end

---@class TarToolConfig
---@field name string Name of the tool
---@field description string Description of the tool
---@field version string Version of the tool
---@field url string URL to download the tar ball
---@field install_dir string Directory where the tool will be installed
---@field executable_dir string Directory where executables will be symlinked
---@field executable_name string Name of the executable (defaults to name if not provided)
---@field archive_name string Name of the archive file (defaults to name if not provided)
---@field post_install function? Optional function to run after installation
---@field post_update function? Optional function to run after update

---@param config TarToolConfig
---@return Tool
function M.create_tar_tool(config)
  if not config.name or not config.description or not config.version or not config.url or not config.install_dir or not config.executable_dir then
    error("Missing required fields in TarToolConfig")
  end

  config.executable_name = config.executable_name or config.name
  config.archive_name = config.archive_name or config.name

  local function is_installed()
    return vim.fn.executable(config.executable_name) == 1
  end

  -- Get the install command as a single script (for output capture)
  local function get_install_cmd()
    local temp_dir = vim.fn.tempname()

    -- Shell-escape all paths and URL for safe interpolation
    local esc_temp_dir = vim.fn.shellescape(temp_dir)
    local esc_install_dir = vim.fn.shellescape(config.install_dir)
    local esc_executable_dir = vim.fn.shellescape(config.executable_dir)
    local esc_url = vim.fn.shellescape(config.url)
    local esc_executable_name = vim.fn.shellescape(config.executable_name)
    local tarball = vim.fn.shellescape(temp_dir .. "/" .. config.archive_name .. ".tar.gz")
    local symlink_path = vim.fn.shellescape(config.executable_dir .. "/" .. config.executable_name)

    local cmds = {
      -- Create directories
      string.format("mkdir -p %s", esc_temp_dir),
      string.format("mkdir -p %s", esc_install_dir),
      string.format("mkdir -p %s", esc_executable_dir),

      -- Download tarball
      string.format("curl -fSL %s -o %s", esc_url, tarball),

      -- Extract tarball
      string.format("tar -xzf %s -C %s", tarball, esc_install_dir),

      -- Remove old symlink if it exists
      string.format("rm -f %s", symlink_path),

      -- Find the executable in install_dir (handles nested tar structures)
      -- Pick first match from find's traversal order (not necessarily the shallowest)
      string.format(
        "FOUND_EXE=$(find %s -type f -name %s -perm -u+x 2>/dev/null | head -n1) && "
          .. 'if [ -z "$FOUND_EXE" ]; then '
          .. 'echo "Error: executable not found in extracted archive" >&2; exit 1; '
          .. "fi && "
          .. 'ln -s "$FOUND_EXE" %s',
        esc_install_dir,
        esc_executable_name,
        symlink_path
      ),

      -- Cleanup: remove temp directory and tarball
      string.format("rm -rf %s", esc_temp_dir),
    }
    return table.concat(cmds, " && ")
  end

  local tool = {
    name = config.name,
    description = config.description,
    is_installed = is_installed,
    -- Lazy command generators (fresh temp_dir each call)
    get_install_cmd = get_install_cmd,
    get_update_cmd = get_install_cmd, -- Same as install for tar tools
    -- Hooks to run after installation/update completes
    post_install = config.post_install,
    post_update = config.post_update,
  }

  return tool
end

return M
