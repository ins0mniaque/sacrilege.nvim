local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local undotree = plugin.vim("mbbill/undotree", M.autodetect)

    options.commands.undo_history:override(undotree:try("<Cmd>UndotreeToggle<CR>"))
end

function M.autodetect()
    return vim.g.loaded_undotree == 1
end

return M
