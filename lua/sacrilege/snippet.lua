local M = { }

local engines = { }

function M.setup(opts)
    engines = vim.tbl_deep_extend("force", engines, opts or { })
end

function M.active(opts)
    for _, engine in pairs(engines) do
        if engine and engine.active and engine.active(opts) then
            return engine
        end
    end

    return nil
end

function M.jump(direction)
    for _, engine in pairs(engines) do
        if engine and engine.jump and engine.active and engine.active({ direction = direction }) then
            engine.jump(direction)

            return true
        end
    end

    return false
end

function M.stop()
    for _, engine in pairs(engines) do
        if engine and engine.stop and engine.active and engine.active() then
            engine.stop()

            return true
        end
    end

    return false
end

return M
