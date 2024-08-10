local M = { }

M.__index = M

function M.new(name, definition)
    local self = { }

    self.name       = name
    self.definition = definition

    return setmetatable(self, M)
end

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

        return function() rhs(unpack(args)) end
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

function M:map(keys, context, mappings)
    if type(keys) == "string" then
        keys = { keys }
    end

    if not keys or #keys == 0 then
        return
    end

    local action = vim.keymap.set

    if mappings then
        action = function(mode, lhs, rhs, opts)
            vim.keymap.set(mode, lhs, rhs, opts)

            table.insert(mappings, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
        end
    end

    local definition = self.definition

    if type(definition) == "table" then
        if type(definition[1]) == "table" then
            local found = nil
            for _, subdefinition in pairs(definition) do
                if not found and (not subdefinition.condition or subdefinition.condition(context)) then
                    found = subdefinition
                end
            end

            definition = found
        elseif definition.condition and not definition.condition(context) then
            definition = nil
        end

        if definition then
            local function map_mode(mode, default)
                if (definition[1] and ((default and definition[mode] ~= false) or (not default and definition[mode]))) or (not definition[1] and definition[mode]) then
                    for _, key in pairs(keys) do
                        parse(action, mode, key, definition[1] or definition[mode], { buffer = buffer, desc = self.name }, definition)
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
        end
    elseif definition then
        for _, key in pairs(keys) do
            parse(action, { "n", "i", "v" }, key, definition, { buffer = context.buffer, desc = self.name })
        end
    end
end

return M
