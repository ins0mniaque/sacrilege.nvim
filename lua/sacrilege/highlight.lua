local editor = require("sacrilege.editor")
local treesitter = require("sacrilege.treesitter")

local M = { }

function M.trigger()
    if editor.supports_lsp_method(0, vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        vim.lsp.buf.document_highlight()
    elseif treesitter.has_parser(treesitter.get_buf_lang()) then
        treesitter.highlight()
    end
end

function M.clear()
    treesitter.clear_highlights()
    vim.lsp.buf.clear_references()
end

function M.setup()
    local group = vim.api.nvim_create_augroup("sacrilege/highlight", { })

    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" },
    {
        group = group,
        callback = M.trigger
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" },
    {
        group = group,
        callback = M.clear
    })
end

return M
