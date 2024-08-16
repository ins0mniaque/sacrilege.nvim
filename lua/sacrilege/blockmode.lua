local editor = require("sacrilege.editor")

local M = { }

local sel_start
local sel_end
local blockmodekey
local exitblockmode = false
local blockmode = false
local delayed = false
local skipnextcursorhold = false
local backspace = vim.api.nvim_replace_termcodes("<BS>", true, false, true)

local function reorder_selection()
    if sel_start[2] > sel_end[2] or (sel_start[2] == sel_end[2] and sel_start[3] > sel_end[3]) then
        local temp = sel_start
        sel_start = sel_end
        sel_end = temp
    end

    if sel_start[3] == sel_end[3] then
        sel_end[3] = sel_end[3] + 1
    end
end

local function start()
    if blockmodekey then
        reorder_selection()

        local key = blockmodekey
        local offset = 0
        local space = " "
        if key == backspace then
            key = ""

            if blockmode then
                space = ""
                offset = -1
            end
        end

        local sel_delete = (not blockmode and sel_end[3] - sel_start[3] == 1) and 0 or 1

        local backspace_delete = 0
        if vim.fn.mode() == "\19" then backspace_delete = delayed and 0 or 1
        elseif delayed then backspace_delete = 1
        end

        if sel_delete == 0 then
            vim.cmd.undo()
        end

        local lines = vim.api.nvim_buf_get_lines(0, sel_start[2] - 1, sel_end[2], true)
        for index, line in ipairs(lines) do
            if index == 1 and key ~= "" then
                lines[index] = line:sub(1, sel_start[3] - 1 + offset) .. key .. space .. line:sub(sel_start[3] + sel_delete)
            elseif key == "" and index == #lines then
                lines[index] = line:sub(1, sel_start[3] - 1 + offset) .. key .. " " .. line:sub(sel_start[3] + backspace_delete)
            elseif delayed and index == #lines then
                lines[index] = line:sub(1, sel_start[3] - 1 + offset) .. key .. space .. line:sub(sel_start[3] + 1 + sel_delete + offset)
            elseif blockmode then
                lines[index] = line:sub(1, sel_start[3] - 1 + offset) .. key .. line:sub(sel_start[3])
            else
                lines[index] = line:sub(1, sel_start[3] - 1 + offset) .. key .. space .. line:sub(sel_start[3])
            end
        end
        vim.api.nvim_buf_set_lines(0, sel_start[2] - 1, sel_end[2], true, lines)
        sel_start[3] = sel_start[3] + 1
        sel_end[3] = sel_start[3] + 1

        if key == "" then
            sel_start[3] = sel_start[3] - 1 + offset
            sel_end[3] = sel_end[3] - 1 + offset
        end

        editor.set_selection(sel_start, sel_end)
        editor.send("<C-G>")

        delayed = false

        vim.schedule(function()
            if vim.fn.mode() == "i" then
                editor.set_selection(sel_start, sel_end)
                editor.send("<C-G>")

                delayed = true
                skipnextcursorhold = true
            end
        end)

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

    reorder_selection()

    local lines = vim.api.nvim_buf_get_lines(0, sel_start[2] - 1, sel_end[2], true)
    for index, line in ipairs(lines) do
        lines[index] = line:sub(1, sel_start[3] - 1) .. line:sub(sel_start[3] + 1)
    end
    vim.api.nvim_buf_set_lines(0, sel_start[2] - 1, sel_end[2], true, lines)

    blockmode = false

    return true
end

function M.paste(register)
    sel_start, sel_end = editor.get_selection()

    reorder_selection()

    local sel_delete = (not blockmode and sel_end[3] - sel_start[3] == 1) and 0 or sel_end[3] - sel_start[3]
    local contents = vim.split(vim.fn.getreg(register), "\n")

    if #contents == 1 then
        contents = contents[1]

        local lines = vim.api.nvim_buf_get_lines(0, sel_start[2] - 1, sel_end[2], true)
        for index, line in ipairs(lines) do
            lines[index] = line:sub(1, sel_start[3] - 1) .. contents .. line:sub(sel_start[3] + sel_delete)
        end
        vim.api.nvim_buf_set_lines(0, sel_start[2] - 1, sel_end[2], true, lines)
    else
        local lines = vim.api.nvim_buf_get_lines(0, sel_start[2] - 1, sel_end[2], true)
        for index, line in ipairs(lines) do
            lines[index] = line:sub(1, sel_start[3] - 1) .. (contents[index] or "") .. line:sub(sel_start[3] + sel_delete)
        end
        vim.api.nvim_buf_set_lines(0, sel_start[2] - 1, sel_end[2], true, lines)
    end

    sel_start[3] = sel_end[3] + 1
    sel_end[3] = sel_start[3] + 1

    editor.set_selection(sel_start, sel_end)
    editor.send("<C-G>")

    -- TODO: Fix selection
    -- TODO: Start blockmode if setup
end

-- BUG: Typing fast can mess up the blockmode selection
-- BUG: Typing space can mess up the blockmode selection
function M.setup()
    local namespace = vim.api.nvim_create_namespace("sacrilege/blockmode")
    local group     = vim.api.nvim_create_augroup("sacrilege/blockmode", { })

    vim.on_key(function(key, typed)
        if vim.fn.mode() ~= "\19" then return end

        if ((#typed == 1 and typed == key) or typed == backspace) and vim.fn.char2nr(typed) >= 32 then
            sel_start, sel_end = editor.get_selection()
            blockmodekey = typed
            exitblockmode = false

            vim.schedule(start)
        elseif typed ~= "" then
            exitblockmode = true
        end
    end, namespace)

    vim.api.nvim_create_autocmd("CursorHoldI",
    {
        desc = "End Block Mode",
        group = group,
        callback = function(_)
            if vim.fn.mode() == "\19" and exitblockmode then
                editor.send("<Esc><Esc>")
            end

            if not skipnextcursorhold then
                M.stop()
            end

            skipnextcursorhold = false
        end
    })
end

return M
