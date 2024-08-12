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
    while definition["and"] do
        definition = definition["and"]
    end

    definition["and"] = vim.tbl_deep_extend("force", { }, other.definition)

    return cloned
end

M.__add    = M.__band
M.__concat = M.__band

function M:__bor(other)
    local cloned = self:clone()
    local definition = cloned.definition
    while definition["or"] do
        definition = definition["or"]
    end

    definition["or"] = vim.tbl_deep_extend("force", { }, other.definition)

    return cloned
end

M.__div  = M.__bor
M.__idiv = M.__band


local arrow_pattern = "[Aa][rR][rR][oO][wW]>"
local input_pattern = "<[Ii][nN][pP][uU][tT]>"
local buffer_pattern = "<[Bb][uU][fF][fF][eE][rR]>"

local function wrap(lhs, rhs, opts, definition, arrow)
    if not definition then
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
        local conditional = false

        if definition["and"] then
            map(name, definition["and"], keys, unwrap_modes(function(mode, lhs, rhs, opts)
                ands[mode] = rhs
                conditional = true
            end))
        end

        if definition["or"] then
            map(name, definition["or"], keys, unwrap_modes(function(mode, lhs, rhs, opts)
                ors[mode] = rhs
                conditional = true
            end))
        end

        local map_mode_action = action

        if conditional then
            map_mode_action = unwrap_modes(function(mode, lhs, rhs, opts)
                local and_command = ands[mode]
                local or_command = ors[mode]

                if and_command then
                    local capture_rhs = rhs
                    rhs = function() return capture_rhs() and and_command() end
                end

                if or_command then
                    local capture_rhs = rhs
                    rhs = function() return capture_rhs() or or_command() end
                end

                action(mode, lhs, rhs, opts)
            end)
        end

        local function map_mode(mode, default)
            if (definition[1] and ((default and definition[mode] ~= false) or (not default and definition[mode]))) or (not definition[1] and definition[mode]) then
                for _, key in pairs(keys) do
                    parse(map_mode_action, mode, key, definition[1] or definition[mode], { desc = name }, definition)
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

return M
