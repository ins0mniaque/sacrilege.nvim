local M = { }

function M.map(options, definitions, context, mappings)
    local names = options.commands.names
    local keys  = options.keys

    context = context or { }

    for command, definition in pairs(definitions) do
        local name = names[command] or command
        local bound = keys[command]

        if not bound or #bound == 0 then
            bound = { "<Plug>(" .. command .. ")" }
        end

        if type(bound) == "string" then
            bound = { bound }
        end

        local cmd = require("sacrilege.command").new(name, definition)

        cmd:map(bound, context, mappings)
    end
end

function M.build_popup(options, popup)
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

            local command = options.commands.global[menu[1]]

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

            table.insert(updates, function(mode)
                local verb = vim.fn.maparg(key, mode) ~= "" and "enable" or "disable"

                menucmd(verb .. " PopUp." .. name)
            end)
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
