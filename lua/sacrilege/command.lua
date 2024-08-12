local editor = require("sacrilege.editor")

local M = { }

M.__index = M

function M.new(name, definition)
    local self = { }

    self.name       = name
    self.definition = definition

    return setmetatable(self, M)
end

function M.is(command)
    return command.__index == M
end

function M:clone(name)
    return M.new(self.name or name, vim.tbl_deep_extend("force", { }, self.definition))
end

function M:named(name)
    self.name = name

    return self
end

function M:__band(other)
    local cloned = self:clone()
    local definition = cloned.definition

    if type(definition) ~= "table" then
        definition = { definition }
    end

    while definition["and"] or definition["or"] do
        local condition = definition["and"] or definition["or"]

        if condition and type(condition) ~= "table" then
            condition = { condition }

            if definition["and"] then definition["and"] = condition
            else                      definition["or"]  = condition
            end
        end

        definition = condition
    end

    definition["and"] = type(other.definition) == "table" and vim.tbl_deep_extend("force", { }, other.definition) or other.definition

    return cloned
end

M.__add    = M.__band
M.__concat = M.__band

function M:__bor(other)
    local cloned = self:clone()
    local definition = cloned.definition

    if type(definition) ~= "table" then
        definition = { definition }
    end

    while definition["and"] or definition["or"] do
        local condition = definition["and"] or definition["or"]

        if condition and type(condition) ~= "table" then
            condition = { condition }

            if definition["and"] then definition["and"] = condition
            else                      definition["or"]  = condition
            end
        end

        definition = condition
    end

    definition["or"] = type(other.definition) == "table" and vim.tbl_deep_extend("force", { }, other.definition) or other.definition

    return cloned
end

M.__div  = M.__bor
M.__idiv = M.__band

local arrow_pattern = "[Aa][rR][rR][oO][wW]>"
local input_pattern = "<[Ii][nN][pP][uU][tT]>"
local buffer_pattern = "<[Bb][uU][fF][fF][eE][rR]>"

local function wrap(lhs, rhs, opts, definition, arrow)
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

local function parse(action, mode, lhs, rhs, opts, definition)
    if definition and definition.arrow and lhs:find(arrow_pattern) then
        local left  = lhs:gsub(arrow_pattern, "Left>")
        local up    = lhs:gsub(arrow_pattern, "Up>")
        local right = lhs:gsub(arrow_pattern, "Right>")
        local down  = lhs:gsub(arrow_pattern, "Down>")

        action(mode, left,  wrap(left,  rhs, opts, definition, "Left"),  opts)
        action(mode, up,    wrap(up,    rhs, opts, definition, "Up"),    opts)
        action(mode, right, wrap(right, rhs, opts, definition, "Right"), opts)
        action(mode, down,  wrap(down,  rhs, opts, definition, "Down"),  opts)
    else
        action(mode, lhs, wrap(lhs, rhs, opts, definition), opts)
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

-- TODO: Allow specifying buffer
-- TODO: Localizer
local function map(name, definition, keys, action)
    if type(definition) == "table" then
        local ands = { }
        local ors = { }

        if definition["and"] then
            map(name, definition["and"], keys, unwrap_modes(function(mode, lhs, rhs, opts)
                ands[mode] = as_func(rhs)
            end))
        end

        if definition["or"] then
            map(name, definition["or"], keys, unwrap_modes(function(mode, lhs, rhs, opts)
                ors[mode] = as_func(rhs)
            end))
        end

        -- TODO: Fix problem when parent/child mode don't match
        local map_mode_action = unwrap_modes(function(mode, lhs, rhs, opts)
            local and_command = ands[mode]
            local or_command = ors[mode]

            if and_command then
                local capture_rhs = as_func(rhs)
                rhs = function() return capture_rhs() ~= false and and_command() ~= false end
            end

            if or_command then
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

        local function map_mode(mode, default)
            local has_rhs = (definition[1] and ((default and definition[mode] ~= false) or (not default and definition[mode]))) or (not definition[1] and (not definition[1] and definition[mode]))
            local rhs     = has_rhs and (definition[1] or definition[mode])

            for _, key in pairs(keys) do
                parse(map_mode_action, mode, key, rhs, { desc = name }, definition)
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
        for _, key in pairs(keys) do
            parse(action, { "n", "i", "v" }, key, definition, { desc = name })
        end
    end
end

function M:map(keys, callback)
    if type(keys) == "string" then
        keys = { keys }
    end

    if not keys or #keys == 0 then
        return
    end

    map(self.name, self.definition, keys, function(mode, lhs, rhs, opts)
        vim.keymap.set(mode, lhs, rhs, opts)

        if callback then
            callback(mode, lhs, rhs, opts)
        end
    end)
end

function M:unmap(keys, callback)
    if type(keys) == "string" then
        keys = { keys }
    end

    if not keys or #keys == 0 then
        return
    end

    map(self.name, self.definition, keys, function(mode, lhs, rhs, opts)
        vim.keymap.del(mode, lhs, opts)

        if callback then
            callback(mode, lhs, rhs, opts)
        end
    end)
end

return M
