local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local command = require("sacrilege.command")

    options.commands.secret = options.commands.secret or { }
    options.commands.secret.smile = command.new("Smile", "<Cmd>smile<CR>")
    options.commands.secret.panic = command.new("Help!", "<C-\\><C-N>:help!<CR>")
    options.commands.secret.holygrail = command.new("Find Holy Grail", "<Cmd>help holy-grail<CR>")
    options.commands.secret["42"] = command.new("42", "<Cmd>help 42<CR>")
end

return M
