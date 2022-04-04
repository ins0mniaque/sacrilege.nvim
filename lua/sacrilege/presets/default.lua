local M = { }

local mapping = {
    ['New Tab']          = '<C-t>',
    ['Open']             = '<C-o>',
    ['Save']             = '<C-s>',
    ['Close']            = { '<C-F4>', '<C-W>' },
    ['Quit']             = '<C-q>',
    ['Undo']             = '<C-z>',
    ['Redo']             = { '<C-S-z>', '<C-y>' },
    ['Cut']              = '<C-x>',
    ['Copy']             = '<C-c>',
    ['Paste']            = '<C-v>',
    ['Delete']           = '<Del>',
    ['Backspace']        = '<BS>',
    ['Find']             = '<C-f>',
    ['Find Previous']    = '<S-F3>',
    ['Find Next']        = '<F3>',
    ['Select All']       = '<C-a>',
    ['Block Select']     = { '<M-S-Arrow>', '<M-LeftMouse>' },
    ['Command Palette']  = '<C-p>',
    ['File Explorer']    = '<C-b>',
    ['Show Manual Page'] = '<F1>',
    ['Warn Vim User']    = '<Leader><Leader>'
}

local menu = {
    ['&File']      = { '&New Tab', '&Open', '&Save', '&Close', '-', '&Quit' },
    ['&Edit']      = { '&Undo', '&Redo', '-', '&Cut', '&Copy', '&Paste', '&Delete', '-', '&Find', 'Find Pre&vious', 'Find &Next' },
    ['&Selection'] = { 'Select &All', '&Block Select' },
    ['&View']      = { 'Command &Palette', '-', '&File Explorer' },
    ['&Help']      = { 'Show &Manual Page', '&Shortcuts', 'Vim &Help', 'Vim &Reference', 'Vim &Tutorial', '&About' }
}

function M.mapping(os)
    return mapping
end

function M.menu(os)
    return menu
end

return M