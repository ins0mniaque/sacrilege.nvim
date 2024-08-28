local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local conform = plugin.new("stevearc/conform.nvim", "conform")

    options.commands.format:override(conform:try(function(conform) conform.format({ async = true, lsp_fallback = true }) end)):visual(false)
end

function M.autodetect()
    return pcall(require, "conform") and true or false
end

return M
