local editor = require("sacrilege.editor")

local M = { }

local cursor, last_cursor, wininfo
local possible_scroll = false

function M.setup()
    -- Fix delayed mouse word selection
    vim.keymap.set("i", "<2-LeftMouse>", "<2-LeftMouse><2-LeftRelease>")

    -- Fix multi-screen mouse selection
    vim.keymap.set({ "n", "i" }, "<S-LeftMouse>", function()
        if cursor then
            local mouse = vim.fn.getmousepos()
            editor.set_selection({ 0, cursor[1], cursor[2] + 1 }, { 0, mouse.line, mouse.column })
            vim.fn.winrestview({ topline = wininfo.topline })
            editor.send("<S-LeftMouse>")
        else
            editor.send("<S-LeftMouse>")
        end
    end)

    local group = vim.api.nvim_create_augroup("sacrilege/mouse", { })

    vim.api.nvim_create_autocmd("WinScrolled",
    {
        desc = "Fix Multi-Screen Mouse Selection",
        group = group,
        callback = function(_)
            if possible_scroll then
                cursor = last_cursor
                possible_scroll = false
            end
        end
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" },
    {
        desc = "Fix Multi-Screen Mouse Selection",
        group = group,
        callback = function(_)
            local last_topline = wininfo and wininfo.topline

            wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]

            last_cursor = cursor
            cursor = vim.api.nvim_win_get_cursor(0)
            last_cursor = last_cursor or cursor

            if not possible_scroll and last_topline then
                if last_topline < wininfo.topline then
                    possible_scroll = cursor[1] == wininfo.topline
                else
                    possible_scroll = cursor[1] == wininfo.botline
                end
            else
                possible_scroll = false
            end
        end
    })
end

return M
