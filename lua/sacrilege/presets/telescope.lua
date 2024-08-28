local localize = require("sacrilege.localizer").localize
local editor = require("sacrilege.editor")

local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")
    local methods = vim.lsp.protocol.Methods

    local telescope   = plugin.new("nvim-telescope/telescope.nvim",              "telescope.builtin")
    local filebrowser = plugin.new("nvim-telescope/telescope-file-browser.nvim", "telescope")

    options.commands.open:override(filebrowser:try(function(telescope) telescope.extensions.file_browser.file_browser() end))
    options.commands.find_in_files:override(telescope:try(function(telescope) telescope.live_grep() end))

    options.commands.lsp.definition:override(telescope:try(function(telescope) telescope.lsp_definitions() end)):when({ lsp = methods.textDocument_definition })
    options.commands.lsp.references:override(telescope:try(function(telescope) telescope.lsp_references() end)):when({ lsp = methods.textDocument_references })
    options.commands.lsp.implementation:override(telescope:try(function(telescope) telescope.lsp_implementations() end)):when({ lsp = methods.textDocument_implementation })
    options.commands.lsp.type_definition:override(telescope:try(function(telescope) telescope.lsp_type_definitions() end)):when({ lsp = methods.textDocument_typeDefinition })
    options.commands.lsp.document_symbol:override(telescope:try(function(telescope) telescope.lsp_document_symbols() end)):when({ lsp = methods.textDocument_documentSymbol })
    options.commands.lsp.workspace_symbol:override(telescope:try(function(telescope) telescope.lsp_dynamic_workspace_symbols() end)):when({ lsp = methods.workspace_symbol })

    vim.api.nvim_create_autocmd("FileType",
    {
        desc = localize("Fix Telescope Prompt Insert Mode"),
        group = vim.api.nvim_create_augroup("sacrilege/telescope", { }),
        callback = function(event)
            if options.insertmode and event.match == "TelescopePrompt" and vim.fn.mode() == "n" then
                editor.send("<BS>")
            end
        end
    })

    local pickers = plugin.new("nvim-telescope/telescope.nvim", "telescope.pickers")

    require("sacrilege.ui").quickfix = pickers:try(function(pickers, title, items, opts)
        opts = opts or { }

        pickers.new(opts,
        {
            prompt_title = title,
            finder = require("telescope.finders").new_table
            {
                results = items,
                entry_maker = require("telescope.make_entry").gen_from_quickfix(opts),
            },
            previewer = require("telescope.config").values.qflist_previewer(opts),
            sorter = require("telescope.config").values.generic_sorter(opts),
            push_cursor_on_edit = true,
            push_tagstack_on_edit = true
        }):find()
    end)
end

function M.autodetect()
    return pcall(require, "telescope") and true or false
end

return M
