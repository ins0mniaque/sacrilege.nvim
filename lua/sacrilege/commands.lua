local sacrilege = require("sacrilege")
local command = require("sacrilege.command")
local editor = require("sacrilege.editor")
local completion = require("sacrilege.completion")
local snippet = require("sacrilege.snippet")
local autopair = require("sacrilege.autopair")
local blockmode = require("sacrilege.blockmode")
local ui = require("sacrilege.ui")
local plugin = require("sacrilege.plugin")

local M = { treesitter = { }, lsp = { } }

local dap     = plugin.new("mfussenegger/nvim-dap", "dap")
local neotest = plugin.new("nvim-neotest/neotest", "neotest")
local methods = vim.lsp.protocol.Methods

local function select_command(rhs)
    return function(arrow)
        local keys = rhs:gsub("[Aa][rR][rR][oO][wW]>", arrow .. ">")

        editor.send(keys)

        -- HACK: Fix cursor column for subsequent cursor moves
        vim.defer_fn(function()
            editor.send("<Right><Left>")
        end, 0)
    end
end


local function arrow_command(rhs, block_rhs)
    return function(arrow)
        local mode = vim.fn.mode()
        local keys = mode == "\19" or mode == "\22" and block_rhs or rhs

        keys = keys:gsub("[Aa][rR][rR][oO][wW]>", arrow .. ">")

        editor.send(keys)
    end
end

local function completion_command(rhs)
    return { function(lhs) if not rhs() then editor.send(lhs) end end, input = true, n = false, v = false, c = true }
end

local function snippet_command(rhs)
    return { v = function(lhs) if not rhs() then editor.send(lhs) end end, input = true }
end

local function popup_command(rhs)
    return function() if not editor.try_close_popup() then rhs() end end
end

local function paste(register)
    return function()
        local mode = vim.fn.mode()

        if mode == "\19" or mode == "\22" then
            blockmode.paste(register)
        elseif mode == "s" or mode == "S" then
            editor.send("\"_d\"" .. register .. "P")
        else
            editor.send("<C-G>\"_d\"" .. register .. "P")
        end
    end
end

local function ts_condition(method)
    return function(context) return context and context.buffer and not editor.supports_lsp_method(context.buffer, method) end
end

local function lsp_condition(method)
    return function(context) return context and context.client and context.client.supports_method(method) end
end

M.escape = command.new("Escape", { sacrilege.escape, n = false, c = true })
M.interrupt = command.new("Interrupt", { sacrilege.interrupt, v = false, c = true })
M.tab = command.new("Indent / Snippet Jump Next", { sacrilege.tab, n = false, c = true })
M.shifttab = command.new("Unindent / Snippet Jump Previous", { sacrilege.shifttab, n = false })
M.up = command.new("Up / Select Previous Completion", { sacrilege.up, n = false, c = true })
M.down = command.new("Down / Select Next Completion", { sacrilege.down, n = false, c = true })
M.left = command.new("Left / Wild Menu Left", { c = function() editor.send(vim.fn.pumvisible() == 1 and "<C-Y><Left>" or "<Left>") end })
M.right = command.new("Right / Wild Menu Right", { c = function() editor.send(vim.fn.pumvisible() == 1 and "<C-Y><Right>" or "<Right>") end })
M.popup = command.new("Popup Menu", { s = "<C-\\><C-G>gv<Cmd>:popup! PopUp<CR>" })

M.command_palette = command.new("Command Palette...", { ui.command_palette, c = true })
M.cmdline = command.new("Command Line Mode", "<Esc>:")
M.terminal = command.new("Terminal", { vim.cmd.terminal, c = true })
M.diagnostics = command.new("Toggle Diagnostics", { vim.diagnostic.setloclist, c = true })
M.diagnostic = command.new("Toggle Diagnostic Popup", popup_command(function() vim.diagnostic.open_float({ scope = 'cursor', focus = false }) end))
M.messages = command.new("Toggle Message Log", function() editor.send("<C-\\><C-N>:messages<CR>") end)
M.checkhealth = command.new("Check Health", "<Cmd>checkhealth<CR>")

M.new = command.new("New Tab", { vim.cmd.tabnew, c = true })
M.open = command.new("Open...", { ui.browse, c = true })
M.save = command.new("Save", ui.save)
M.saveas = command.new("Save As...", ui.saveas)
M.saveall = command.new("Save All", "<Cmd>silent! wa<CR>")
M.split = command.new("Split Down", vim.cmd.split)
M.vsplit = command.new("Split Right", vim.cmd.vsplit)
M.close = command.new("Close", "<Cmd>confirm quit<CR>")
M.quit = command.new("Quit", { "<Cmd>confirm quitall<CR>", c = true })

M.tabprevious = command.new("Previous Tab", "<Cmd>tabprevious<CR>")
M.tabnext = command.new("Next Tab", "<Cmd>tabnext<CR>")

M.select = command.new("Select Character", { i = select_command("<C-O>v<Arrow><C-G>"), v = arrow_command("<Arrow>", "<C-V>gv<Arrow>v"), arrow = true })
M.selectword = command.new("Select Word", { i = select_command("<C-O>v<C-Arrow><C-G>"), v = arrow_command("<C-Arrow>", "<C-V>gv<C-Arrow>v"), arrow = true })
M.blockselect = command.new("Block Select Character", { i = select_command("<C-O><C-V><Arrow><C-G>"), v = arrow_command("<C-V><Arrow><C-G>", "<Arrow>"), arrow = true })
M.blockselectword = command.new("Block Select Word", { i = select_command("<C-O><C-V><C-Arrow><C-G>"), v = arrow_command("<C-V><C-Arrow><C-G>", "<C-Arrow>"), arrow = true })
M.selectall = command.new("Select All", { n = "ggVG", i = "<C-Home><C-O>VG", v = "gg0oG$" })
M.stopselect = command.new("Stop Selection", { v = function(lhs) editor.send("<Esc>") sacrilege.interrupt() editor.send(lhs) end, input = true })

M.mouseselect = command.new("Set Selection End", "<S-LeftMouse>")
M.mousestartselect = command.new("Start Selection", "<LeftMouse>")
M.mousestartblockselect = command.new("Start Block Selection", "<4-LeftMouse>")
M.mousedragselect = command.new("Drag Select", "<LeftDrag>")
M.mousestopselect = command.new("Stop Selection", "")

M.autopair = command.new("Insert Character Pair", { i = autopair.insert, v = autopair.surround, input = true })
M.autounpair = command.new("Delete Character Pair", { i = function(lhs) if not autopair.remove() then editor.send(lhs) end end, input = true })

M.completion_abort = command.new("Abort Completion", completion_command(completion.abort))
M.completion_trigger = command.new("Trigger Completion", completion_command(completion.trigger))
M.completion_confirm = command.new("Confirm Completion", completion_command(function() return completion.confirm({ select = false }) end))
M.completion_selectconfirm = command.new("Select and Confirm Completion", completion_command(function() return completion.confirm({ select = true }) end))
M.completion_select_previous = command.new("Select Previous Completion", completion_command(function() return completion.select(-1) end))
M.completion_select_next = command.new("Select Next Completion", completion_command(function() return completion.select(1) end))

M.snippet_jump_previous = command.new("Snippet Jump Previous", snippet_command(function() return snippet.jump(-1) end))
M.snippet_jump_next = command.new("Snippet Jump Next", snippet_command(function() return snippet.jump(1) end))

M.undo = command.new("Undo", vim.cmd.undo)
M.redo = command.new("Redo", vim.cmd.redo)
M.copy = command.new("Copy", { v = "\"+y" })
M.cut = command.new("Cut", { v = "\"+x" })
M.paste = command.new("Paste", { n = "\"+gP", i = "<C-G>u<C-\\><C-O>\"+gP", v = paste("+"), c = "<C-R>+", o = "<C-C>\"+gP<C-\\><C-G>" })
M.delete = command.new("Delete", { v = "\"_d" })
M.deleteword = command.new("Delete Word", { n = "cvb", i = "<C-\\><C-N>cvb", v = "\"_d" })

M.find = command.new("Find...", ui.find)
M.find_previous = command.new("Find Previous", "<C-\\><C-N><Left>gN")
M.find_next = command.new("Find Next", "<C-\\><C-N>gn")
M.replace = command.new("Replace", ui.replace)
M.find_in_files = command.new("Find in Files...", ui.find_in_files)
M.replace_in_files  = command.new("Replace in Files...", ui.replace_in_files)
M.line = command.new("Go to Line...", ui.go_to_line)

M.indent = command.new("Indent", { i = "<C-T>", s = "<C-O>>gv", x = "<C-G><C-O>>gv" })
M.unindent = command.new("Unindent", { i = "<C-D>", s = "<C-O><lt>gv", x = "<C-G><C-O><lt>gv" })
M.comment = command.new("Toggle Line Comment",
{
    i = function() editor.send("<C-\\><C-N>") editor.send("gcci", true) end,
    s = function() editor.send("<C-G>") editor.send("gc", true) editor.send("<C-\\><C-N>gv") end,
    x = function() editor.send("gc", true) editor.send("<C-\\><C-N>gv") end
})
M.format = command.new("Format Document", { n = "gg=G", i = "<C-\\><C-N>gg=G" })
M.format_selection = command.new("Format Selection", { s = "<C-O>=gv", x = "<C-G><C-O>=gv" })

M.spellcheck = command.new("Toggle Spell Check", function() vim.o.spell = not vim.o.spell end)
M.spellerror_previous = command.new("Go to Previous Spelling Error", "<C-\\><C-N><Left>[s")
M.spellerror_next =  command.new("Go to Next Spelling Error", "<C-\\><C-N><Right>]s")
M.spellsuggest = command.new("Suggest Spelling Corrections", "<Cmd>startinsert<CR><Right><C-X>s")
M.spellrepeat = command.new("Repeat Spelling Correction", "<Cmd>spellrepall<CR>")

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

M.treesitter.definition = command.new("Go to Definition", { function() require("sacrilege.treesitter").definition() end, condition = ts_condition(methods.textDocument_definition) })
M.treesitter.references = command.new("Find All References...", { function() require("sacrilege.treesitter").references() end, condition = ts_condition(methods.textDocument_references) })
M.treesitter.rename = command.new("Rename...", { function() require("sacrilege.treesitter").rename() end, condition = ts_condition(methods.textDocument_rename) })

M.lsp.format = command.new("Format Document", { function() vim.lsp.buf.format({ async = true }) end, condition = lsp_condition(methods.textDocument_formatting), v = false })
M.lsp.format_selection = command.new("Format Selection", { function() vim.lsp.buf.format({ async = true, range = editor.get_selection_range() }) end, condition = lsp_condition(methods.textDocument_rangeFormatting), n = false, i = false })

M.lsp.hover = command.new("Hover",
{
    { popup_command(vim.lsp.buf.hover), condition = lsp_condition(methods.textDocument_hover) },
    { popup_command(vim.lsp.buf.signature_help), condition = lsp_condition(methods.textDocument_signatureHelp) }
})
M.lsp.definition = command.new("Go to Definition", { vim.lsp.buf.definition, condition = lsp_condition(methods.textDocument_definition) })
M.lsp.references = command.new("Find All References...", { vim.lsp.buf.references, condition = lsp_condition(methods.textDocument_references) })
M.lsp.implementation = command.new("Go to Implementation", { vim.lsp.buf.implementation, condition = lsp_condition(methods.textDocument_implementation) })
M.lsp.type_definition = command.new("Go to Type Definition", { vim.lsp.buf.type_definition, condition = lsp_condition(methods.textDocument_typeDefinition) })
M.lsp.document_symbol = command.new("Find in Document Symbols...", { vim.lsp.buf.document_symbol, condition = lsp_condition(methods.textDocument_documentSymbol) })
M.lsp.workspace_symbol = command.new("Find in Workspace Symbols...", { vim.lsp.buf.workspace_symbol, condition = lsp_condition(methods.workspace_symbol) })
M.lsp.declaration = command.new("Go to Declaration", { vim.lsp.buf.declaration, condition = lsp_condition(methods.textDocument_declaration) })
M.lsp.rename = command.new("Rename...", { vim.lsp.buf.rename, condition = lsp_condition(methods.textDocument_rename) })
M.lsp.code_action = command.new("Code Action", { vim.lsp.buf.code_action, condition = lsp_condition(methods.textDocument_codeAction) })
M.lsp.hint = command.new("Toggle Hints", { function(buffer) vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = buffer }, { bufnr = buffer }) end, condition = lsp_condition(methods.textDocument_inlayHint), buffer = true })

return M
