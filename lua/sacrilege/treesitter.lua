local ts_utils = require("nvim-treesitter.ts_utils")
local locals = require("nvim-treesitter.locals")
local parsers = require("nvim-treesitter.parsers")
local utils = require("nvim-treesitter.utils")

local M =
{
    get_buf_lang = parsers.get_buf_lang,
    has_parser   = parsers.has_parser
}

function M.definition(opts)
    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    local node_at_point = ts_utils.get_node_at_cursor()

    if not node_at_point then
        return
    end

    local definition = locals.find_definition(node_at_point, bufnr)

    ts_utils.goto_node(definition)
end

function M.references(opts)
    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    local node_at_point = ts_utils.get_node_at_cursor()

    if not node_at_point then
        return
    end

    local definition, scope = locals.find_definition(node_at_point, bufnr)
    local usages = locals.find_usages(definition, scope, bufnr)

    if #usages < 1 then
        return
    end

    local qf_list = { }

    for _, node in ipairs(usages) do
        local lnum, col, _ = node:start()
        local type = string.upper(node:type():sub(1, 1))
        local text = vim.treesitter.get_node_text(node, bufnr) or ""

        table.insert(qf_list,
        {
            bufnr = bufnr,
            lnum  = lnum + 1,
            col   = col  + 1,
            text  = text,
            type  = type
        })
    end

    vim.fn.setqflist(qf_list, "r")
    vim.api.nvim_command("copen")
end

function M.rename(new_name, opts)
    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    local node_at_point = ts_utils.get_node_at_cursor()

    if not node_at_point then
        utils.print_warning("Nothing to rename")
        return
    end

    local function complete_rename(new_name)
        if not new_name or #new_name < 1 then
            return
        end

        local definition, scope = locals.find_definition(node_at_point, bufnr)
        local nodes_to_rename = { }

        nodes_to_rename[node_at_point:id()] = node_at_point
        nodes_to_rename[definition:id()] = definition

        for _, n in ipairs(locals.find_usages(definition, scope, bufnr)) do
            nodes_to_rename[n:id()] = n
        end

        local edits = { }

        for _, node in pairs(nodes_to_rename) do
            local lsp_range = ts_utils.node_to_lsp_range(node)
            local text_edit = { range = lsp_range, newText = new_name }
            table.insert(edits, text_edit)
        end

        vim.lsp.util.apply_text_edits(edits, bufnr, "utf-8")
    end

    if not new_name or #new_name < 1 then
        local node_text = vim.treesitter.get_node_text(node_at_point, bufnr)
        local input = { prompt = "New name: ", default = node_text or "" }

        vim.ui.input(input, complete_rename)
    else
        complete_rename(new_name)
    end
end

return M