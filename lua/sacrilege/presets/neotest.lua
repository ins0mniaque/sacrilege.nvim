local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local neotest = plugin.new("nvim-neotest/neotest", "neotest")

    options.commands.test_explorer:override(neotest:try(function(neotest) neotest.summary.toggle() end))
    options.commands.test_output:override(neotest:try(function(neotest) neotest.output_panel.toggle() end))
    options.commands.run_test:override(neotest:try(function(neotest) neotest.run.run() end))
    options.commands.run_all_tests:override(neotest:try(function(neotest) neotest.run.run(vim.fn.expand("%")) end))
    options.commands.debug_test:override(neotest:try(function(neotest) neotest.run.run({ strategy = "dap" }) end))
    options.commands.stop_test:override(neotest:try(function(neotest) neotest.run.stop() end))
    options.commands.attach_test:override(neotest:try(function(neotest) neotest.run.attach() end))
end

function M.autodetect()
    return pcall(require, "neotest") and true or false
end

return M
