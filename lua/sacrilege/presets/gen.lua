local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local gen = plugin.new("David-Kunz/gen.nvim", "gen")

    options.commands.ai_chat:override(gen:try("<Cmd>Gen Chat<CR>"))
    options.commands.ai_prompt:override(gen:try("<Cmd>Gen<CR>"))
end

function M.autodetect()
    return pcall(require, "gen") and true or false
end

return M
