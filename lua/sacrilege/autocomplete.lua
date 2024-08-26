local localize = require("sacrilege.localizer").localize
local completion = require("sacrilege.completion")

local M = { }

-- TODO: CmdlineChanged auto-complete
function M.setup()
    local namespace = vim.api.nvim_create_namespace("sacrilege/autocomplete")
    local group     = vim.api.nvim_create_augroup("sacrilege/autocomplete", { })

    -- TODO: Add option
    local function on(char)
        return char ~= " "
    end

    local lastrow, lastcol
    local wasvisible = false
    local typed = false

    vim.on_key(function(_, typed)
        if typed ~= "" then
            wasvisible = completion.visible() ~= nil
        end
    end, namespace)

    vim.api.nvim_create_autocmd("InsertCharPre",
    {
        desc = localize("Trigger Autocompletion"),
        group = group,
        callback = function()
            typed = vim.fn.state("m") ~= "m"
            if not typed or completion.visible() then
                return
            end

            local char = vim.v.char
            if #char > 1 then
                char = char:sub(1, 1)
            end

            if on(char) then
                completion.trigger()
            end
        end
    })

    vim.api.nvim_create_autocmd("CursorMovedI",
    {
        desc = localize("Trigger Autocompletion"),
        group = group,
        callback = function()
            if not typed then
                return
            end

            local row, col = unpack(vim.api.nvim_win_get_cursor(0))

            if wasvisible then
                if row == lastrow and (col == lastcol + 1 or col == lastcol - 1) then
                    local char = col == 0 and " " or vim.api.nvim_buf_get_text(0, row - 1, col - 1, row - 1, col, { })[1]

                    if on(char) then
                        completion.trigger()
                    else
                        completion.abort()
                    end
                else
                    completion.abort()
                end
            end

            lastrow = row
            lastcol = col
        end
    })
end

return M
