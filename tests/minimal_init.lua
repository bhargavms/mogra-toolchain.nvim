-- tests/minimal_init.lua
local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({
    "git",
    "clone",
    "--depth=1",
    "https://github.com/nvim-lua/plenary.nvim.git",
    install_path,
  })
end

vim.opt.rtp:append(install_path)
vim.opt.rtp:append(".")

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
