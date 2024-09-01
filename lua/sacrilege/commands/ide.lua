local command = require("sacrilege.command")
local ui = require("sacrilege.ui")

local M = { }

local function not_implemented()
    return false
end

M.command_palette = command.new("Command Palette...", ui.command_palette):cmdline(true)
M.command_palette_local = command.new("Local Command Palette...", function() ui.command_palette(0) end):cmdline(true)
M.themes = command.new("Themes...", ui.themes):cmdline(true)
M.file_explorer = command.new("Toggle File Explorer", not_implemented):cmdline(true)
M.code_outline = command.new("Toggle Code Outline", not_implemented):cmdline(true)
M.undo_history = command.new("Toggle Undo History", not_implemented):cmdline(true)

M.compilers = command.new("Compilers...", ui.compilers):cmdline(true)
M.build = command.new("Build", "<Cmd>make<CR>")
M.rebuild = command.new("Rebuild", "<Cmd>make clean<CR><Cmd>make<CR>")
M.run = command.new("Run", "<Cmd>make run<CR>")
M.clean = command.new("Clean", "<Cmd>make clean<CR>")

M.debugger = command.new("Toggle Debugger", not_implemented):cmdline(true)
M.continue = command.new("Start Debugging / Continue", not_implemented)
M.step_into = command.new("Step Into", not_implemented)
M.step_over = command.new("Step Over", not_implemented)
M.step_out = command.new("Step Out", not_implemented)
M.breakpoint = command.new("Toggle Breakpoint", not_implemented)
M.conditional_breakpoint = command.new("Set Conditional Breakpoint", not_implemented)

M.test_explorer = command.new("Test Explorer", not_implemented):cmdline(true)
M.test_output = command.new("Test Output", not_implemented):cmdline(true)
M.run_test = command.new("Run Test", not_implemented)
M.run_all_tests = command.new("Run All Tests", "<Cmd>make check<CR>")
M.debug_test = command.new("Debug Test", not_implemented)
M.stop_test = command.new("Stop Test", not_implemented)
M.attach_test = command.new("Attach Test", not_implemented)

return M
