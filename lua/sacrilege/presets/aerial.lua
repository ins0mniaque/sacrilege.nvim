local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local aerial = plugin.new("stevearc/aerial.nvim", "aerial")

    options.commands.code_outline:override(aerial:try("<Cmd>AerialToggle<CR>"))
end

function M.autodetect()
    return pcall(require, "aerial") and true or false
end

return M
