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

  local temp_dir = vim.fn.tempname()
  vim.fn.mkdir(temp_dir, "p")

  local function is_installed()
    return vim.fn.executable(config.executable_name) == 1
  end

  local function download_and_extract()
    local download_cmd = string.format("curl -L %s -o %s/%s.tar.gz", config.url, temp_dir, config.archive_name)
    local success = os.execute(download_cmd)
    if not success then
      return false
    end

    local extract_cmd = string.format("tar -xzf %s/%s.tar.gz -C %s", temp_dir, config.archive_name, config.install_dir)
    success = os.execute(extract_cmd)
    if not success then
      return false
    end

    return true
  end

  local function create_symlink()
    local source = string.format("%s/%s", config.install_dir, config.executable_name)
    local target = string.format("%s/%s", config.executable_dir, config.executable_name)

    os.execute(string.format("rm -f %s", target))

    local success = os.execute(string.format("ln -s %s %s", source, target))
    return success
  end

  local function install()
    vim.fn.mkdir(config.install_dir, "p")
    vim.fn.mkdir(config.executable_dir, "p")

    local success = download_and_extract()
    if not success then
      return false
    end

    success = create_symlink()
    if not success then
      return false
    end

    if config.post_install then
      success = config.post_install()
      if not success then
        return false
      end
    end

    return is_installed()
  end

  local tool = {
    name = config.name,
    description = config.description,
    is_installed = is_installed,
    install = install,
    update = function()
      return install()
    end,
  }

  return tool
end

return M
