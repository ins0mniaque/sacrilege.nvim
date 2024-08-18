local localize = require("sacrilege.localizer").localize

local M = { }

function M.send(keys, remap)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), remap and "t" or "n", true)
end

function M.notify(msg, log_level, opts)
    local defaults = { title = localize("sacrilege.nvim") }

    vim.notify(localize(msg), log_level or vim.log.levels.INFO, vim.tbl_extend("force", defaults, opts or { }))
end

function M.mapmode(mode)
    mode = mode or vim.fn.mode()

    if     mode == "n" or mode == "i" or mode == "c" or mode == "t" then return mode
    elseif mode == "s" or mode == "S" or mode == "\19"              then return "s"
    elseif mode == "v" or mode == "V" or mode == "\22"              then return "x"
    else                                                                 return nil
    end
end

function M.toggleinsert()
    if vim.bo.modifiable and not vim.bo.readonly then
        vim.cmd.startinsert()
    else
        vim.cmd.stopinsert()
    end
end

function M.stopvisual()
    if M.mapmode() == "x" then
        M.send("<C-\\><C-N>gv")
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

function M.try_close_popup()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative == 'win' then
            vim.api.nvim_win_close(win, true)
            return true
        end
    end

    return false
end

return M
