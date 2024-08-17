local editor = require("sacrilege.editor")
local snippet = require("sacrilege.snippet")

local M = { }

local options

function M.setup(opts)
    options = opts or { }

    if options.selection then
        vim.opt.keymodel = { }
        vim.opt.selection = "exclusive"
        vim.opt.virtualedit = "onemore"

        if options.selection.mouse then
            vim.opt.mouse = "a"
            vim.opt.selectmode = { "mouse", "key", "cmd" }

            -- Fix delayed mouse word selection
            vim.keymap.set("i", "<2-LeftMouse>", "<2-LeftMouse><2-LeftRelease>")
        end

        if options.selection.virtual then
            vim.opt.virtualedit = "block,onemore"
        end
    end

    local group = vim.api.nvim_create_augroup("sacrilege/insertmode", { })

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TermLeave" },
    {
        desc = "Toggle Insert Mode",
        group = group,
        callback = function(_)
            if options.insertmode then
                vim.defer_fn(editor.toggleinsert, 0)
            end
        end
    })

    vim.api.nvim_create_autocmd("ModeChanged",
    {
        desc = "Toggle Insert Mode",
        group = group,
        pattern = { "*:n" },
        callback = function(_)
            if options.insertmode then
                vim.defer_fn(editor.toggleinsert, 0)
            end
        end
    })

    vim.api.nvim_create_autocmd("ModeChanged",
    {
        desc = "Stop Visual Mode",
        group = group,
        pattern = { "*:v", "*:V", "*:\22" },
        callback = function(_)
            if options.selectmode then
                vim.defer_fn(editor.stopvisual, 0)
            end
        end
    })

    if options.selection then
        vim.api.nvim_create_autocmd("ModeChanged",
        {
            desc = "Fix Active Snippet Exclusive Selection",
            group = group,
            pattern = { "*:s" },
            callback = function(_)
                if options.selectmode then
                    vim.opt.selection = snippet.active() and "inclusive" or "exclusive"
                end
            end
        })
    end

    if options.insertmode then
        vim.defer_fn(editor.stopvisual,   0)
        vim.defer_fn(editor.toggleinsert, 0)
    end
end

function M.enable(enabled)
    if not options then
        return editor.notify("sacrilege.insertmode is not configured", vim.log.levels.ERROR)
    end

    options.insertmode = enabled

    if options.insertmode then
        vim.defer_fn(editor.stopvisual,   0)
        vim.defer_fn(editor.toggleinsert, 0)
    end
end

return M
