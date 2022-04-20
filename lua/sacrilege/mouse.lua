local M = { }

function M.locate()
    local location = vim.fn.getmousepos()

    if location.winid == 0 then
        if location.screenrow > vim.o.lines - vim.o.cmdheight then
            location.cmdline = true
        else
            location.statusline = true
        end

        location.winid  = nil
        location.winrow = nil
        location.wincol = nil
        location.line   = nil
        location.column = nil

        return location
    end

    if location.winrow == 0 then
        location.tabline = true

        location.line   = nil
        location.column = nil

        return location
    end

    if location.line == 0 or location.column == 0 then
        if vim.o.laststatus < 3 and location.winrow == vim.fn.winheight(location.winid) + 1 then
            location.statusline = true
        else
            location.border = true
        end

        location.line   = nil
        location.column = nil

        return location
    end

    local wininfo   = vim.fn.getwininfo(location.winid)[1]
    local winconfig = vim.api.nvim_win_get_config(location.winid)

    location.bufnr = wininfo.bufnr
    location.winnr = wininfo.winnr

    if wininfo.loclist  == 1    then location.loclist        = true end
    if wininfo.terminal == 1    then location.terminal       = true end
    if wininfo.quickfix == 1    then location.quickfix       = true end
    if winconfig.focusable      then location.focusable      = true end
    if winconfig.relative ~= '' then location.floatingwindow = true end

    if location.wincol <= wininfo.textoff then
        location.margin = true

        if vim.api.nvim_win_get_option(location.winid, 'number') then
            local screenattr = vim.fn.screenattr(location.screenrow, location.screencol)
            local numberattr = vim.fn.screenattr(location.screenrow, location.screencol + wininfo.textoff - location.wincol)

            if screenattr == numberattr then
                location.numbercolumn = true
            end
        end

        if not location.numbercolumn and vim.api.nvim_win_get_option(location.winid, 'foldcolumn') ~= '0' then
            -- TODO: vim.fn.foldlevel for specific bufnr
            local foldlevel = location.bufnr == vim.fn.bufnr() and vim.fn.foldlevel(location.line) or 0
            if location.wincol <= foldlevel then
                location.foldcolumn = true

                -- TODO: Replace vim.opt.fillchars with nvim_win_get_option(location.winid) and nvim_get_option
                local screenchar = vim.fn.nr2char(vim.fn.screenchar(location.screenrow, location.screencol))
                local fillchars  = vim.opt.fillchars:get()

                if     screenchar == (fillchars['foldopen']  or '-') then location.foldtoggle    = true
                elseif screenchar == (fillchars['foldclose'] or '+') then location.foldtoggle    = true
                elseif screenchar == (fillchars['foldsep']   or '│') then location.foldseparator = true
                elseif screenchar == (fillchars['foldsep']   or '|') then location.foldseparator = true
                end
            end
        end

        if not location.numbercolumn and not location.foldcolumn and vim.api.nvim_win_get_option(location.winid, 'signcolumn') ~= '0' then
            location.signcolumn = true
        end

        return location
    end

    -- TODO: vim.fn.foldclosed for specific bufnr
    if location.bufnr == vim.fn.bufnr() and vim.fn.foldclosed(location.line) ~= -1 then
        location.closedfold = true

        return location
    end

    local eof = vim.fn.screenpos(location.winid, vim.fn.line('$', location.winid), 1)
    if location.screenrow > eof.row then
        location.eof = true

        return location
    end

    local eol = vim.fn.screenpos(location.winid, location.line, 2147483647)
    if location.screencol >= eol.endcol then
        location.eol = true

        if location.screencol == eol.endcol and vim.api.nvim_win_get_option(location.winid, 'list') then
            -- TODO: Replace vim.opt.listchars with nvim_win_get_option(location.winid) and nvim_get_option
            local eolchar = vim.opt.listchars:get()['eol'] or ''
            if eolchar ~= '' then
                location.eolchar = true
            end
        end

        -- NOTE: vim.fn.screenchar returns blended characters instead of spaces on floating windows
        if not location.eolchar and not location.floatingwindow then
            local hastext = vim.fn.screenchar(location.screenrow, location.screencol)     ~= 32 or
                            location.screencol > eol.endcol + 1                                 and
                            vim.fn.screenchar(location.screenrow, location.screencol - 1) ~= 32
            if hastext then
                location.virtualtext = true
            end
        end
    end

    return location
end

function M.input(keys)
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), 'ni')
end

return M