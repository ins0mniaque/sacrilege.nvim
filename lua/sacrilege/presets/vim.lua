local M = { }

function M.setup(os)
    return {
        insertmode = vim.opt.insertmode,
        mousemodel = vim.opt.mousemodel,
        menubar = '',
        popup = 'PopUp',
        context = { },
        toolbar = false,
        bind =  { ']Keyboard', ']Mouse' },
        menus = {
            'source $VIMRUNTIME/menu.vim',

            { 'Keyboard', hidden = true,
                { '&Menu',  key = '⎇F10', a = '<Cmd>lua require(\'sacrilege\').menu()<CR>' },
                { '&Popup', key = '⇧F10', a = '<Cmd>lua require(\'sacrilege\').popup()<CR>' },
            },

            { 'Mouse', hidden = true,
                { '&Breakpoint', key = 'LeftMouse',  a = '<Cmd>lua require(\'sacrilege.presets.vim\').leftmouse()<CR>'  },
                { '&Popup',      key = 'RightMouse', a = '<Cmd>lua require(\'sacrilege.presets.vim\').rightmouse()<CR>' },
            }
        }
    }
end

function M.leftmouse()
    local mouse  = vim.fn.getmousepos()
    local gutter = vim.fn.getwininfo(mouse.winid)[1].textoff

    if mouse.wincol <= gutter then
        -- TODO: Trigger breakpoint command
        print('Breakpoint at line '..tostring(mouse.line)..'!')
    else
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<LeftMouse>', true, true, true), 'ni')
    end 
end

function M.rightmouse()
    local mouse  = vim.fn.getmousepos()
    local gutter = vim.fn.getwininfo(mouse.winid)[1].textoff

    if mouse.wincol <= gutter then
        require('sacrilege').popup('Gutter')
    else
        require('sacrilege').popup()
    end
end

return M