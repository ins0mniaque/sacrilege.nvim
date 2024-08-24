local localize = require("sacrilege.localizer").localize
local editor = require("sacrilege.editor")

local M = { }

-- TODO: Add configuration
local rightpairs =
{
    ["\""] = "\"",
    ["'"] = "'",
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
    ["<"] = ">",
    ["«"] = "»"
}

local leftpairs =
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

local lastpairs = { }
local lastcursor
local cursormoved

local function detect_insertion_break()
    local cursor = vim.api.nvim_win_get_cursor(0)

    if lastcursor and (cursor[1] ~= lastcursor[1] or cursor[2] < lastcursor[2]) then
        lastpairs = { }
    end

    lastcursor = cursor
end

local function setup()
    cursormoved = cursormoved or vim.api.nvim_create_autocmd("CursorMovedI",
    {
        desc = localize("Detect Insertion Break"),
        group = vim.api.nvim_create_augroup("sacrilege/autopair", { }),
        callback = detect_insertion_break
    })
end

local function pop(char)
    local lastpair = #lastpairs
    if lastpair > 0 and lastpairs[lastpair] == char then
        lastpairs[lastpair] = nil
        return true
    end

    return false
end

local function push(char)
    table.insert(lastpairs, char)
end

local function get_cursor_chars(window)
    local row, col = unpack(vim.api.nvim_win_get_cursor(window or 0))
    local prevchar = col == 0 and "" or vim.api.nvim_buf_get_text(0, row - 1, col - 1, row - 1, col, { })[1]
    local nextchar = vim.api.nvim_buf_get_text(0, row - 1, col, row - 1, col + 1, { })[1]

    return prevchar, nextchar
end

function M.insert(char)
    setup()

    local prevchar, nextchar = get_cursor_chars()

    local leftpair = leftpairs[char]
    if leftpair and nextchar == char and pop(char) then
        editor.send("<Right>")
        return
    end

    editor.send(char)

    local rightpair = rightpairs[char]
    if rightpair and vim.tbl_contains(nextchars, nextchar) then
        push(rightpair)

        editor.send(rightpair)
        editor.send("<Left>")
    end
end

function M.surround(char)
    local rightpair = rightpairs[char]
    if rightpair then
        editor.send("<C-G>c" .. char .. rightpair .. "<Esc>Pgvo<Right>o<Right>")
    else
        editor.send(char)
    end
end

function M.remove()
    setup()

    local prevchar, nextchar = get_cursor_chars()

    if rightpairs[prevchar] == nextchar then
        pop(nextchar)

        lastcursor = nil
        editor.send("<Right><BS><BS>")

        return true
    end

    return false
end

return M
