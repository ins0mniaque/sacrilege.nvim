local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local grug = plugin.new("MagicDuck/grug-far.nvim", "grug-far")

    options.commands.replace_in_files:override(grug:try(function(grug) grug.open() end))
end

function M.autodetect()
    return pcall(require, "grug-far") and true or false
end

return M
