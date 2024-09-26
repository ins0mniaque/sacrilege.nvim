local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local neogit = plugin.new("NeogitOrg/neogit", "neogit")

    options.commands.source_control:override(neogit:try("<Cmd>Neogit<CR>"))
end

function M.autodetect()
    return pcall(require, "neogit") and true or false
end

return M
