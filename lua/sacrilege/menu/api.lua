local M = { }

local function escape(name)
    -- TODO: Fix this escape any '.' not followed by letter
    return name:gsub('%.%.%.%.', '\\.\\.\\..'):gsub('%.%.%.', '\\.\\.\\.'):gsub(' ', '\\ ')
end

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

function M.menu_get(name, mode)
    local exists, menu = pcall(vim.fn.menu_get, escape(name), mode)

    return exists and menu or nil
end

function M.menu_set(menus)
    if menus[1] and type(menus[1]) == 'table' then
        for _, menu in ipairs(menus) do
            menu_set(menu)
        end
    else
        menu_set(menus)
    end
end

function M.menu_del(name, mode)
    local exists, _ = pcall(vim.cmd, (mode or 'a')..'unmenu '..escape(name))

    return exists
end

return M