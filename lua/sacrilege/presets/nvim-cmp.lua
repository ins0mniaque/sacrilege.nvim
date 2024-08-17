local M = { }

function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local cmp = plugin.new("hrsh7th/nvim-cmp", "cmp")

    options.completion = options.completion or { }
    options.completion.trigger = cmp:try(function(cmp) return cmp.complete() end)
    options.completion.cmp =
    {
        visible = cmp:try(function(cmp) return cmp.visible() end),
        abort = cmp:try(function(cmp) return cmp.abort() end),
        confirm = cmp:try(function(cmp, opts) return cmp.confirm(opts) end),
        select = cmp:try(function(cmp, direction)
            if direction == -1 then
                return cmp.select_prev_item()
            elseif direction == 1 then
                return cmp.select_next_item()
            end

            return false
        end)
    }
end

return M
