local editor = require("sacrilege.editor")

local M = { }

M.__index = M

function M.is(command)
    return type(command) == "table" and command.__index == M
end

function M.new(name, definition)
    local self = { }

    self.name       = name
    self.definition = definition

    return setmetatable(self, M)
end

-- TODO: This is wrong...
function M:copy(name)
    local definition = { linked = type(self.definition) == "table" and self.definition.linked or self.definition }

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

M.__add    = M.__band
M.__concat = M.__band

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

local function parse(name, definition, key, action)
    if type(definition) == "table" then
        local ands = { }
        local ors = { }
        local modeless = false

        if definition["and"] then
            modeless = type(definition["and"]) == "table" and (definition["and"].modeless or (type(definition["and"].linked) == "table" and definition["and"].linked.modeless))

            parse(name, definition["and"], key, unwrap_modes(function(mode, lhs, rhs, opts)
                ands[mode] = as_func(rhs)
            end))
        end

        if definition["or"] then
            modeless = type(definition["or"]) == "table" and (definition["or"].modeless or (type(definition["or"].linked) == "table" and definition["or"].linked.modeless))

            parse(name, definition["or"], key, unwrap_modes(function(mode, lhs, rhs, opts)
                ors[mode] = as_func(rhs)
            end))
        end

        local map_mode_action = unwrap_modes(function(mode, lhs, rhs, opts)
            local and_command = ands[mode]
            local or_command = ors[mode]

            if and_command and (not modeless or rhs) then
                local capture_rhs = as_func(rhs)
                rhs = function() return capture_rhs() ~= false and and_command() ~= false end
            end

            if or_command and (not modeless or rhs) then
                local capture_rhs = as_func(rhs)
                rhs = function() return capture_rhs() ~= false or or_command() ~= false end
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
