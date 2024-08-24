local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local dapui = plugin.new("rcarriga/nvim-dap-ui", "dapui")

    options.commands.debugger:override(dapui:try(function(dapui) dapui.toggle() end))
end

return M