local editor = require("sacrilege.editor")

local M = { }

-- TODO: Add configuration
local right_pairs =
{
    ["\""] = "\"",
    ["'"] = "'",
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
    ["<"] = ">",
    ["«"] = "»"
}

local left_pairs =
{
    ["\""] = "\"",
    ["'"] = "'",
    [")"] = "(",
    ["]"] = "[",
    ["}"] = "{",
    [">"] = "<",
    ["»"] = "«"
}

local nextchars = { "", " ", ".", ",", ";", ":", "=", ")", "]", "}", ">", "»" }

local function get_cursor_chars(window)
    local row, col = unpack(vim.api.nvim_win_get_cursor(window or 0))
    local prevchar = col == 0 and "" or vim.api.nvim_buf_get_text(0, row - 1, col - 1, row - 1, col, { })[1]
    local nextchar = vim.api.nvim_buf_get_text(0, row - 1, col, row - 1, col + 1, { })[1]

    return prevchar, nextchar
end

function M.insert(char)
    local prevchar, nextchar = get_cursor_chars()

    local left_pair = left_pairs[char]
    if left_pair and prevchar == left_pair and nextchar == char then
        editor.send("<Right>")
        return
    end

    editor.send(char)

    local right_pair = right_pairs[char]
    if right_pair and vim.tbl_contains(nextchars, nextchar) then
        editor.send(right_pair)
        editor.send("<Left>")
    end
end

function M.surround(char)
    local right_pair = right_pairs[char]
    if right_pair then
        editor.send("<C-G>c" .. char .. right_pair .. "<Esc>Pgvo<Right>o<Right>")
    else
        editor.send(char)
    end
end

function M.remove()
    local prevchar, nextchar = get_cursor_chars()

    if right_pairs[prevchar] == nextchar then
        editor.send("<Right><BS><BS>")
        return true
    end

    return false
end

return M
