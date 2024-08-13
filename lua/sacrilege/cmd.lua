local command = require("sacrilege.command")
local editor = require("sacrilege.editor")

local M = { }

local function metatable(prefix)
    prefix = prefix or ""

    return
    {
        __index = function(table, key)
            local existing = rawget(table, key)
            if not existing then
                existing = { }
                setmetatable(existing, metatable(prefix .. key .. "."))
                rawset(table, key, existing)
            end

            return existing
        end,

        __newindex = function(table, key, value)
            local plug = "<Plug>" .. prefix .. key .. "<CR>"

            local existing = rawget(table, key)

            if command.is(existing) then
                existing:unmap(plug)
            elseif type(existing) == "table" then
                local group = table[key]
                for id, _ in pairs(existing) do
                    group[id] = nil
                end
            end

            if command.is(value) then
                value:map(plug)
            elseif type(value) == "table" then
                local group = table[key]
                for id, subcommand in pairs(value) do
                    group[id] = subcommand
                end
            elseif value then
                editor.notify("Invalid value assigned to sacrilege.cmd: " .. vim.inspect(value), vim.log.levels.ERROR)

                value = nil
            end

            rawset(table, key, value)
        end
    }
end

setmetatable(M, metatable())

return M
