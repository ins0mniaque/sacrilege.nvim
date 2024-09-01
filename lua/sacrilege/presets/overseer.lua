local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local overseer = plugin.new("stevearc/overseer.nvim", "overseer")
    local run_task = options.commands.run_task:clone():override(overseer:try("<Cmd>OverseerRun<CR>"))
                                                      :when(function() return vim.bo.makeprg == "" end)

    options.commands.run_task = run_task / options.commands.run_task
    options.commands.task_output:override(overseer:try("<Cmd>OverseerToggle<CR>"))

    require("sacrilege.ui").make = overseer:try(function(overseer, args, background)
        local cmd, subs = vim.bo.makeprg:gsub("%$%*", args or "")
        if subs == 0 then
            cmd = cmd .. " " .. (args or "")
        end

        local task = overseer.new_task
        {
            cmd = vim.fn.expandcmd(cmd),
            components =
            {
                { "on_output_quickfix", open = not background },
                "default"
            }
        }

        task:start()
    end)
end

function M.autodetect()
    return pcall(require, "overseer") and true or false
end

return M
