local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local gp = plugin.new("Robitx/gp.nvim", "gp")

    options.commands.ai_chat:override(gp:try("<Cmd>GpChatToggle<CR>"))
    options.commands.ai_prompt:override(gp:try("<Cmd>GpChatToggle popup<CR>"))
end

function M.autodetect()
    return pcall(require, "gp") and true or false
end

return M
