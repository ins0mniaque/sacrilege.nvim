local M = { }

function M.definition(opts)
    require("nvim-treesitter-refactor.navigation").goto_definition(opts and opts.bufnr)
end

function M.references(opts)
    local ts_utils = require("nvim-treesitter.ts_utils")
    local locals = require("nvim-treesitter.locals")

    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    local node_at_point = ts_utils.get_node_at_cursor()
    if not node_at_point then
        return
    end

    local def_node, scope = locals.find_definition(node_at_point, bufnr)
    local usages = locals.find_usages(def_node, scope, bufnr)

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
    vim.api.nvim_command "copen"
end

function M.rename(new_name, opts)
    require("nvim-treesitter-refactor.smart_rename").smart_rename(opts and opts.bufnr)
end

return M