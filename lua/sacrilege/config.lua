local is_command = require("sacrilege.command").is

local M = { }

local function map(prefixes, keys, commands, callback)
    for id, command in pairs(commands) do
        local prefixes = vim.list_slice(prefixes, 1, #prefixes)

        table.insert(prefixes, id)

        if is_command(command) then
            local keys = vim.tbl_get(keys, unpack(prefixes))

            if not keys or #keys == 0 then
                keys = { "<Plug>(" .. table.concat(prefixes, ".") .. ")" }
            end

            command:map(keys, callback)
        else
            map(prefixes, keys, command, callback)
        end
    end
end

function M.map(keys, commands, callback)
    map({ }, keys, commands, callback)
end

-- TODO: Localize
function M.build_popup(options, popup)
    local keys = options.keys

    local updates = { }

    for _, menu in pairs(popup) do
        if type(menu) == "string" then
            menu = { menu }
        end

        if not menu[1]:find("^-") then
            local key = keys[menu[1]]

            if type(key) == "table" then
                key = key[1]
            end

            local n = true
            local i = true
            local v = true
            local x = false
            local c = false
            local o = false

            local command = options.commands[menu[1]]

            -- TODO: Health check for invalid commands
            if command then
                local definition = command.definition
                local name       = command.name:gsub(" ", "\\ "):gsub("%.", "\\.")

                if type(definition) == "table" then
                    if type(definition[1]) == "table" then
                        definition = definition[1]
                    end

                    if not definition[1] then
                        n = false
                        i = false
                        v = false
                    end

                    if definition.n then n = true end
                    if definition.i then i = true end
                    if definition.v then v = true end
                    if definition.x then x = true end
                    if definition.c then c = true end
                    if definition.o then o = true end
                end

                if menu.n == false then n = false end
                if menu.i == false then i = false end
                if menu.v == false then v = false end
                if menu.x == false then x = false end
                if menu.c == false then c = false end
                if menu.o == false then o = false end

                local menucmd
                if n and i and (v or x) and c and o then
                    menucmd = vim.cmd.amenu
                elseif n and not i and (v or x) and not c and o then
                    menucmd = vim.cmd.menu
                elseif not n and i and not v and not x and c and not o then
                    menucmd = function(arg) vim.cmd("menu! " .. arg) end
                else
                    menucmd = function(arg)
                        if n then vim.cmd.nmenu(arg) end
                        if i then vim.cmd.imenu(arg) end
                        if v or x then vim.cmd.vmenu(arg) end
                        if c then vim.cmd.cmenu(arg) end
                        if o then vim.cmd.omenu(arg) end
                    end
                end

                menucmd((menu.position or "") .. " PopUp." .. name .. " " .. key)

                table.insert(updates, function(mode)
                    local verb = vim.fn.maparg(key, mode) ~= "" and "enable" or "disable"

                    menucmd(verb .. " PopUp." .. name)
                end)
            end
        else
            vim.cmd.amenu((menu.position or "") .. " PopUp." .. menu[1] .. " <Nop>")
        end
    end

    return function(mode)
        for _, update in pairs(updates) do
            update(mode)
        end
    end
end

return M
