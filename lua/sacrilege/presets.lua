local M = { }

-- TODO: atom { macos = { }, linux = { }, windows = { } } : https://github.com/nwinkler/atom-keyboard-shortcuts
-- TODO: vscode
-- TODO: nano : https://www.nano-editor.org/dist/latest/cheatsheet.html

local presets = {
    none = { mapping = { }, menu = { } },
    default = {
        mapping = {
            Linux = {
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
            },
            macOS = {
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
            },
            Windows = {
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
        },
        menu = {
            Linux = {
                ['&File']      = { '&New Tab', '&Open', '&Save', '&Close', '-', '&Quit' },
                ['&Edit']      = { '&Undo', '&Redo', '-', '&Cut', '&Copy', '&Paste', '&Delete', '-', '&Find', 'Find Pre&vious', 'Find &Next' },
                ['&Selection'] = { 'Select &All', '&Block Select' },
                ['&View']      = { 'Command &Palette', '-', '&File Explorer' },
                ['&Help']      = { 'Show &Manual Page', '&Shortcuts', 'Vim &Help', 'Vim &Reference', 'Vim &Tutorial', '&About' }
            },
            macOS = {
                ['&File']      = { '&New Tab', '&Open', '&Save', '&Close', '-', '&Quit' },
                ['&Edit']      = { '&Undo', '&Redo', '-', '&Cut', '&Copy', '&Paste', '&Delete', '-', '&Find', 'Find Pre&vious', 'Find &Next' },
                ['&Selection'] = { 'Select &All', '&Block Select' },
                ['&View']      = { 'Command &Palette', '-', '&File Explorer' },
                ['&Help']      = { 'Show &Manual Page', '&Shortcuts', 'Vim &Help', 'Vim &Reference', 'Vim &Tutorial', '&About' }
            },
            Windows = {
                ['&File']      = { '&New Tab', '&Open', '&Save', '&Close', '-', '&Quit' },
                ['&Edit']      = { '&Undo', '&Redo', '-', '&Cut', '&Copy', '&Paste', '&Delete', '-', '&Find', 'Find Pre&vious', 'Find &Next' },
                ['&Selection'] = { 'Select &All', '&Block Select' },
                ['&View']      = { 'Command &Palette', '-', '&File Explorer' },
                ['&Help']      = { 'Show &Manual Page', '&Shortcuts', 'Vim &Help', 'Vim &Reference', 'Vim &Tutorial', '&About' }
            }
        }
    }
}

local function detect_os()
    local uname = vim.loop.os_uname()

    if     uname.sysname:find('Windows') then return 'Windows'
    elseif uname.sysname == 'Darwin'     then return 'macOS'
    else                                      return uname.sysname
    end
end

local function find(kind, name, os)
    os   = os or detect_os()
    name = name == '' and 'none' or name

    local preset = presets[name]
    if not preset then
        return nil
    end

    preset = preset[kind]

    return preset[os] or preset
end

function M.mapping(preset, os)
    return find('mapping', preset, os)
end

function M.menu(preset, os)
    return find('menu', preset, os)
end

return M