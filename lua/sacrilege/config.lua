local M = { }

local function map(mode, lhs, rhs, opts)
    local arrow = "[Aa][rR][rR][oO][wW]>"

    if lhs:find(arrow) then
        if type(rhs) == "string" then
            vim.keymap.set(mode, lhs:gsub(arrow, "Left>"), rhs:gsub(arrow, "Left>"), opts)
            vim.keymap.set(mode, lhs:gsub(arrow, "Up>"), rhs:gsub(arrow, "Up>"), opts)
            vim.keymap.set(mode, lhs:gsub(arrow, "Right>"), rhs:gsub(arrow, "Right>"), opts)
            vim.keymap.set(mode, lhs:gsub(arrow, "Down>"), rhs:gsub(arrow, "Down>"), opts)
        else
            vim.keymap.set(mode, lhs:gsub(arrow, "Left>"), function() rhs("Left") end, opts)
            vim.keymap.set(mode, lhs:gsub(arrow, "Up>"), function() rhs("Up") end, opts)
            vim.keymap.set(mode, lhs:gsub(arrow, "Right>"), function() rhs("Right") end, opts)
            vim.keymap.set(mode, lhs:gsub(arrow, "Down>"), function() rhs("Down") end, opts)
        end
    else
        vim.keymap.set(mode, lhs, rhs, opts)
    end
end

function M.parse(options, definitions, predicate)
    local names = options.commands.names
    local keys  = options.keys

    for command, definition in pairs(definitions) do
        local name = names[command] or command
        local bound = keys[command]

        if bound and #bound > 0 then
            if type(bound) == "string" then
                bound = { bound }
            end

            if type(definition) == "table" then
                if type(definition[1]) == "table" then
                    local found = nil
                    for _, subdefinition in pairs(definition) do
                        if not found and (not predicate or predicate(subdefinition)) then
                            found = subdefinition
                        end
                    end

                    definition = found
                end

                local function map_mode(mode, default)
                    if (definition[1] and (definition[mode] or default) ~= false) or (not definition[1] and definition[mode]) then
                        for _, key in pairs(bound) do
                            map(mode, key, definition[1] or definition[mode], { desc = name })
                        end
                    end
                end

                map_mode("n", true)
                map_mode("i", true)
                map_mode("v", true)
                map_mode("s", false)
                map_mode("x", false)
                map_mode("c", false)
                map_mode("t", false)
                map_mode("o", false)
            elseif definition then
                for _, key in pairs(bound) do
                    map({ "n", "i", "v" }, key, definition, { desc = name })
                end
            end
        end
    end
end

function M.parse_popup(options, popup)
    local names = options.commands.names
    local keys  = options.keys

    local updates = { }

    for _, menu in pairs(popup) do
        if type(menu) == "string" then
            menu = { menu }
        end

        if not menu[1]:find("^-") then
            local name = (names[menu[1]] or menu[1]):gsub(" ", "\\ "):gsub("%.", "\\.")
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

            local command = options.commands.definitions[menu[1]]

            if type(command) == "table" then
                if type(command[1]) == "table" then
                    command = command[1]
                end

                if not command[1] then
                    n = false
                    i = false
                    v = false
                end

                if command.n then n = true end
                if command.i then i = true end
                if command.v then v = true end
                if command.x then x = true end
                if command.c then c = true end
                if command.o then o = true end
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
            menucmd("disable PopUp." .. name)

            table.insert(updates, function(mode)
                local verb = vim.fn.maparg(key, mode) ~= "" and "enable" or "disable"

                menucmd(verb .. " PopUp." .. name)
            end)
        else
            vim.cmd.amenu((menu.position or "") .. " PopUp." .. menu[1] .. " :")
        end
    end

    return function(mode)
        for _, update in pairs(updates) do
            update(mode)
        end
    end
end

return M
