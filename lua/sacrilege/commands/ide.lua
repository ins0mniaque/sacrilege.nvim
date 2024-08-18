local command = require("sacrilege.command")
local ui = require("sacrilege.ui")
local plugin = require("sacrilege.plugin")

local M = { }

local dap     = plugin.new("mfussenegger/nvim-dap", "dap")
local neotest = plugin.new("nvim-neotest/neotest", "neotest")

local function not_implemented()
    return false
end

M.command_palette = command.new("Command Palette...", ui.command_palette):cmdline(true)
M.file_explorer = command.new("Toggle File Explorer", not_implemented):cmdline(true)
M.code_outline = command.new("Toggle Code Outline", not_implemented):cmdline(true)
M.debugger = command.new("Toggle Debugger", not_implemented):cmdline(true)

M.continue = command.new("Start Debugging / Continue", dap:try(function(dap) dap.continue() end))
M.step_into = command.new("Step Into", dap:try(function(dap) dap.step_into() end))
M.step_over = command.new("Step Over", dap:try(function(dap) dap.step_over() end))
M.step_out = command.new("Step Out", dap:try(function(dap) dap.step_out() end))
M.breakpoint = command.new("Toggle Breakpoint", dap:try(function(dap) dap.toggle_breakpoint() end))
M.conditional_breakpoint = command.new("Set Conditional Breakpoint", dap:try(function(dap) ui.input("Breakpoint condition: ", dap.set_breakpoint) end))

M.run_test = command.new("Run Test", neotest:try(function(neotest) neotest.run.run() end))
M.run_all_tests = command.new("Run All Tests", neotest:try(function(neotest) neotest.run.run(vim.fn.expand("%")) end))
M.debug_test = command.new("Debug Test", neotest:try(function(neotest) neotest.run.run({ strategy = "dap" }) end))
M.stop_test = command.new("Stop Test", neotest:try(function(neotest) neotest.run.stop() end))
M.attach_test = command.new("Attach Test", neotest:try(function(neotest) neotest.run.attach() end))

return M
