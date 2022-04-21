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
                { '&Menu',  key = '⎇F10', a = '<Cmd>lua require(\'sacrilege.ui\').popup(\'\')<CR>' },
                { '&Popup', key = '⇧F10', a = '<Cmd>lua require(\'sacrilege.ui\').popup()<CR>' },
            },

            { 'Mouse', hidden = true,
                { '&Popup', key = 'RightMouse', a = '<Cmd>lua require(\'sacrilege.ui\').popup()<CR>' },
            }
        }
    }
end

return M