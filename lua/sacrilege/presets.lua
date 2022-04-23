local M = { }

function M.os()
    local uname = vim.loop.os_uname()

    if     uname.sysname:find('Windows') then return 'Windows'
    elseif uname.sysname == 'Darwin'     then return 'macOS'
    else                                      return uname.sysname
    end
end

-- TODO: Allow presets outside 'sacrilege.presets.'
function M.load(name, os)
    local exists, preset = pcall(require, 'sacrilege.presets.'..name:lower())

    return exists and preset.load(os or M.os()) or nil
end

return M