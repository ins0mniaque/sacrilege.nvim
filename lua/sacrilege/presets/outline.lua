local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local outline = plugin.new("hedyhli/outline.nvim", "outline")

    options.commands.code_outline:override(outline:try("<Cmd>Outline<CR>"))
end

function M.autodetect()
    return pcall(require, "outline") and true or false
end

return M
