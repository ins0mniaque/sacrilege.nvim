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

function M.get_buf_lang(buffer)
    buffer = buffer or vim.api.nvim_get_current_buf()

    return M.ft_to_lang(vim.bo[buffer].ft)
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

function M.get_parser(buffer, lang)
    buffer = buffer or vim.api.nvim_get_current_buf()
    lang = lang or M.get_buf_lang(buffer)

    if M.has_parser(lang) then
        return vim.treesitter.get_parser(buffer, lang)
    end
end

local editor  = require("sacrilege.editor")
local plugin  = require("sacrilege.plugin")
local nvim_ts = plugin.new("nvim-treesitter/nvim-treesitter", "nvim-treesitter")

function M.selectnode()
    local incremental_selection = nvim_ts.load("incremental_selection") if not incremental_selection then return end

    local mode = vim.fn.mode()

    if mode == "i" then
        editor.send("<C-O>v<Right><Left>")
        vim.schedule(incremental_selection.node_incremental)
    elseif mode == "n" then
        incremental_selection.init_selection()
    else
        incremental_selection.node_incremental()
    end
end

function M.selectscope()
    local incremental_selection = nvim_ts.load("incremental_selection") if not incremental_selection then return end

    local mode = vim.fn.mode()

    if mode == "i" then
        editor.send("<C-O>v<Right><Left>")
        vim.schedule(incremental_selection.scope_incremental)
    elseif mode == "n" then
        incremental_selection.init_selection()
    else
        incremental_selection.scope_incremental()
    end
end

function M.selectsubnode()
    local incremental_selection = nvim_ts.load("incremental_selection") if not incremental_selection then return end

    local mode = vim.fn.mode()

    if mode == "i" then
        editor.send("<C-O>v<Right><Left>")
        vim.schedule(incremental_selection.node_decremental)
    elseif mode == "n" then
        incremental_selection.init_selection()
    else
        incremental_selection.node_decremental()
    end
end

function M.definition()
    local locals   = nvim_ts.load("locals")   if not locals   then return end
    local ts_utils = nvim_ts.load("ts_utils") if not ts_utils then return end

    local buffer = vim.api.nvim_get_current_buf()
    local window = vim.fn.bufwinid(buffer)
    local node_at_cursor = ts_utils.get_node_at_cursor(window)

    if not node_at_cursor then
        return
    end

    local definition = locals.find_definition(node_at_cursor, buffer)

    ts_utils.goto_node(definition)
end

function M.references()
    local locals   = nvim_ts.load("locals")   if not locals   then return end
    local ts_utils = nvim_ts.load("ts_utils") if not ts_utils then return end

    local buffer = vim.api.nvim_get_current_buf()
    local window = vim.fn.bufwinid(buffer)
    local node_at_cursor = ts_utils.get_node_at_cursor(window)

    if not node_at_cursor then
        return
    end

    local definition, scope = locals.find_definition(node_at_cursor, buffer)
    local usages = locals.find_usages(definition, scope, buffer)

    if #usages < 2 then
        if #usages == 1 then
            ts_utils.goto_node(usages[1])
        end

        return
    end

    local items = { }

    for _, node in ipairs(usages) do
        local lnum, col, _ = node:start()
        local type = string.upper(node:type():sub(1, 1))
        local text = vim.treesitter.get_node_text(node, buffer) or ""

        table.insert(items,
        {
            bufnr = buffer,
            lnum  = lnum + 1,
            col   = col  + 1,
            text  = text,
            type  = type
        })
    end

    require("sacrilege.ui").quickfix(localize("References"), items)
end

function M.rename(new_name)
    local locals   = nvim_ts.load("locals")   if not locals   then return end
    local ts_utils = nvim_ts.load("ts_utils") if not ts_utils then return end

    local buffer = vim.api.nvim_get_current_buf()
    local window = vim.fn.bufwinid(buffer)
    local node_at_cursor = ts_utils.get_node_at_cursor(window)

    if not node_at_cursor then
        return log.inform("Nothing to rename")
    end

    local function complete_rename(new_text)
        if not new_text or #new_text < 1 then
            return
        end

        local definition, scope = locals.find_definition(node_at_cursor, buffer)
        local nodes_to_rename = { }

        nodes_to_rename[node_at_cursor:id()] = node_at_cursor
        nodes_to_rename[definition:id()] = definition

        for _, n in ipairs(locals.find_usages(definition, scope, buffer)) do
            nodes_to_rename[n:id()] = n
        end

        local edits = { }

        for _, node in pairs(nodes_to_rename) do
            local lsp_range = ts_utils.node_to_lsp_range(node)
            local text_edit = { range = lsp_range, newText = new_text }
            table.insert(edits, text_edit)
        end

        vim.lsp.util.apply_text_edits(edits, buffer, "utf-8")
    end

    if not new_name or #new_name < 1 then
        local text = vim.treesitter.get_node_text(node_at_cursor, buffer)
        local input = { prompt = localize("New name: "), default = text or "" }

        vim.ui.input(input, complete_rename)
    else
        complete_rename(new_name)
    end
end

local highlights_namespace
local last_highlighted_nodes

local function setup_highlights()
    if not highlights_namespace then
        highlights_namespace   = vim.api.nvim_create_namespace("sacrilege/treesitter/highlights")
        last_highlighted_nodes = { }

        vim.cmd("highlight default link TSDefinition Search")
        vim.cmd("highlight default link TSDefinitionUsage Visual")
    end
end

function M.highlight(buffer)
    local locals   = nvim_ts.load("locals")   if not locals   then return end
    local ts_utils = nvim_ts.load("ts_utils") if not ts_utils then return end

    setup_highlights()

    buffer = buffer or vim.api.nvim_get_current_buf()

    local window = vim.fn.bufwinid(buffer)
    local node_at_cursor = ts_utils.get_node_at_cursor(window)
    if node_at_cursor and node_at_cursor == last_highlighted_nodes[buffer] and M.has_highlights(buffer) then
        return
    else
        if not last_highlighted_nodes[buffer] then
            vim.api.nvim_buf_attach(buffer, false,
            {
                on_detach = function()
                    last_highlighted_nodes[buffer] = nil
                    return true
                end,
                -- NOTE: This is needed to prevent on_detach from being called on buffer reload
                on_reload = function() end
            })
        end

        last_highlighted_nodes[buffer] = node_at_cursor
    end

    M.clear_highlights(buffer)
    if not node_at_cursor then
        return
    end

    local definition, scope = locals.find_definition(node_at_cursor, buffer)
    local usages = locals.find_usages(definition, scope, buffer)

    for _, node in ipairs(usages) do
        ts_utils.highlight_node(node, buffer, highlights_namespace, "TSDefinitionUsage")
    end

    if definition ~= node_at_cursor then
        ts_utils.highlight_node(definition, buffer, highlights_namespace, "TSDefinition")
    end
end

function M.has_highlights(buffer)
    return highlights_namespace and #vim.api.nvim_buf_get_extmarks(buffer or 0, highlights_namespace, 0, -1, { }) > 0
end

function M.clear_highlights(buffer)
    if highlights_namespace then
        vim.api.nvim_buf_clear_namespace(buffer or 0, highlights_namespace, 0, -1)
    end
end

return M
