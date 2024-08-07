local M = { }

local engines = { }

function M.setup(opts)
    engines = vim.tbl_deep_extend("force", engines, opts or { })
end

function M.native(key)
    local editor = require("sacrilege.editor")

    return
    {
        visible = function() return vim.fn.pumvisible() == 1 end,
        abort = function() editor.send("<C-E>") end,
        trigger = function() editor.send("<C-X>" .. key) end,
        confirm = function(opts)
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
            if direction == -1 then
                return editor.send("<C-P>")
            elseif direction == 1 then
                return editor.send("<C-N>")
            end

            return false
        end
    }
end

function M.visible()
    for _, engine in pairs(engines) do
        if engine and engine.visible and engine.visible() then
            return engine
        end
    end

    return nil
end

function M.abort()
    for _, engine in pairs(engines) do
        if engine and engine.abort and engine.visible and engine.visible() then
            return engine.abort() ~= false
        end
    end

    return false
end

function M.trigger()
    if engines.default then
        local default = engines[engines.default]
        if default and default.trigger and default.visible and not default.visible() then
            return default.trigger() ~= false
        end
    end

    for _, engine in pairs(engines) do
        if engine and engine.trigger and engine.visible and not engine.visible() then
            return engine.trigger() ~= false
        end
    end

    return false
end

function M.confirm(opts)
    for _, engine in pairs(engines) do
        if engine and engine.confirm and engine.visible and engine.visible() then
            return engine.confirm(opts) ~= false
        end
    end

    return false
end

function M.select(direction)
    for _, engine in pairs(engines) do
        if engine and engine.select and engine.visible and engine.visible() then
            return engine.select(direction) ~= false
        end
    end

    return false
end

return M
