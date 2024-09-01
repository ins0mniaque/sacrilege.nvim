local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local overseer = plugin.new("stevearc/overseer.nvim", "overseer")

    options.commands.run_task:override(overseer:try("<Cmd>OverseerRun<CR>"))
    options.commands.task_output:override(overseer:try("<Cmd>OverseerToggle<CR>"))
end

function M.autodetect()
    return pcall(require, "overseer") and true or false
end

return M
