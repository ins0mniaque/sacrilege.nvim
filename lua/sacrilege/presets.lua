local M = { }

M.default = {
     ['New Tab']          = '<C-t>',
     ['Open']             = '<C-o>',
     ['Close']            = { '<C-F4>', '<C-W>' },
     ['Quit']             = '<C-q>',
     ['Save']             = '<C-s>',
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
     ['File Explorer']    = '<C-b>',
     ['Command Palette']  = '<C-p>',
     ['Show Manual Page'] = '<F1>',
     ['Warn Vim User']    = '<Leader><Leader>'
}

-- M.atom { macos = { }, linux = { }, windows = { } }
-- M.vscode
-- M.nano : https://www.nano-editor.org/dist/latest/cheatsheet.html

return M