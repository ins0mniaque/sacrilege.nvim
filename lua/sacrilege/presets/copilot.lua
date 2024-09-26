local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local copilot = plugin.new("github/copilot.vim", M.autodetect)

    options.commands.ai_chat:override(copilot:try("<Cmd>Copilot<CR>"))
    options.commands.ai_prompt:override(copilot:try("<Cmd>Copilot<CR>"))
end

function M.autodetect()
    return vim.g.loaded_copilot == 1
end

return M
