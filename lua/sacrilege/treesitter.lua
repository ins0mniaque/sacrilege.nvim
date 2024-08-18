local localize = require("sacrilege.localizer").localize
local log = require("sacrilege.log")

local M = { }

local parser_files

function M.reset_cache()
    parser_files = setmetatable({ },
    {
        __index = function(table, key)
            rawset(table, key, vim.api.nvim_get_runtime_file("parser/" .. key .. ".*", false))

            return rawget(table, key)
        end
    })
end

M.reset_cache()

function M.ft_to_lang(ft)
    local result = vim.treesitter.language.get_lang(ft)

    if result then
        return result
    else
        ft = vim.split(ft, ".", { plain = true })[1]

        return vim.treesitter.language.get_lang(ft) or ft
    end
end

function M.get_buf_lang(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    return M.ft_to_lang(vim.api.nvim_buf_get_option(bufnr, "ft"))
end

function M.has_parser(lang)
    lang = lang or M.get_buf_lang()

    if not lang or #lang == 0 then
        return false
    end

    -- HACK: nvim internal API
    if vim._ts_has_language(lang) then
        return true
    end

    return #parser_files[lang] > 0
end

function M.get_parser(bufnr, lang)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    lang = lang or M.get_buf_lang(bufnr)

    if M.has_parser(lang) then
        return vim.treesitter.get_parser(bufnr, lang)
    end
end

local plugin  = require("sacrilege.plugin")
local nvim_ts = plugin.new("nvim-treesitter/nvim-treesitter", "nvim-treesitter")

function M.definition(opts)
    local locals   = nvim_ts.load("locals")   if not locals   then return end
    local ts_utils = nvim_ts.load("ts_utils") if not ts_utils then return end

    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    local winid = vim.fn.bufwinid(bufnr)
    local node_at_cursor = ts_utils.get_node_at_cursor(winid)

    if not node_at_cursor then
        return
    end

    local definition = locals.find_definition(node_at_cursor, bufnr)

    ts_utils.goto_node(definition)
end

function M.references(opts)
    local locals   = nvim_ts.load("locals")   if not locals   then return end
    local ts_utils = nvim_ts.load("ts_utils") if not ts_utils then return end

    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    local winid = vim.fn.bufwinid(bufnr)
    local node_at_cursor = ts_utils.get_node_at_cursor(winid)

    if not node_at_cursor then
        return
    end

    local definition, scope = locals.find_definition(node_at_cursor, bufnr)
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
    local locals   = nvim_ts.load("locals")   if not locals   then return end
    local ts_utils = nvim_ts.load("ts_utils") if not ts_utils then return end

    local bufnr = opts and opts.bufnr or vim.api.nvim_get_current_buf()
    local winid = vim.fn.bufwinid(bufnr)
    local node_at_cursor = ts_utils.get_node_at_cursor(winid)

    if not node_at_cursor then
        return log.inform("Nothing to rename")
    end

    local function complete_rename(new_text)
        if not new_text or #new_text < 1 then
            return
        end

        local definition, scope = locals.find_definition(node_at_cursor, bufnr)
        local nodes_to_rename = { }

        nodes_to_rename[node_at_cursor:id()] = node_at_cursor
        nodes_to_rename[definition:id()] = definition

        for _, n in ipairs(locals.find_usages(definition, scope, bufnr)) do
            nodes_to_rename[n:id()] = n
        end

        local edits = { }

        for _, node in pairs(nodes_to_rename) do
            local lsp_range = ts_utils.node_to_lsp_range(node)
            local text_edit = { range = lsp_range, newText = new_text }
            table.insert(edits, text_edit)
        end

        vim.lsp.util.apply_text_edits(edits, bufnr, "utf-8")
    end

    if not new_name or #new_name < 1 then
        local text = vim.treesitter.get_node_text(node_at_cursor, bufnr)
        local input = { prompt = localize("New name: "), default = text or "" }

        vim.ui.input(input, complete_rename)
    else
        complete_rename(new_name)
    end
end

return M
