local editor = require("sacrilege.editor")

local M = { }

-- TODO: Add configuration
local pairs =
{
    ["\""] = "\"",
    ["'"] = "'",
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
    ["<"] = ">",
    ["«"] = "»"
}

local nextchars = { "", " ", ".", ",", ";", ":", "=", ")", "]", "}", ">", "»" }

function M.insert(char)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local nextchar = vim.api.nvim_buf_get_text(0, row - 1, col, row - 1, col + 1, { })[1]

    editor.send(char)

    if vim.tbl_contains(nextchars, nextchar) then
        editor.send(M.pair(char))
        editor.send("<Left>")
    end
end

function M.surround(char)
    editor.send("<C-G>c" .. char .. M.pair(char) .. "<Esc>Pgvo<Right>o<Right>")
end

function M.remove()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local char = col == 0 and "" or vim.api.nvim_buf_get_text(0, row - 1, col - 1, row - 1, col, { })[1]
    local nextchar = vim.api.nvim_buf_get_text(0, row - 1, col, row - 1, col + 1, { })[1]

    if pairs[char] == nextchar then
        editor.send("<Right><BS><BS>")
        return true
    end

    return false
end

function M.pair(char)
    return pairs[char] or char
end

return M
