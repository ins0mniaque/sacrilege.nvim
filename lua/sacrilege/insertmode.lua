local localize = require("sacrilege.localizer").localize
local log = require("sacrilege.log")
local editor = require("sacrilege.editor")

local M = { }

local options

function M.setup(opts)
    options = opts or { }

    local group = vim.api.nvim_create_augroup("sacrilege/insertmode", { })

    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" },
    {
        desc = localize("Toggle Insert Mode"),
        group = group,
        callback = function(_)
            if options.insertmode then
                editor.toggleinsert()
            end
        end
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TermLeave" },
    {
        desc = localize("Toggle Insert Mode"),
        group = group,
        callback = function(_)
            if options.insertmode then
                vim.schedule(editor.toggleinsert)
            end
        end
    })

    vim.api.nvim_create_autocmd("ModeChanged",
    {
        desc = localize("Toggle Insert Mode"),
        group = group,
        pattern = { "*:n" },
        callback = function(_)
            if options.insertmode then
                vim.schedule(editor.toggleinsert)
            end
        end
    })

    vim.api.nvim_create_autocmd("ModeChanged",
    {
        desc = localize("Stop Visual Mode"),
        group = group,
        pattern = { "*:v", "*:V", "*:\22" },
        callback = function(_)
            if options.insertmode then
                vim.schedule(editor.stopvisual)
            end
        end
    })

    if options.insertmode then
        vim.schedule(editor.stopvisual)
        vim.schedule(editor.toggleinsert)
    end
end

function M.enable(enabled)
    if not options then
        return log.err("sacrilege.insertmode is not configured")
    end

    options.insertmode = enabled

    if options.insertmode then
        vim.schedule(editor.stopvisual)
        vim.schedule(editor.toggleinsert)
    end
end

return M
