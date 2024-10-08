local M = { }

function M.send(keys, remap)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), remap and "t" or "n", true)
end

function M.mapmode(mode)
    mode = mode or vim.fn.mode()

    if     mode == "n" or mode == "i" or mode == "c" or mode == "t" then return mode
    elseif mode == "s" or mode == "S" or mode == "\19"              then return "s"
    elseif mode == "v" or mode == "V" or mode == "\22"              then return "x"
    else                                                                 return nil
    end
end

function M.supports_lsp_method(bufnr, method)
    local clients = vim.lsp.get_clients()
    for _, client in pairs(clients) do
        if vim.lsp.buf_is_attached(bufnr, client.id) and client.supports_method(method) then
            return true
        end
    end

    return false
end

function M.get_selection()
    return vim.fn.getpos("v"), vim.fn.getpos("."), vim.fn.mode()
end

function M.set_selection(start, cursor, mode)
    local selectmode = mode == "s" or mode == "S" or mode == "\19"
    if selectmode then
        mode = vim.fn.nr2char(vim.fn.char2nr(mode) + 3)
    end

    if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
        mode = "v"
    end

    vim.fn.setpos('.', start)
    vim.cmd("normal! " .. mode)
    vim.fn.setpos('.', cursor)

    if selectmode then
        M.send("<C-G>")
    end
end

function M.get_selected_text()
    local s_start, s_end = M.get_selection()
    local n_lines = math.abs(s_end[2] - s_start[2]) + 1
    local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

    lines[1] = string.sub(lines[1], s_start[3], -1)
    if n_lines == 1 then
        lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3])
    else
        lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
    end

    return table.concat(lines, '\n')
end

function M.get_selection_range()
    return
    {
        ["start"] = vim.api.nvim_buf_get_mark(0, "<"),
        ["end"]   = vim.api.nvim_buf_get_mark(0, ">")
    }
end

function M.get_url()
    if vim.bo.filetype == "markdown" then
        local range = vim.api.nvim_win_get_cursor(0)

        vim.treesitter.get_parser():parse(range)

        -- NOTE: Marking the node as "markdown_inline" is required. "markdown" does not work.
        local current_node = vim.treesitter.get_node { lang = "markdown_inline" }
        while current_node do
            local type = current_node:type()
            if type == "inline_link" or type == "image" then
                local child = assert(current_node:named_child(1))
                return vim.treesitter.get_node_text(child, 0)
            end
            current_node = current_node:parent()
        end
    end

    local url = vim.fn.expand("<cfile>")
    if url:match("(https?://[%w-_%.]+%.%w[%w-_%.%%%?%.:/+=&%%[%]#]*)") then
        return url
    end

    return nil
end

function M.try_close_popup()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative ~= "" then
            vim.api.nvim_win_close(win, true)
            return true
        end
    end

    return false
end

return M
