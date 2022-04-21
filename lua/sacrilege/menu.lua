-- TODO: Lazy-load modules
local api      = require('sacrilege.menu.api')
local binder   = require('sacrilege.menu.binder')
local executor = require('sacrilege.menu.executor')
local parser   = require('sacrilege.menu.parser')

local M = { }

function M.bind(name, mode)
    return binder.bind(name, mode)
end

function M.execute(name, mode)
    executor.execute(name, mode)
end

function M.get(name, mode)
    return api.menu_get(name, mode)
end

function M.set(menus)
    if menus[1] and type(menus[1]) == 'table' then
        for _, menu in ipairs(menus) do
            api.menu_set(parser.parse(menu))
        end
    else
        api.menu_set(parser.parse(menus))
    end
end

function M.del(name, mode)
    api.menu_del(name, mode)
end

function M.enable(name, mode)
    api.menu_enable(name, mode)
end

function M.disable(name, mode)
    api.menu_disable(name, mode)
end

function M.show(name, mode)
    local menus = api.menu_get(']'..name, mode)
    if not menus then
        do return end
    end

    api.menu_del(']'..name, mode)

    for _, menu in ipairs(menus) do
        menu.hidden = 0
        api.menu_set(menu)
    end
end

function M.hide(name, mode)
    local menus = api.menu_get(name, mode)
    if not menus then
        do return end
    end

    api.menu_del(name, mode)

    for _, menu in ipairs(menus) do
        menu.hidden = 1
        api.menu_set(menu)
    end
end

return M