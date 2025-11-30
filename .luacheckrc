max_line_length = 200
globals = {
  "vim",
}
read_globals = {
  "vim",
}

-- Allow setting vim.bo and vim.wo fields (these are valid in Neovim)
ignore = {
  "122", -- setting read-only field (vim.bo, vim.wo are writable at runtime)
}
