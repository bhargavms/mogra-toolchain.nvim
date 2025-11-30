local hl_groups = {
  MograToolchainBackdrop = { bg = "#000000", default = true },
  MograToolchainNormal = { link = "NormalFloat", default = true },
  MograToolchainHeader = { bold = true, fg = "#222222", bg = "#DCA561", default = true },
  MograToolchainHeaderSecondary = { bold = true, fg = "#222222", bg = "#56B6C2", default = true },

  MograToolchainHighlight = { fg = "#56B6C2", default = true },
  MograToolchainHighlightBlock = { bg = "#56B6C2", fg = "#222222", default = true },
  MograToolchainHighlightBlockBold = { bg = "#56B6C2", fg = "#222222", bold = true, default = true },

  MograToolchainHighlightSecondary = { fg = "#DCA561", default = true },
  MograToolchainHighlightBlockSecondary = { bg = "#DCA561", fg = "#222222", default = true },
  MograToolchainHighlightBlockBoldSecondary = { bg = "#DCA561", fg = "#222222", bold = true, default = true },

  MograToolchainLink = { link = "MograToolchainHighlight", default = true },

  MograToolchainMuted = { fg = "#888888", default = true },
  MograToolchainMutedBlock = { bg = "#888888", fg = "#222222", default = true },
  MograToolchainMutedBlockBold = { bg = "#888888", fg = "#222222", bold = true, default = true },

  MograToolchainError = { link = "ErrorMsg", default = true },
  MograToolchainWarning = { link = "WarningMsg", default = true },

  MograToolchainHeading = { bold = true, default = true },
  MograToolchainComment = { fg = "#888888", default = true },
}

for name, hl in pairs(hl_groups) do
  vim.api.nvim_set_hl(0, name, hl)
end
