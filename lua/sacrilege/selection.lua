local localize = require("sacrilege.localizer").localize
local editor = require("sacrilege.editor")
local snippet = require("sacrilege.snippet")

local M = { }

function M.setup(options)
    vim.opt.keymodel = { }
    vim.opt.selection = "exclusive"
    vim.opt.virtualedit = "onemore"

    if options.mouse then
        vim.opt.mouse = "a"
        vim.opt.selectmode = { "mouse", "key", "cmd" }
    end

    if options.virtual then
        vim.opt.virtualedit = "block,onemore"
    end

    local group = vim.api.nvim_create_augroup("sacrilege/selection", { })

    vim.api.nvim_create_autocmd("ModeChanged",
    {
        desc = localize("Fix Active Snippet Exclusive Selection"),
        group = group,
        pattern = { "*:s" },
        callback = function(_)
            vim.opt.selection = snippet.active() and "inclusive" or "exclusive"
        end
    })

    local clipboard

    vim.api.nvim_create_autocmd("InsertEnter",
    {
        desc = localize("Disable Copy On Delete"),
        group = group,
        callback = function(_)
            clipboard = vim.fn.getreg("+")
        end
    })

    vim.api.nvim_create_autocmd("TextYankPost",
    {
        desc = localize("Disable Copy On Delete"),
        group = group,
        callback = function(_)
            if clipboard and vim.v.event.operator == "d" and vim.v.event.regname == "" then
                vim.fn.setreg("+", clipboard)
            end

            clipboard = nil
        end
    })

    if options.mouse then
        -- Fix delayed mouse word selection
        vim.keymap.set("i", "<2-LeftMouse>", "<2-LeftMouse><2-LeftRelease>", { desc = localize("Select Word") })

        -- Fix multi-screen mouse selection
        local cursor, last_cursor, wininfo
        local possible_scroll = false

        local function restore_cursor_and_select()
            if cursor then
                local mouse   = vim.fn.getmousepos()
                local topline = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].topline

                editor.set_selection({ 0, cursor[1], cursor[2] + 1 }, { 0, mouse.line, mouse.column })
                vim.fn.winrestview({ topline = topline })
                editor.send("<S-LeftMouse>")
            else
                editor.send("<S-LeftMouse>")
            end
        end

        vim.keymap.set({ "n", "i" }, "<S-LeftMouse>", restore_cursor_and_select, { desc = localize("Set Selection End") })

        vim.api.nvim_create_autocmd("WinScrolled",
        {
            desc = localize("Fix Multi-Screen Mouse Selection"),
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
            desc = localize("Fix Multi-Screen Mouse Selection"),
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
end

return M
