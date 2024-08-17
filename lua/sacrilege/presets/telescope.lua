local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local editor = require("sacrilege.editor")
    local plugin = require("sacrilege.plugin")
    local methods = vim.lsp.protocol.Methods

    local telescope   = plugin.new("nvim-telescope/telescope.nvim",              "telescope.builtin")
    local filebrowser = plugin.new("nvim-telescope/telescope-file-browser.nvim", "telescope")

    local function supports_lsp(method)
        return function() return editor.supports_lsp_method(0, method) end
    end

    options.commands.open:override(filebrowser:try(function(telescope) telescope.extensions.file_browser.file_browser() end))
    options.commands.find_in_files:override(telescope:try(function(telescope) telescope.live_grep() end))

    options.commands.lsp.definition:override(telescope:try(function(telescope) telescope.lsp_definitions() end)):when(supports_lsp(methods.textDocument_definition))
    options.commands.lsp.references:override(telescope:try(function(telescope) telescope.lsp_references() end)):when(supports_lsp(methods.textDocument_references))
    options.commands.lsp.implementation:override(telescope:try(function(telescope) telescope.lsp_implementations() end)):when(supports_lsp(methods.textDocument_implementation))
    options.commands.lsp.type_definition:override(telescope:try(function(telescope) telescope.lsp_type_definitions() end)):when(supports_lsp(methods.textDocument_typeDefinition))
    options.commands.lsp.document_symbol:override(telescope:try(function(telescope) telescope.lsp_document_symbols() end)):when(supports_lsp(methods.textDocument_documentSymbol))
    options.commands.lsp.workspace_symbol:override(telescope:try(function(telescope) telescope.lsp_dynamic_workspace_symbols() end)):when(supports_lsp(methods.workspace_symbol))
end

return M