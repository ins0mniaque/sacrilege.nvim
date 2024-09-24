local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local codecompanion = plugin.new("olimorris/codecompanion.nvim", "codecompanion")

    options.commands.ai_chat:override(codecompanion:try("<Cmd>CodeCompanionToggle<CR>"))
    options.commands.ai_prompt:override(codecompanion:try("<Cmd>CodeCompanion<CR>"))
end

function M.autodetect()
    return pcall(require, "codecompanion") and true or false
end

return M
