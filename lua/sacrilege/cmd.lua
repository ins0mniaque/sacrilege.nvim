local command = require("sacrilege.command")
local editor = require("sacrilege.editor")

local M = { }

local function split(key, init)
    local start, finish, match = key:find("_([oa][rn]d?)_", init)

    if     match == "and" then return key:sub(1, start - 1), key:sub(finish + 1), "__band"
    elseif match == "or"  then return key:sub(1, start - 1), key:sub(finish + 1), "__bor"
    elseif start          then return split(key, start + 1)
    end

    return nil, nil, nil
end

local function parse(table, key)
    local cmd, op
    local keypart = key

    while keypart do
        local left, right, nextop = split(keypart)
        local cmdkey = left or (op and keypart)

        if cmdkey then
            local othercmd = rawget(table, cmdkey)

            if command.is(othercmd) then
                if cmd then
                    cmd = cmd[op](cmd, othercmd)
                else
                    cmd = othercmd
                end
            else
                if cmd or right then
                    -- TODO: Add to health check issues instead
                    editor.notify("Missing command \"" .. cmdkey .. "\" of composite command \"" .. key .. "\"", vim.log.levels.WARN)
                end

                cmd   = nil
                right = nil
            end
        end

        keypart = right
        op      = nextop
    end

    if cmd then
        rawset(table, key, cmd)
    end

    return cmd
end

local function metatable(prefix)
    prefix = prefix or ""

    return
    {
        __index = function(table, key)
            local existing = rawget(table, key) or parse(table, key)

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
                existing.plug = nil
            elseif type(existing) == "table" then
                local group = table[key]
                for id, _ in pairs(existing) do
                    group[id] = nil
                end
            end

            if command.is(value) then
                value:map(plug)
                value.plug = plug
            elseif type(value) == "table" then
                local group = table[key]
                for id, subcommand in pairs(value) do
                    group[id] = subcommand
                end
            elseif value then
                -- TODO: Add to health check issues instead
                editor.notify("Invalid value assigned to sacrilege.cmd: " .. vim.inspect(value), vim.log.levels.ERROR)

                value = nil
            end

            rawset(table, key, value)
        end
    }
end

setmetatable(M, metatable())

return M
