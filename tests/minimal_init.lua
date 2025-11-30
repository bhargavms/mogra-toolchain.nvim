-- Minimal init for running tests
-- This file sets up the test environment for Plenary tests

local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if not vim.loop.fs_stat(plenary_path) then
  vim.fn.system({
    "git",
    "clone",
    "--depth=1",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_path,
  })
end
vim.opt.runtimepath:prepend(plenary_path)

-- Add the plugin to runtimepath
local plugin_path = vim.fn.getcwd()
vim.opt.runtimepath:prepend(plugin_path)

-- Add tests directory to package path for fixtures, mocks, and helpers
local tests_path = plugin_path .. "/tests"
package.path = tests_path .. "/?.lua;" .. tests_path .. "/?/init.lua;" .. tests_path .. "/mocks/?.lua;" .. tests_path .. "/fixtures/?.lua;" .. tests_path .. "/helpers/?.lua;" .. package.path

-- Disable swap files for tests
vim.opt.swapfile = false

-- Set up minimal options
vim.opt.termguicolors = true
vim.opt.hidden = true

-- Load plenary
vim.cmd([[runtime plugin/plenary.vim]])
