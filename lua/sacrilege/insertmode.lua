local localize = require("sacrilege.localizer").localize
local log = require("sacrilege.log")
local editor = require("sacrilege.editor")

local M = { }

local options

local function toggleinsert()
    if vim.bo.modifiable and not vim.bo.readonly or vim.bo.buftype == "terminal" then
        vim.cmd.startinsert()
    else
        vim.cmd.stopinsert()
    end
end

local function stopvisual()
    if editor.mapmode() == "x" then
        editor.send("<C-\\><C-N>gv")
    end
end

function M.setup(opts)
    options = opts or { }

    local group = vim.api.nvim_create_augroup("sacrilege/insertmode", { })

    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" },
    {
        desc = localize("Toggle Insert Mode"),
        group = group,
        callback = function(_)
            if options.insertmode then
                toggleinsert()
            end
        end
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TermLeave" },
    {
        desc = localize("Toggle Insert Mode"),
        group = group,
        callback = function(_)
            if options.insertmode then
                vim.schedule(toggleinsert)
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
                vim.schedule(toggleinsert)
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
                vim.schedule(stopvisual)
            end
        end
    })

    if options.insertmode then
        vim.schedule(stopvisual)
        vim.schedule(toggleinsert)
    end
end

function M.enable(enabled)
    if not options then
        return log.err("sacrilege.insertmode is not configured")
    end

    options.insertmode = enabled

    if options.insertmode then
        vim.schedule(stopvisual)
        vim.schedule(toggleinsert)
    end
end

function M.escape()
    if vim.fn.mode() == "c" then
        editor.send("<C-U><Esc>")
    elseif options and not options.insertmode then
        editor.send("<Esc>")
    end
end

function M.interrupt()
    if options and options.insertmode then
        toggleinsert()
    else
        editor.send("<C-c>")
    end
end

return M
