local M = { }

local engines = { }

function M.setup(opts)
    engines = vim.tbl_deep_extend("force", engines, opts or { })
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
            engine.abort()

            return true
        end
    end

    return false
end

function M.complete()
    if engines.default then
        local default = engines[engines.default]
        if default and default.complete and default.visible and not default.visible() then
            default.complete()

            return true
        end
    end

    for _, engine in pairs(engines) do
        if engine and engine.complete and engine.visible and not engine.visible() then
            engine.complete()

            return true
        end
    end

    return false
end

function M.confirm(opts)
    for _, engine in pairs(engines) do
        if engine and engine.confirm and engine.visible and engine.visible() then
            engine.confirm(opts)

            return true
        end
    end

    return false
end

function M.select(direction)
    for _, engine in pairs(engines) do
        if engine and engine.select and engine.visible and engine.visible() then
            engine.select(direction)

            return true
        end
    end

    return false
end

return M
