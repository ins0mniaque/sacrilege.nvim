local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local neotree = plugin.new("nvim-neo-tree/neo-tree.nvim", "neo-tree")

    options.commands.file_explorer:override(neotree:try("<Cmd>Neotree toggle<CR>"))
    options.commands.code_outline:override(neotree:try("<Cmd>Neotree document_symbols toggle<CR>"))
end

function M.autodetect()
    return pcall(require, "neo-tree") and true or false
end

return M
