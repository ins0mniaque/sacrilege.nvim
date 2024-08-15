local editor = require("sacrilege.editor")

local M = { }

local sel_start
local sel_end
local mode
local blockmodekey
local blockmode = false
local backspace = vim.api.nvim_replace_termcodes("<BS>", true, false, true)

local function start()
    if blockmodekey == backspace then
        if blockmode then
            editor.send("<C-\\><C-N>gvI <Esc>gvo<Left>o<Left>\"_dgv<C-G>")
        end
    elseif blockmodekey then
        local needed = math.abs(sel_end[3] - sel_start[3]) - 2

        if not blockmode and needed < 0 then
            editor.send("<Cmd>undo<CR><C-\\><C-N>gvI" .. blockmodekey .. " <Esc>gv")
        else
            editor.send("<BS><C-\\><C-N>gvI" .. blockmodekey .. " <Esc>gv")
        end

        if sel_end[3] - sel_start[3] < -1 then
            editor.send("<Right>o")
        else
            editor.send("o<Right>o")
        end

        while needed > 0 do
            editor.send("<Left>")
            needed = needed - 1
        end

        if needed < 0 then
            editor.send("<Right>")
        end

        editor.send("<C-G>")

        blockmode = true
    end

    blockmodekey = nil
end

function M.active()
    return blockmode
end

function M.stop()
    if not blockmode then
        return false
    end

    local cursor = vim.api.nvim_win_get_cursor(0)

    editor.send("<C-\\><C-N>gv\"_d<Esc>")

    -- BUG: This is too early sometimes...
    vim.defer_fn(function() vim.api.nvim_win_set_cursor(0, cursor) end, 0)

    blockmode = false

    return true
end

function M.paste(register)
    editor.send("<C-\\><C-N>gv\"_d<Esc>gvI<C-R>" .. register .. "<Esc>")
end

-- BUG: Typing fast can exit block mode
function M.setup()
    local namespace = vim.api.nvim_create_namespace("sacrilege/blockmode")
    local group     = vim.api.nvim_create_augroup("sacrilege/blockmode", { })

    vim.on_key(function(key, typed)
        if mode == "\19" and #typed == 1 and (typed == key or typed == backspace) and typed ~= "\7" then
            sel_start = vim.fn.getpos("v")
            sel_end = vim.fn.getpos(".")
            blockmodekey = typed

            vim.schedule(start)
        end
    end, namespace)

    vim.api.nvim_create_autocmd("ModeChanged",
    {
        desc = "Block Mode",
        group = group,
        callback = function(event)
            mode = vim.fn.mode()

            if blockmode and event.match == "\22:n" then
                editor.send("gv<C-G>")
            end
        end
    })

    vim.api.nvim_create_autocmd("CursorHoldI",
    {
        desc = "End Block Mode",
        group = group,
        callback = function(_)
            M.stop()
        end
    })
end

return M
