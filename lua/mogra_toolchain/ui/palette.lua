local M = {}

-- Create a highlight wrapper factory.
-- @param highlight The highlight group name to associate with text (empty string for no highlight).
-- @return A function that accepts `text` and returns a two-element table: `{ text, highlight }`.
local function hl(highlight)
  return function(text)
    return { text, highlight }
  end
end

-- aliases
M.none = hl("")
M.header = hl("MograToolchainHeader")
M.header_secondary = hl("MograToolchainHeaderSecondary")
M.muted = hl("MograToolchainMuted")
M.muted_block = hl("MograToolchainMutedBlock")
M.muted_block_bold = hl("MograToolchainMutedBlockBold")
M.highlight = hl("MograToolchainHighlight")
M.highlight_block = hl("MograToolchainHighlightBlock")
M.highlight_block_bold = hl("MograToolchainHighlightBlockBold")
M.highlight_block_secondary = hl("MograToolchainHighlightBlockSecondary")
M.highlight_block_bold_secondary = hl("MograToolchainHighlightBlockBoldSecondary")
M.highlight_secondary = hl("MograToolchainHighlightSecondary")
M.error = hl("MograToolchainError")
M.warning = hl("MograToolchainWarning")
M.heading = hl("MograToolchainHeading")
M.Comment = hl("MograToolchainComment")

setmetatable(M, {
  __index = function(self, key)
    self[key] = hl(key)
    return self[key]
  end,
})

return M