local editor = require("sacrilege.editor")

local M = { }

local engines = { }

function M.setup(opts)
    engines = vim.tbl_deep_extend("force", engines, opts or { })
end

-- local native_modes =
-- {
--     ["<C-N>"] = "keyword",
--     ["<C-L>"] = "whole_line",
--     ["<C-F>"] = "files",
--     ["<C-]>"] = "tags",
--     ["<C-D>"] = "path_defines",
--     ["<C-I>"] = "path_patterns",
--     ["<C-K>"] = "dictionary",
--     ["<C-T>"] = "thesaurus",
--     ["<C-V>"] = "cmdline",
--     ["<C-U>"] = "function",
--     ["<C-O>"] = "omni",
--     ["s"]     = "spell"
-- }

function M.native(key)
    local function visible()
        -- TODO: Check for mode, but vim.fn.complete_info is not always available
        --       i.e. vim.fn.complete_info({ "mode" }).mode == native_modes[key]
        return vim.fn.pumvisible() == 1
    end

    return
    {
        visible = visible,

        abort = function()
            if not visible() then
                return false
            end

            editor.send("<C-E>")

            return true
        end,

        trigger = function()
            if not visible() then
                editor.send("<C-X>" .. key)
            end

            return true
        end,

        confirm = function(opts)
            if not visible() then
                return false
            end

            local selected = vim.fn.complete_info({ "selected" }).selected ~= -1

            if opts and opts.select and not selected then
                editor.send("<C-N>")
                selected = true
            end

            if selected then
                editor.send("<C-Y>")
            else
                editor.send("<C-X>")
            end

            return selected
        end,

        select = function(direction)
            if not visible() then
                return false
            end

            if direction == -1 then
                return editor.send("<C-P>")
            elseif direction == 1 then
                return editor.send("<C-N>")
            end

            return false
        end
    }
end

function M.what()
    local line

    return setmetatable({ },
    {
        __index = function(table, key)

            line = line or string.sub(vim.fn.getline("."), 1, vim.fn.getpos(".")[3] - 1)

            if key == "line" then
                rawset(table, "line", line:match("^%s*(.-)%s*$"))
            elseif key == "keyword" then
                rawset(table, "keyword", line:sub(vim.fn.match(line, "\\k*$", -1) + 1))
            elseif key == "char" then
                rawset(table, "char", line:sub(-1))
            end

            return rawget(table, key)
        end
    })
end

function M.resolve(name)
    local engine = engines[name]

    local what
    local loop = 0
    while loop < 32 and type(engine) == "function" do
        what = what or M.what()
        engine = engines[engine(what)]
        loop = loop + 1
    end

    if loop >= 32 then
        local looped = { name }
        local loop_done = false
        loop = 0

        while loop < 32 and not loop_done and type(engine) == "function" do
            local engine_name = engine(what)
            loop_done = vim.tbl_contains(looped, engine_name)
            table.insert(looped, engine_name)
            engine = engines[engine_name]
            loop = loop + 1
        end

        editor.notify("Completion loop detected for \"" .. name .. "\": " .. table.concat(looped, " => "), vim.log.levels.WARN)

        return nil
    end

    return engine
end

function M.visible()
    for _, engine in pairs(engines) do
        if type(engine) == "table" and engine.visible and engine.visible() then
            return engine
        end
    end

    return nil
end

function M.abort()
    for _, engine in pairs(engines) do
        if type(engine) == "table" and engine.abort and engine.visible and engine.visible() then
            return engine.abort() ~= false
        end
    end

    return false
end

function M.trigger()
    local default = M.resolve("default")

    if type(default) == "table" and default.trigger and default.visible and not default.visible() then
        return default.trigger() ~= false
    end

    for _, engine in pairs(engines) do
        if type(engine) == "table" and engine.trigger and engine.visible and not engine.visible() then
            return engine.trigger() ~= false
        end
    end

    return false
end

function M.confirm(opts)
    for _, engine in pairs(engines) do
        if type(engine) == "table" and engine.confirm and engine.visible and engine.visible() then
            return engine.confirm(opts) ~= false
        end
    end

    return false
end

function M.select(direction)
    for _, engine in pairs(engines) do
        if type(engine) == "table" and engine.select and engine.visible and engine.visible() then
            return engine.select(direction) ~= false
        end
    end

    return false
end

return M
