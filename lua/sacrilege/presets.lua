local M = { }

-- TODO: atom { macos = { }, linux = { }, windows = { } } : https://github.com/nwinkler/atom-keyboard-shortcuts
-- TODO: vscode
-- TODO: nano : https://www.nano-editor.org/dist/latest/cheatsheet.html

local function normalize(name)
    return name == '' and 'none' or name or 'default'
end

function M.load(name)
    local exists, preset = pcall(require, 'sacrilege.presets.'..normalize(name))

    return preset
end

function M.os()
    local uname = vim.loop.os_uname()

    if     uname.sysname:find('Windows') then return 'Windows'
    elseif uname.sysname == 'Darwin'     then return 'macOS'
    else                                      return uname.sysname
    end
end

return M