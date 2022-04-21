-- TODO: Lazy-load modules
local api = require('sacrilege.menu.api')

local M = { }

-- NOTE: Parsed format:
-- { 10 (optional, auto-generated), '&Edit', key = '', tip = '', hidden = true,
--   { 20, '&Undo', key = '', a = '', tip = '', silent = true, noremap = true, enabled = false, sid = 1 },
--   { 25, '&Undo', key = '', a = { '', silent = false }, tip = '', silent = true, noremap = true, enabled = false, sid = 1 },
--   '-',
--   { 30, '-' },

-- TODO: Optimize this...
local function parse(menu, lastPriority)
    if not menu[1] and not menu.base then
        return menu
    end

    -- TODO: Better error than indexing failed ([1]) when menu doesn't exists
    local apimenu = menu.base and api.menu_get(menu.base)[1] or { }

    apimenu.priority = menu.priority
    apimenu.actext   = menu.key or apimenu.actext
    apimenu.hidden   = menu.hidden and 1 or apimenu.hidden or 0
    apimenu.tooltip  = menu.tip or apimenu.tooltip

    if menu[1] then
        if type(menu[1]) == 'number' then
            apimenu.priority = menu[1]
        elseif type(menu[1]) == 'string' then
            apimenu.name = menu[1]
        end
    end

    if menu[2] then
        if type(menu[2]) == 'number' then
            apimenu.priority = menu[2]
        elseif type(menu[2]) == 'string' then
            apimenu.name = menu[2]
        end
    end

    local index, _ = apimenu.name:find('&', 1, true)
    if index then
        apimenu.shortcut = apimenu.name:sub(index + 1, index + 1)
        apimenu.name     = apimenu.name:sub(1, index - 1)..apimenu.name:sub(index + 1)
    end

    apimenu.priority = apimenu.priority or (lastPriority or 0) + 10

    for key, value in pairs(menu) do
        local keyType = type(key)
        if keyType == 'string' and key == key:gsub('[^anovxsict]', '') then
            for i = 1, #key do
                apimenu.mappings = apimenu.mappings or { }

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

                apimenu.mappings[key:sub(i, i)] = mapping
            end
        elseif keyType == 'number' then
            if key > 2 and type(value) == 'string' then
                value = { value }
            end

            if type(value) == 'table' then
                local submenu = parse(value, lastPriority)

                apimenu.submenus = apimenu.submenus or { }
                table.insert(apimenu.submenus, submenu)

                lastPriority = submenu.priority
            end
        end
    end

    if apimenu.name:sub(1, 1) == '-' then
        if apimenu.name == '-' then
            apimenu.name = '-SEP'..tostring(apimenu.priority)..'-'
        end

        if not apimenu.mappings then
            apimenu.mappings = { a = {
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

    return apimenu
end

function M.parse(menu)
    return parse(menu)
end

return M