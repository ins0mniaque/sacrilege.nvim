local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local trouble = plugin.new("folke/trouble.nvim", "trouble")

    options.commands.diagnostics:override(trouble:try("<Cmd>Trouble diagnostics toggle<CR>"))
end

function M.autodetect()
    return pcall(require, "trouble") and true or false
end

return M
