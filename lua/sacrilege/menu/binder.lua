local api = require('sacrilege.menu.api')

local M = { }

local function mapkey(actext)
    -- TODO: Handle chords and <Key> format
    if not actext or actext == '' or actext:sub(1, 1) == ':' then
        return nil
    end

    actext = actext:gsub('Ctrl-', 'C-')
    actext = actext:gsub('Ctrl', 'C-')
    actext = actext:gsub('%^', 'C-')
    actext = actext:gsub('⌃', 'C-')
    actext = actext:gsub('⎈', 'C-')
    actext = actext:gsub('Alt-', 'A-')
    actext = actext:gsub('Alt', 'A-')
    actext = actext:gsub('⎇', 'A-')
    actext = actext:gsub('⌥', 'A-')
    actext = actext:gsub('Shift-', 'S-')
    actext = actext:gsub('Shift', 'S-')
    actext = actext:gsub('⇧', 'S-')
    actext = actext:gsub('Meta-', 'M-')
    actext = actext:gsub('Meta', 'M-')
    actext = actext:gsub('◆', 'M-')
    actext = actext:gsub('◆', 'M-')

    actext = actext:gsub('Super-', 'D-')
    actext = actext:gsub('Super', 'D-')
    actext = actext:gsub('❖', 'D-')
    actext = actext:gsub('Command-', 'D-')
    actext = actext:gsub('Command', 'D-')
    actext = actext:gsub('Cmd-', 'D-')
    actext = actext:gsub('Cmd', 'D-')
    actext = actext:gsub('⌘', 'D-')
    actext = actext:gsub('', 'D-')
    actext = actext:gsub('Windows-', 'D-')
    actext = actext:gsub('Windows', 'D-')
    actext = actext:gsub('Win-', 'D-')
    actext = actext:gsub('Win', 'D-')

    actext = actext:gsub('Hyper-', 'C-A-S-M-')
    actext = actext:gsub('Hyper', 'C-A-S-M-')
    actext = actext:gsub('✦', 'C-A-S-M-')

    actext = actext:gsub('⎋', 'Esc')
    actext = actext:gsub('⇥', 'Tab')
    actext = actext:gsub('↹', 'Tab')
    actext = actext:gsub('SPC', 'Space')
    actext = actext:gsub('␣', 'Space')
    actext = actext:gsub('⏎', 'CR')
    actext = actext:gsub('↩', 'CR')
    actext = actext:gsub('⌤', 'CR')
    actext = actext:gsub('⌫', 'BS')
    actext = actext:gsub('⌦', 'Del')
    actext = actext:gsub('⌧', 'Del')
    actext = actext:gsub('↖', 'Home')
    actext = actext:gsub('↘', 'End')
    actext = actext:gsub('⇞', 'PgUp')
    actext = actext:gsub('⇟', 'PgDown')
    actext = actext:gsub('↑', 'Up')
    actext = actext:gsub('↑', 'Up')
    actext = actext:gsub('↓', 'Down')
    actext = actext:gsub('⇣', 'Down')
    actext = actext:gsub('←', 'Left')
    actext = actext:gsub('⇠', 'Left')
    actext = actext:gsub('→', 'Right')
    actext = actext:gsub('⇢', 'Right')

    if actext:sub(1, 1) ~= '<' and actext:len() > 1 then
        actext = '<'..actext..'>'
    end

    return actext
end

local function bind(menu, parentName, parentKey)
    local name = menu.name
    local key  = mapkey(menu.actext)

    if parentName then
        name = parentName..'.'..name
    end

    if parentKey then
        key = parentKey..(key or '')
    end

    if key and menu.mappings then
        for mode, mapping in pairs(menu.mappings) do
            vim.api.nvim_set_keymap(mode, key, mapping.rhs, { silent  = mapping.silent  == 1,
                                                              noremap = mapping.noremap == 1 })
        end
    end

    if menu.submenus then
        for _, submenu in ipairs(menu.submenus) do
            bind(submenu, name, key)
        end
    end
end

-- TODO: Allow binding specific bufnr
function M.bind(name, mode)
    for _, menu in ipairs(api.menu_get(name, mode)) do
        bind(menu)
    end
end

return M