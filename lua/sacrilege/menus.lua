local M = { }

-- NOTE: Parsed format:
-- { 10 (optional, auto-generated), '&Edit', key = '', tip = '', hidden = true,
--   { 20, '&Undo', key = '', a = '', tip = '', silent = true, noremap = true, enabled = false, sid = 1 },
--   { 25, '&Undo', key = '', a = { '', silent = false }, tip = '', silent = true, noremap = true, enabled = false, sid = 1 },
--   '-',
--   { 30, '-' },

local function escape(name)
    -- TODO: Fix this escape any '.' not followed by letter
    return name:gsub('%.%.%.%.', '\\.\\.\\..'):gsub('%.%.%.', '\\.\\.\\.'):gsub(' ', '\\ ')
end

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

-- NOTE: Uses vim.fn.menu_get format
local function menu_set(menu, parentName, parentPriority)
    local name     = menu.name
    local priority = menu.priority

    if menu.shortcut then
        local index, _ = menu.name:find(menu.shortcut, 1, true)
        if index then
            name = name:sub(1, index - 1)..'&'..name:sub(index)
        end
    end

    if menu.actext then
        name = name..'<Tab>'..menu.actext
    end

    if menu.hidden == 1 and name:sub(1, 1) ~= ']' then
        name = ']'..name
    elseif menu.hidden == 0 and name:sub(1, 1) == ']' then
        name = name:sub(2)
    end

    name = escape(name)

    if parentName then
        name = parentName..'.'..name
    end

    if parentPriority then
        priority = parentPriority..'.'..priority
    end

    if menu.mappings then
        for mode, mapping in pairs(menu.mappings) do
            if mapping.rhs then
                local command = mapping.noremap == 1 and 'noremenu' or 'menu'
                local rhs     = mapping.rhs == '' and '<Nop>' or mapping.rhs

                command = (mode == 't' and 'tl' or mode)..command
                if mapping.silent == 1 then
                    command = command..' <silent>'
                end

                if mapping.sid then
                    rhs = rhs:gsub('<SID>', '<SNR>'..tostring(mapping.sid)..'_')
                end

                vim.cmd(command..' '..priority..' '..name..' '..rhs)
            else
                local command = 'unmenu'

                command = (mode == 't' and 'tl' or mode)..command

                vim.cmd(command..' '..name)
            end
        end
    end

    if menu.submenus then
        for _, submenu in ipairs(menu.submenus) do
            menu_set(submenu, name, priority)
        end
    end

    if menu.tooltip and menu.tooltip:match('^%s*(.-)%s*$') ~= '' then
        vim.cmd('tmenu '..name..' '..menu.tooltip)
    end
end

-- NOTE: Converts to vim.fn.menu_get format
-- TODO: Optimize this...
local function parse(menu, lastPriority)
    local realmenu = menu.base and vim.fn.menu_get(escape(menu.base))[1] or { }

    realmenu.priority = menu.priority
    realmenu.actext   = menu.key or realmenu.actext
    realmenu.hidden   = menu.hidden and 1 or realmenu.hidden or 0
    realmenu.tooltip  = menu.tip or realmenu.tooltip

    if menu[1] then
        if type(menu[1]) == 'number' then
            realmenu.priority = menu[1]
        elseif type(menu[1]) == 'string' then
            realmenu.name = menu[1]
        end
    end

    if menu[2] then
        if type(menu[2]) == 'number' then
            realmenu.priority = menu[2]
        elseif type(menu[2]) == 'string' then
            realmenu.name = menu[2]
        end
    end

    local index, _ = realmenu.name:find('&', 1, true)
    if index then
        realmenu.shortcut = realmenu.name:sub(index + 1, index + 1)
        realmenu.name     = realmenu.name:sub(1, index - 1)..realmenu.name:sub(index + 1)
    end

    realmenu.priority = realmenu.priority or (lastPriority or 0) + 10

    for key, value in pairs(menu) do
        local keyType = type(key)
        if keyType == 'string' and key == key:gsub('[^anovxsict]', '') then
            for i = 1, #key do
                realmenu.mappings = realmenu.mappings or { }

                local mapping = {
                    enabled = menu.enabled == false and 0 or 1,
                    noremap = menu.noremap == false and 0 or 1,
                    silent  = menu.silent == false and 0 or 1,
                    sid     = menu.sid,
                    rhs     = value
                }

                if type(value) == 'table' then
                    if value.enabled then mapping.enabled = value.enabled == false and 0 or 1 end
                    if value.noremap then mapping.noremap = value.noremap == false and 0 or 1 end
                    if value.silent  then mapping.silent  = value.silent  == false and 0 or 1 end

                    if     value.sid then mapping.sid = value.sid end
                    if     value.rhs then mapping.rhs = value.rhs
                    elseif value[1]  then mapping.rhs = value[1]
                    end
                end

                realmenu.mappings[key:sub(i, i)] = mapping
            end
        elseif keyType == 'number' then
            if key > 2 and type(value) == 'string' then
                value = { value }
            end

            if type(value) == 'table' then
                local submenu = parse(value, lastPriority)

                realmenu.submenus = realmenu.submenus or { }
                table.insert(realmenu.submenus, submenu)

                lastPriority = submenu.priority
            end
        end
    end

    if realmenu.name:sub(1, 1) == '-' then
        if realmenu.name == '-' then
            realmenu.name = '-SEP'..tostring(realmenu.priority)..'-'
        end

        if not realmenu.mappings then
            realmenu.mappings = { a = {
                enabled = 1,
                noremap = 1,
                silent  = 1,
                sid     = 1,
                rhs     = ''
            } }
        end
    end

    -- TODO: Add delete support { delete = 'a' | 'ni' }
    if menu.delete then
        -- TODO: For each mode in delete, set mapping.rhs = nil
    end

    return realmenu
end

function M.get(name, mode)
    local exists, menu = pcall(vim.fn.menu_get, escape(name), mode)

    return exists and menu or nil
end

function M.set(menus)
    if menus[1] then
        if type(menus[1]) == 'table' then
            for _, menu in ipairs(menus[1]) do
                M.set(menu)
            end
        else
            menu_set(parse(menus))
        end
    else
        menu_set(menus)
    end
end

function M.del(name, mode)
    vim.cmd((mode or 'a')..'unmenu '..escape(name))
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
    for _, menu in ipairs(vim.fn.menu_get(escape(name), mode)) do
        bind(menu)
    end
end

-- TODO: Add enable/disable
function M.hide(name, mode)
    local menus = M.get(name, mode)
    if not menus then
        do return end
    end

    M.del(name)

    for _, menu in ipairs(menus) do
        menu.hidden = 1
        menu_set(menu)
    end
end

function M.show(name, mode)
    local menus = M.get(']'..name, mode)
    if not menus then
        do return end
    end

    M.del(']'..name)

    for _, menu in ipairs(menus) do
        menu.hidden = 0
        menu_set(menu)
    end
end

function M.context()

end

function M.setup()
    -- :autocmd BufNewFile,BufRead *.html setlocal nowrap
    -- :autocmd FileType javascript nnoremap <buffer> <localleader>c I//<esc>
    -- BufWinEnter for BufType
end

return M