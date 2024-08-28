local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")
    local ui = require("sacrilege.ui")

    local dap = plugin.new("mfussenegger/nvim-dap", "dap")

    options.commands.continue:override(dap:try(function(dap) dap.continue() end))
    options.commands.step_into:override(dap:try(function(dap) dap.step_into() end))
    options.commands.step_over:override(dap:try(function(dap) dap.step_over() end))
    options.commands.step_out:override(dap:try(function(dap) dap.step_out() end))
    options.commands.breakpoint:override(dap:try(function(dap) dap.toggle_breakpoint() end))
    options.commands.conditional_breakpoint:override(dap:try(function(dap) ui.input("Breakpoint condition: ", dap.set_breakpoint) end))
end

function M.autodetect()
    return pcall(require, "dap") and true or false
end

return M
