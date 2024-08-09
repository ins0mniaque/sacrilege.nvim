local editor = require("sacrilege.editor")

local M = { }

local s_start
local s_end
local blockkey
local blockmode = false
local bs = vim.api.nvim_replace_termcodes("<BS>", true, false, true)

function M.active()
    return blockmode
end

-- BUG: Typing fast can exit block mode
function M.setup()
    local namespace = vim.api.nvim_create_namespace("sacrilege/blockmode")
    local group     = vim.api.nvim_create_augroup("sacrilege/blockmode", { })

    vim.on_key(function(key, typed)
        local mode = vim.fn.mode()

        if (mode == "\19" and #typed == 1 and typed == key) or (mode == "\22" and typed == bs) then
            s_start = vim.fn.getpos("v")
            s_end = vim.fn.getpos(".")
            blockkey = typed
        end
    end, namespace)

    vim.api.nvim_create_autocmd("ModeChanged",
    {
        desc = "Multi Insert",
        group = group,
        pattern = { "n:i" },
        callback = function(_)
            if blockkey == bs then
                if blockmode then
                    editor.send("<C-\\><C-N>gvI <Esc>gvo<Left>o<Left>\"_dgv<C-G>")
                end
            elseif blockkey then
                editor.send("<BS><C-\\><C-N>gvI" .. blockkey .. " <Esc>gv")

                if s_end[3] < s_start[3] then
                    editor.send("<Right>o")
                else
                    editor.send("o<Right>o")
                end
                local needed = math.abs(s_end[3] - s_start[3]) - 2
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

            blockkey = nil
        end
    })

    vim.api.nvim_create_autocmd("CursorHoldI",
    {
        desc = "End Multi Insert",
        group = group,
        pattern = { "*" },
        callback = function(_)
            if blockmode then
                local cursor = vim.api.nvim_win_get_cursor(0)
                editor.send("<C-\\><C-N>gv\"_d<Esc>i")
                -- TODO: This is too early sometimes... on mode changed too?
                vim.defer_fn(function() vim.api.nvim_win_set_cursor(0, cursor) end, 0)

                blockmode = false
            end
        end
    })
end

return M
