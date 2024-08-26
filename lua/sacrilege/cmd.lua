local log = require("sacrilege.log")
local command = require("sacrilege.command")

local M = { }

local function split(key, init)
    local start, finish, match = key:find(" ([oa][rn]d?) ", init)

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
                    log.warn("Missing command \"%s\" of composite command \"%s\"", cmdkey, key)
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
            key = prefix .. key

            local value = rawget(M, key) or parse(M, key)

            if not value then
                value = { }
                setmetatable(value, metatable(key .. "."))
            end

            return value
        end,

        __newindex = function(table, key, value)
            key = prefix .. key

            local plug = "<Plug>" .. key .. "<CR>"
            local existing = rawget(M, key)

            if command.is(existing) then
                existing:unmap(plug)
                existing.plug = nil
            end

            if command.is(value) then
                value:map(plug)
                value.plug = plug

                rawset(M, key, value)
            elseif type(value) == "table" then
                local group = M[key]
                for id, subcommand in pairs(value) do
                    group[id] = subcommand
                end
            elseif value then
                log.err("Invalid value assigned to sacrilege.cmd.%s: %s", key, vim.inspect(value))
            elseif prefix ~= "" then
                local starts_with_key = "^" .. key:gsub("%.", "%%.") .. "%."
                for id, _ in pairs(M) do
                    if id:match(starts_with_key) then
                        rawset(M, prefix .. id, nil)
                    end
                end
            else
                rawset(M, key, nil)
            end
        end
    }
end

setmetatable(M, metatable())

return M
