local localize = require("sacrilege.localizer").localize
local log = require("sacrilege.log")
local editor = require("sacrilege.editor")

local M = { }

local engines = { }
local expand

function M.setup(opts)
    engines = vim.tbl_deep_extend("force", engines, opts or { })

    expand = engines.expand
    engines.expand = nil

    if expand then
        vim.api.nvim_create_autocmd("CompleteDonePre",
        {
            desc = localize("Expand Snippets"),
            group = vim.api.nvim_create_augroup("sacrilege/snippet", { }),
            pattern = "*",
            callback = function()
                local lsp = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')

                if lsp and lsp.insertTextFormat == 2 then
                    -- Remove inserted text
                    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                    vim.api.nvim_buf_set_text(0, row - 1, col - #vim.v.completed_item.word, row - 1, col, { "" })
                    vim.api.nvim_win_set_cursor(0, { row, col - vim.fn.strwidth(vim.v.completed_item.word) })

                    -- Expand snippet
                    M.expand(vim.tbl_get(lsp, "textEdit", "newText") or lsp.insertText or lsp.label)
                end
            end
        })
    else
        vim.api.nvim_del_augroup_by_id(vim.api.nvim_create_augroup("sacrilege/snippet", { }))
    end
end

function M.expand(body)
    if expand then
        return expand(body) ~= false
    end

    log.warn("Snippet expansion is not configured")

    return false
end

function M.active(opts)
    for _, engine in pairs(engines) do
        if engine.active and engine.active(opts) then
            return engine
        end
    end

    return nil
end

function M.jump(direction)
    for _, engine in pairs(engines) do
        if engine.jump and engine.active and engine.active({ direction = direction }) then
            return engine.jump(direction) ~= false
        end
    end

    return false
end

function M.stop()
    for _, engine in pairs(engines) do
        if engine.stop and engine.active and engine.active() then
            return engine.stop() ~= false
        end
    end

    return false
end

return M
