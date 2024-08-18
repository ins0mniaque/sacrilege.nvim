local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local tree = plugin.new("nvim-tree/nvim-tree.lua", "nvim-tree")

    options.commands.file_explorer:override(tree:try("<Cmd>NvimTreeToggle<CR>"))
end

return M
