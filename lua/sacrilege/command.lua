local editor = require("sacrilege.editor")

local M = { }

M.__index = M

function M.is(command)
    return type(command) == "table" and command.__index == M
end

function M.isnot(command)
    return not M.is(command)
end

function M.new(name, definition)
    local self = { }

    self.name       = name
    self.definition = definition

    return setmetatable(self, M)
end

function M:copy(name)
    if type(self.definition) ~= "table" then
        self.definition = { self.definition }
    end

    local definition = { linked = self.definition.linked or self.definition }

    if type(self.definition) == "table" then
        definition["and"] = self.definition["and"]
        definition["or"]  = self.definition["or"]
    end

    return M.new(self.name or name, definition)
end

function M:clone(name)
    return M.new(self.name or name, type(self.definition) == "table" and vim.tbl_deep_extend("force", { }, self.definition) or self.definition)
end

function M:override(definition)
    if type(self.definition) == "table" then
        for id, _ in pairs(self.definition) do
            self.definition[id] = nil
        end

        if type(definition) ~= "table" then
            definition = { definition }
        end

        for id, value in pairs(definition) do
            self.definition[id] = value
        end
    else
        self.definition = definition
    end

    return self
end

local function copy_modes(definition, linked)
    if type(linked) == "table" then
        if linked[1] then
            definition.n = linked.n
            definition.i = linked.i
            definition.v = linked.v
            definition.s = linked.s
            definition.x = linked.x
            definition.c = linked.c
            definition.t = linked.t
            definition.o = linked.o
        else
            if not linked.n then definition.n = false end
            if not linked.i then definition.i = false end
            if not linked.v then definition.v = false end
            if     linked.s then definition.s = true  end
            if     linked.x then definition.x = true  end
            if     linked.c then definition.c = true  end
            if     linked.t then definition.t = true  end
            if     linked.o then definition.o = true  end
        end
    end
end

local function when(definition, predicate)
    if type(definition) == "string" then
        return function(...)
            if predicate(...) then
                editor.send(definition)
                return true
            end

            return false
        end
    else
        return function(...)
            if predicate(...) then
                return definition(...) ~= false
            end

            return false
        end
    end
end

function M:when(predicate)
    if type(self.definition) ~= "table" then
        self.definition = when(self.definition, predicate)
    elseif self.definition.linked then
        local linked = self.definition.linked

        self.definition = { function(...) return predicate(...) end, ["and"] = { linked = linked } }

        copy_modes(self.definition, linked)
    elseif self.definition[1] then
         self.definition[1] = when(self.definition[1], predicate)
    else
        if self.definition.n then self.definition.n = when(self.definition.n, predicate) end
        if self.definition.i then self.definition.i = when(self.definition.i, predicate) end
        if self.definition.v then self.definition.v = when(self.definition.v, predicate) end
        if self.definition.s then self.definition.s = when(self.definition.s, predicate) end
        if self.definition.x then self.definition.x = when(self.definition.x, predicate) end
        if self.definition.c then self.definition.c = when(self.definition.c, predicate) end
        if self.definition.t then self.definition.t = when(self.definition.t, predicate) end
        if self.definition.o then self.definition.o = when(self.definition.o, predicate) end
    end

    return self
end

function M:named(name)
    self.name = name

    return self
end

M.__concat = function(name, self)
    return self:named(name)
end

local function try_convert_to_default(definition)
    if type(definition) == "table" and not definition[1] and not definition.linked then
        local any = definition.n or definition.i or definition.v or definition.s or definition.x or definition.c or definition.t or definition.o
        local all_any = (not definition.n or definition.n == any) and
                        (not definition.i or definition.i == any) and
                        (not definition.v or definition.v == any) and
                        (not definition.s or definition.s == any) and
                        (not definition.x or definition.x == any) and
                        (not definition.c or definition.c == any) and
                        (not definition.t or definition.t == any) and
                        (not definition.o or definition.o == any)

        if all_any then
            definition[1] = any

            if definition.n then definition.n = nil  else definition.n = false end
            if definition.i then definition.i = nil  else definition.i = false end
            if definition.v then definition.v = nil  else definition.v = false end
            if definition.s then definition.s = true else definition.s = nil   end
            if definition.x then definition.x = true else definition.x = nil   end
            if definition.c then definition.c = true else definition.c = nil   end
            if definition.t then definition.t = true else definition.t = nil   end
            if definition.o then definition.o = true else definition.o = nil   end
        end
    end

    return definition
end

-- TODO: Convert table form to non-table form when possible
local function try_convert_to_smallest_form(definition)
    if type(definition) == "table" and not definition[1] and not definition.linked then
        local count = (definition.n and 1 or 0) +
                      (definition.i and 1 or 0) +
                      (definition.v and 1 or 0) +
                      (definition.s and 1 or 0) +
                      (definition.x and 1 or 0) +
                      (definition.c and 1 or 0) +
                      (definition.t and 1 or 0) +
                      (definition.o and 1 or 0)

        if count == 1 then
            return definition
        end

        return try_convert_to_default(definition)
    end

    return definition
end

local function convert_to_nondefault(definition)
    if type(definition) ~= "table" then
        definition = { definition }
    end

    if definition.linked then
        local cloned = vim.tbl_deep_extend("force", { }, definition.linked)

        cloned["and"] = definition["and"]
        cloned["or"]  = definition["or"]

        definition = cloned
    end

    if definition[1] then
        definition.n = definition.n ~= false and definition[1]
        definition.i = definition.i ~= false and definition[1]
        if definition.v ~= false then
            if definition.x == true and definition.s ~= true then
                definition.x = definition[1]
            elseif definition.x ~= true and definition.s == true then
                definition.s = definition[1]
            else
                definition.v = definition[1]
            end
        end
        definition.s = definition.s == true and definition[1]
        definition.x = definition.x == true and definition[1]
        definition.c = definition.c == true and definition[1]
        definition.t = definition.t == true and definition[1]
        definition.o = definition.o == true and definition[1]

        definition[1] = nil
    end

    return definition
end

function M:requires(options)
    if type(self.definition) ~= "table" then
        self.definition = { self.definition }
    end

    if self.definition.linked then
        local cloned = vim.tbl_deep_extend("force", { }, self.definition.linked)

        cloned["and"] = self.definition["and"]
        cloned["or"]  = self.definition["or"]

        self.definition = cloned
    end

    for option, value in pairs(options) do
        self.definition[option] = value
    end

    return self
end

function M:default(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.n = rhs
        self.definition.i = rhs
        self.definition.v = rhs
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.n = rhs ~= false and nil
            self.definition.i = rhs ~= false and nil
            self.definition.v = rhs ~= false and nil
        elseif rhs == false then
            self.definition.n = nil
            self.definition.i = nil
            self.definition.v = nil
        else
            editor.notify("Could not enable Normal/Insert/Visual Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:normal(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.n = rhs
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.n = rhs ~= false and nil
        elseif rhs == false then
            self.definition.n = nil
        else
            editor.notify("Could not enable Normal Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:insert(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.i = rhs
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.i = rhs ~= false and nil
        elseif rhs == false then
            self.definition.i = nil
        else
            editor.notify("Could not enable Insert Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:visual(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        if self.definition.s then
            self.definition.x = rhs
        else
            self.definition.v = rhs
        end
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            if self.definition.s then
                self.definition.x = rhs or nil
            else
                self.definition.v = rhs ~= false and nil
            end
        elseif rhs == false then
            if self.definition.s then
                self.definition.x = nil
            else
                self.definition.v = false
            end
        else
            editor.notify("Could not enable Visual Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:select(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.s = rhs
        if self.definition.v then
            self.definition.x = self.definition.v
            self.definition.v = nil
        end
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.s = rhs or nil
            if self.definition.v then
                self.definition.x = self.definition.v
                self.definition.v = false
            end
        elseif rhs == false then
            self.definition.s = nil
            if self.definition.v then
                self.definition.x = self.definition.v
                self.definition.v = nil
            end
        else
            editor.notify("Could not enable Select Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:cmdline(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.c = rhs
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.c = rhs or nil
        elseif rhs == false then
            self.definition.c = nil
        else
            editor.notify("Could not enable Command Line Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:terminal(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.t = rhs
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.t = rhs or nil
        elseif rhs == false then
            self.definition.t = nil
        else
            editor.notify("Could not enable Terminal Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:pending(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.o = rhs
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.o = rhs or nil
        elseif rhs == false then
            self.definition.o = nil
        else
            editor.notify("Could not enable Operator-Pending Mode for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:all(rhs)
    if rhs ~= true and rhs ~= false then
        self.definition = convert_to_nondefault(self.definition)
        self.definition.n = rhs
        self.definition.i = rhs
        self.definition.v = rhs
        self.definition.s = nil
        self.definition.x = nil
        self.definition.c = rhs
        self.definition.t = rhs
        self.definition.o = rhs
        self.definition = try_convert_to_smallest_form(self.definition)
    else
        self.definition = try_convert_to_default(self.definition)
        if type(self.definition) ~= "table" then
            self.definition = { self.definition }
        end

        if self.definition[1] then
            self.definition.n = rhs ~= false and nil
            self.definition.i = rhs ~= false and nil
            self.definition.v = rhs ~= false and nil
            self.definition.s = nil
            self.definition.x = nil
            self.definition.c = rhs or nil
            self.definition.t = rhs or nil
            self.definition.o = rhs or nil
        elseif rhs == false then
            self.definition.n = nil
            self.definition.i = nil
            self.definition.v = nil
            self.definition.s = nil
            self.definition.x = nil
            self.definition.c = nil
            self.definition.t = nil
            self.definition.o = nil
        else
            editor.notify("Could not enable All Modes for \"" .. self.name .. "\" because it does not have a single definition", vim.log.levels.ERROR)
        end
    end

    return self
end

function M:__band(other)
    local copy = self:copy()

    if other.name ~= copy.name then
        copy.name = copy.name .. " and " .. other.name
    end

    local definition = copy.definition

    while type(definition) == "table" and (definition["and"] or definition["or"]) do
        local condition = definition["and"] or definition["or"]

        if type(condition) ~= "table" then
            condition = { condition }

            if     definition["and"] then definition["and"] = condition
            elseif definition["or"]  then definition["or"]  = condition
            end
        end

        definition = condition
    end

    definition["and"] = other:copy().definition

    return copy
end

M.__add = M.__band

function M:__bor(other)
    local copy = self:copy()

    if other.name ~= copy.name then
        copy.name = copy.name .. " or " .. other.name
    end

    local definition = copy.definition

    while type(definition) == "table" and (definition["and"] or definition["or"]) do
        local condition = definition["and"] or definition["or"]

        if type(condition) ~= "table" then
            condition = { condition }

            if     definition["and"] then definition["and"] = condition
            elseif definition["or"]  then definition["or"]  = condition
            end
        end

        definition = condition
    end

    definition["or"] = other:copy().definition

    return copy
end

M.__div  = M.__bor
M.__idiv = M.__bor

local arrow_pattern = "[Aa][rR][rR][oO][wW]>"
local input_pattern = "<[Ii][nN][pP][uU][tT]>"
local buffer_pattern = "<[Bb][uU][fF][fF][eE][rR]>"

local function wrap_rhs(lhs, rhs, opts, definition, arrow)
    if not rhs or not definition then
        return rhs
    end

    if type(rhs) == "function" then
        local args = { }

        if definition.input then
            table.insert(args, lhs)
        end

        if definition.arrow then
            table.insert(args, arrow or lhs:match("[-<](%a+)>"))
        end

        if definition.buffer then
            table.insert(args, opts.buffer)
        end

        return function() return rhs(unpack(args)) end
    end

    if definition.input then
        rhs = rhs:gsub(input_pattern, lhs)
    end

    if definition.arrow then
        rhs = rhs:gsub(arrow_pattern, arrow or lhs:match("[-<](%a+)>") .. ">")
    end

    if definition.buffer then
        rhs = rhs:gsub(buffer_pattern, tostring(opts.buffer or 0))
    end

    return rhs
end

local function expand_arrow(action, mode, lhs, rhs, opts, definition)
    if lhs:find(arrow_pattern) then
        local left  = lhs:gsub(arrow_pattern, "Left>")
        local up    = lhs:gsub(arrow_pattern, "Up>")
        local right = lhs:gsub(arrow_pattern, "Right>")
        local down  = lhs:gsub(arrow_pattern, "Down>")

        action(mode, left,  wrap_rhs(left,  rhs, opts, definition, "Left"),  opts)
        action(mode, up,    wrap_rhs(up,    rhs, opts, definition, "Up"),    opts)
        action(mode, right, wrap_rhs(right, rhs, opts, definition, "Right"), opts)
        action(mode, down,  wrap_rhs(down,  rhs, opts, definition, "Down"),  opts)
    else
        action(mode, lhs, wrap_rhs(lhs, rhs, opts, definition), opts)
    end
end

local function do_nothing()
    return false
end

local function as_func(rhs)
    if type(rhs) == "string" then
        return function() editor.send(rhs) end
    end

    return rhs or do_nothing
end

local function unwrap_modes(func)
    return function(mode, lhs, rhs, opts)
        if type(mode) == "table" then
            for _, submode in pairs(mode) do
                func(submode, lhs, rhs, opts)
            end
        else
            func(mode, lhs, rhs, opts)
        end
    end
end

local function parse(name, definition, key, action, context)
    local contextless = context == nil

    if type(definition) == "table" then
        local ands = { }
        local ors = { }
        local modeless = false

        if definition["and"] then
            modeless = type(definition["and"]) == "table" and (definition["and"].modeless or (type(definition["and"].linked) == "table" and definition["and"].linked.modeless))

            context = context or { }

            parse(name, definition["and"], key, unwrap_modes(function(mode, lhs, rhs, opts)
                ands[mode] = as_func(rhs)
            end), context)
        end

        if definition["or"] then
            modeless = type(definition["or"]) == "table" and (definition["or"].modeless or (type(definition["or"].linked) == "table" and definition["or"].linked.modeless))

            context = context or { }

            parse(name, definition["or"], key, unwrap_modes(function(mode, lhs, rhs, opts)
                ors[mode] = as_func(rhs)
            end), context)
        end

        local map_mode_action = unwrap_modes(function(mode, lhs, rhs, opts)
            local and_command = ands[mode]
            local or_command  = ors[mode]

            if and_command then
                local modeless = (modeless and not rhs) or (context.modeless and context.modeless[mode] or false)

                context.modeless = context.modeless or { }
                context.modeless[mode] = modeless

                if rhs then
                    local capture_rhs = as_func(rhs)
                    rhs = function() return capture_rhs() ~= false and and_command() ~= false end
                elseif not contextless or not (context.modeless and context.modeless[mode]) then
                    rhs = and_command
                end
            end

            if or_command then
                local modeless = (modeless and not rhs) or (context.modeless and context.modeless[mode] or false)

                context.modeless = context.modeless or { }
                context.modeless[mode] = modeless

                if rhs then
                    local capture_rhs = as_func(rhs)
                    rhs = function() return capture_rhs() ~= false or or_command() ~= false end
                elseif not contextless or not (context.modeless and context.modeless[mode]) then
                    rhs = or_command
                end
            end

            if type(rhs) == "function" then
                local capture_rhs = rhs
                rhs = function()
                    if capture_rhs() == false then
                        editor.notify("Command '" .. name .. "' is not available", vim.log.levels.WARN)
                    end
                end
            end

            if rhs then
                action(mode, lhs, rhs, opts)
            end
        end)

        if definition.linked then
            definition = definition.linked

            if type(definition) ~= "table" then
                definition = { definition }
            end
        end

        local function map_mode(mode, default)
            local has_rhs = (definition[1] and ((default and definition[mode] ~= false) or (not default and definition[mode]))) or
                            (not definition[1] and (not definition[1] and definition[mode]))

            local rhs = has_rhs and (definition[1] or definition[mode])

            if not has_rhs then
                if mode == "v" then
                    local has_x_rhs = (definition[1] and definition["x"]) or
                                      (not definition[1] and (not definition[1] and definition["x"]))
                    local has_s_rhs = (definition[1] and definition["s"]) or
                                      (not definition[1] and (not definition[1] and definition["s"]))
                    if has_x_rhs or has_s_rhs then
                        local rhs_x = has_x_rhs and as_func(definition[1] or definition["x"])
                        local rhs_s = has_s_rhs and as_func(definition[1] or definition["s"])

                        rhs = function()
                            if rhs_s then return rhs_s() ~= false end
                            if rhs_x then return rhs_x() ~= false end

                            return false
                        end
                    end
                elseif mode == "s" then
                    local has_v_rhs = (definition[1] and definition["v"] ~= false) or
                                      (not definition[1] and (not definition[1] and definition["v"]))
                    if has_v_rhs and not contextless then
                        rhs = has_v_rhs and as_func(definition[1] or definition["v"])

                        if rhs then
                            local capture_rhs = as_func(rhs)
                            rhs = function() editor.send("<C-G>") return capture_rhs() ~= false end
                        end
                    elseif contextless then
                        return
                    end
                elseif mode == "x" then
                    local has_v_rhs = (definition[1] and definition["v"] ~= false) or
                                      (not definition[1] and (not definition[1] and definition["v"]))
                    if has_v_rhs and not contextless then
                        rhs = has_v_rhs and as_func(definition[1] or definition["v"])
                    elseif contextless then
                        return
                    end
                end
            end

            expand_arrow(map_mode_action, mode, key, rhs, { desc = name }, definition)
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
        expand_arrow(action, { "n", "i", "v" }, key, definition, { desc = name })
    end
end

function M:__call(key)
    -- TODO: Optimize this
    local mapmode = editor.mapmode()

    parse(self.name, self.definition, key or "<Nop>", function(mode, lhs, rhs, opts)
        vim.keymap.set(mode, lhs, rhs, opts)
        if mode == mapmode or (mode == "v" and (mapmode == "s" or mapmode == "x")) then
            if type(rhs) == "function" then rhs()
            else                            editor.send(rhs)
            end
        end
    end)
end

-- TODO: Allow specifying buffer
function M:map(keys, callback)
    if type(keys) == "string" then
        keys = { keys }
    end

    if not keys or #keys == 0 then
        return
    end

    for _, key in pairs(keys) do
        parse(self.name, self.definition, key, function(mode, lhs, rhs, opts)
            vim.keymap.set(mode, lhs, rhs, opts)

            if callback then
                callback(mode, lhs, rhs, opts)
            end
        end)
    end
end

-- TODO: Allow specifying buffer
function M:unmap(keys, callback)
    if type(keys) == "string" then
        keys = { keys }
    end

    if not keys or #keys == 0 then
        return
    end

    for _, key in pairs(keys) do
        parse(self.name, self.definition, key, function(mode, lhs, rhs, opts)
            vim.keymap.del(mode, lhs, opts)

            if callback then
                callback(mode, lhs, rhs, opts)
            end
        end)
    end
end

function M:menu(parent, position)
    if not self.plug then
        -- TODO: Add to health check issues instead
        editor.notify("Menu command '" .. self.name .. "' was not registered with sacrilege.cmd", vim.log.levels.WARN)

        return { enable = do_nothing, disable = do_nothing, update = do_nothing, delete = do_nothing }
    end

    local name  = parent:gsub(" ", "\\ "):gsub("%.", "\\.") .. "." .. self.name:gsub(" ", "\\ "):gsub("%.", "\\.")
    local modes = { }

    parse(self.name, self.definition, "<Nop>", unwrap_modes(function(mode, lhs, rhs, opts)
        if mode ~= "t" then
            table.insert(modes, mode)
        end
    end))

    local menu =
    {
        create = function()
            for _, mode in pairs(modes) do
                vim.cmd(mode .. "menu " .. (position or "") .. " " .. name .. " " .. self.plug)
            end
        end,
        enable = function()
            for _, mode in pairs(modes) do
                vim.cmd(mode .. "menu enable " .. name)
            end
        end,
        disable = function()
            for _, mode in pairs(modes) do
                vim.cmd(mode .. "menu disable " .. name)
            end
        end,
        update = function(mode)
            if mode == "s" or mode == "x" and vim.tbl_contains(modes, "v") then
                mode = "v"
            elseif not vim.tbl_contains(modes, mode) then
                return
            end

            if vim.fn.maparg(self.plug, mode) ~= "" then
                vim.cmd(mode .. "menu enable " .. name)
            else
                vim.cmd(mode .. "menu disable " .. name)
            end
        end,
        delete = function()
            for _, mode in pairs(modes) do
                vim.cmd(mode .. "unmenu " .. name)
            end
        end
    }

    menu.create()

    return menu
end

return M
