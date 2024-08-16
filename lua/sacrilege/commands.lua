local sacrilege = require("sacrilege")
local command = require("sacrilege.command")
local editor = require("sacrilege.editor")
local completion = require("sacrilege.completion")
local snippet = require("sacrilege.snippet")
local autopair = require("sacrilege.autopair")
local blockmode = require("sacrilege.blockmode")
local ui = require("sacrilege.ui")
local treesitter = require("sacrilege.treesitter")
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

local function supports_treesitter()
    return treesitter.has_parser(treesitter.get_buf_lang())
end

local function supports_lsp(method)
    return function() return editor.supports_lsp_method(0, method) end
end

M.replayinput = command.new("Replay Input", editor.send):requires({ input = true, modeless = true }):all(true)

M.clear_highlights = command.new("Clear Highlights", "<Cmd>nohl<CR>"):cmdline(true)
M.clear_echo = command.new("Clear Command Line Message", "<Cmd>echon '\\r\\r'<CR><Cmd>echon ''<CR>"):cmdline(true)
M.stop_blockmode = command.new("Stop Block Mode", blockmode.stop):cmdline(true)
M.close_popup = command.new("Close Popup", editor.try_close_popup):cmdline(true)
M.wildmenu_confirm = command.new("Confirm Wild Menu"):cmdline(completion.confirm(opts)):when(function() return vim.fn.wildmenumode() and vim.fn.pumvisible() == 1 end)
M.escape = command.new("Escape", sacrilege.escape)
M.interrupt = command.new("Interrupt", sacrilege.interrupt):visual(false):cmdline(true)

M.tab = command.new("Indent / Snippet Jump Next", sacrilege.tab):normal(false):cmdline(true)
M.shifttab = command.new("Unindent / Snippet Jump Previous", sacrilege.shifttab):normal(false)
M.popup = command.new("Popup Menu"):select("<C-\\><C-G>gv<Cmd>:popup! PopUp<CR>")

M.command_palette = command.new("Command Palette...", ui.command_palette):cmdline(true)
M.cmdline = command.new("Command Line Mode", "<Esc>:")
M.terminal = command.new("Terminal", vim.cmd.terminal):cmdline(true)
M.diagnostics = command.new("Toggle Diagnostics", vim.diagnostic.setloclist):cmdline(true)
M.diagnostic = (M.close_popup / command.new("Open Diagnostic Popup", function() vim.diagnostic.open_float({ scope = 'cursor', focus = false }) end)):named("Toggle Diagnostic Popup")
M.messages = command.new("Toggle Message Log", function() editor.send("<C-\\><C-N>:messages<CR>") end)
M.checkhealth = command.new("Check Health", "<Cmd>checkhealth<CR>")

M.new = command.new("New Tab", vim.cmd.tabnew):cmdline(true)
M.open = command.new("Open...", ui.browse):cmdline(true)
M.save = command.new("Save", ui.save)
M.saveas = command.new("Save As...", ui.saveas)
M.saveall = command.new("Save All", "<Cmd>silent! wa<CR>")
M.split = command.new("Split Down", vim.cmd.split)
M.vsplit = command.new("Split Right", vim.cmd.vsplit)
M.close = command.new("Close", "<Cmd>confirm quit<CR>")
M.quit = command.new("Quit", "<Cmd>confirm quitall<CR>"):all(true)

M.tabprevious = command.new("Previous Tab", "<Cmd>tabprevious<CR>")
M.tabnext = command.new("Next Tab", "<Cmd>tabnext<CR>")

M.select = command.new("Select Character"):insert(select_command("<C-O>v<Arrow><C-G>")):visual(arrow_command("<Arrow>", "<C-V>gv<Arrow>v")):requires({ arrow = true })
M.selectword = command.new("Select Word"):insert(select_command("<C-O>v<C-Arrow><C-G>")):visual(arrow_command("<C-Arrow>", "<C-V>gv<C-Arrow>v")):requires({ arrow = true })
M.blockselect = command.new("Block Select Character"):insert(select_command("<C-O><C-V><Arrow><C-G>")):visual(arrow_command("<C-V><Arrow><C-G>", "<Arrow>")):requires({ arrow = true })
M.blockselectword = command.new("Block Select Word"):insert(select_command("<C-O><C-V><C-Arrow><C-G>")):visual(arrow_command("<C-V><C-Arrow><C-G>", "<C-Arrow>")):requires({ arrow = true })
M.selectall = command.new("Select All"):normal("ggVG"):insert("<C-Home><C-O>VG"):visual("gg0oG$")
M.stopselect = command.new("Stop Selection"):visual(function() editor.send("<Esc>") sacrilege.interrupt() end)
M.movecursor = M.stopselect + M.replayinput

M.mouseselect = command.new("Set Selection End", "<S-LeftMouse>")
M.mousestartselect = command.new("Start Selection", "<LeftMouse>")
M.mousestartblockselect = command.new("Start Block Selection", "<4-LeftMouse>")
M.mousedragselect = command.new("Drag Select", "<LeftDrag>")
M.mousestopselect = command.new("Stop Selection", "")

M.autopair = command.new("Insert Character Pair"):insert(autopair.insert):visual(autopair.surround):requires({ input = true })
M.autounpair = command.new("Delete Character Pair"):insert(autopair.remove):requires({ input = true })

M.completion_abort = command.new("Abort Completion"):insert(completion.abort):cmdline(true)
M.completion_trigger = command.new("Trigger Completion"):insert(completion.trigger):cmdline(true)
M.completion_confirm = command.new("Confirm Completion"):insert(function() return completion.confirm({ select = false }) end):cmdline(true)
M.completion_selectconfirm = command.new("Select and Confirm Completion"):insert(function() return completion.confirm({ select = true }) end):cmdline(true)
M.completion_select_previous = command.new("Select Previous Completion"):insert(function() return completion.select(-1) end):cmdline(true)
M.completion_select_next = command.new("Select Next Completion"):insert(function() return completion.select(1) end):cmdline(true)

M.snippet_jump_previous = command.new("Snippet Jump Previous"):visual(function() return snippet.jump(-1) end)
M.snippet_jump_next = command.new("Snippet Jump Next"):visual(function() return snippet.jump(1) end)
M.snippet_stop = command.new("Snippet Stop"):visual(snippet.stop)

M.undo = command.new("Undo", vim.cmd.undo)
M.redo = command.new("Redo", vim.cmd.redo)
M.copy = command.new("Copy"):visual("\"+y")
M.cut = command.new("Cut"):visual("\"+x")
M.paste = command.new("Paste"):normal("\"+gP"):insert("<C-G>u<C-\\><C-O>\"+gP"):visual(paste("+")):cmdline("<C-R>+"):pending("<C-C>\"+gP<C-\\><C-G>")
M.delete = command.new("Delete"):visual("\"_d")
M.deleteword = command.new("Delete Word"):normal("cvb"):insert("<C-\\><C-N>cvb"):visual("\"_d")

M.find = command.new("Find...", ui.find)
M.find_previous = command.new("Find Previous", "<C-\\><C-N><Left>gN")
M.find_next = command.new("Find Next", "<C-\\><C-N>gn")
M.replace = command.new("Replace", ui.replace)
M.find_in_files = command.new("Find in Files...", ui.find_in_files)
M.replace_in_files  = command.new("Replace in Files...", ui.replace_in_files)
M.line = command.new("Go to Line...", ui.go_to_line)

M.indent = command.new("Indent"):insert("<C-T>"):visual("<C-G><C-O>>gv"):select("<C-O>>gv")
M.unindent = command.new("Unindent"):insert("<C-D>"):visual("<C-G><C-O><lt>gv"):select("<C-O><lt>gv")
M.comment = command.new("Toggle Line Comment")
                   :insert(function() editor.send("<C-\\><C-N>") editor.send("gcci", true) end)
                   :visual(function() editor.send("gc", true) editor.send("<C-\\><C-N>gv") end)
                   :select(function() editor.send("<C-G>") editor.send("gc", true) editor.send("<C-\\><C-N>gv") end)

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

M.lsp.format = command.new("Format Document", function() vim.lsp.buf.format({ async = true }) end):visual(false)
                      :when(supports_lsp(methods.textDocument_formatting))

M.reindent = command.new("Reindent Document", function() editor.send(editor.mapmode() == "i" and "<C-\\><C-N>gg=G" or "gg=G") end):visual(false)

M.format = M.lsp.format / M.reindent

M.lsp.format_selection = command.new("Format Selection")
                                :visual(function() vim.lsp.buf.format({ async = true, range = editor.get_selection_range() }) end)
                                :when(supports_lsp(methods.textDocument_rangeFormatting))

M.reindent_selection = command.new("Reindent Selection")
                              :visual(function() editor.send(editor.mapmode() == "x" and "<C-G><C-O>=gv" or "<C-O>=gv") end)

M.format_selection = M.lsp.format_selection / M.reindent_selection

M.treesitter.definition = command.new("Go to Definition", treesitter.definition):when(supports_treesitter)
M.lsp.definition = command.new("Go to Definition", vim.lsp.buf.definition):when(supports_lsp(methods.textDocument_definition))
M.definition = M.lsp.definition / M.treesitter.definition

M.treesitter.references = command.new("Find All References...", treesitter.references):when(supports_treesitter)
M.lsp.references = command.new("Find All References...", vim.lsp.buf.references):when(supports_lsp(methods.textDocument_references))
M.references = M.lsp.references / M.treesitter.references

M.treesitter.rename = command.new("Rename...", treesitter.rename):when(supports_treesitter)
M.lsp.rename = command.new("Rename...", vim.lsp.buf.rename):when(supports_lsp(methods.textDocument_rename))
M.rename = M.lsp.rename / M.treesitter.rename

M.lsp.hover = command.new("Hover", vim.lsp.buf.hover):when(supports_lsp(methods.textDocument_hover))
M.lsp.signature_help = command.new("Signature Help", vim.lsp.buf.signature_help):when(supports_lsp(methods.textDocument_signatureHelp))
M.hover = (M.close_popup / M.lsp.hover / M.lsp.signature_help):named("Hover")

M.lsp.implementation = command.new("Go to Implementation", vim.lsp.buf.implementation):when(supports_lsp(methods.textDocument_implementation))
M.implementation = M.lsp.implementation:copy()

M.lsp.type_definition = command.new("Go to Type Definition", vim.lsp.buf.type_definition):when(supports_lsp(methods.textDocument_typeDefinition))
M.type_definition = M.lsp.type_definition:copy()

M.lsp.document_symbol = command.new("Find in Document Symbols...", vim.lsp.buf.document_symbol):when(supports_lsp(methods.textDocument_documentSymbol))
M.document_symbol = M.lsp.document_symbol:copy()

M.lsp.workspace_symbol = command.new("Find in Workspace Symbols...", vim.lsp.buf.workspace_symbol):when(supports_lsp(methods.workspace_symbol))
M.workspace_symbol = M.lsp.workspace_symbol:copy()

M.lsp.declaration = command.new("Go to Declaration", vim.lsp.buf.declaration):when(supports_lsp(methods.textDocument_declaration))
M.declaration = M.lsp.declaration:copy()

M.lsp.code_action = command.new("Code Action", vim.lsp.buf.code_action):when(supports_lsp(methods.textDocument_codeAction))
M.code_action = M.lsp.code_action:copy()

local function toggle_lsp_inlay_hint()
    local buffer = vim.api.nvim_get_current_buf()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = buffer }, { bufnr = buffer })
end

M.lsp.hint = command.new("Toggle Hints", toggle_lsp_inlay_hint):when(supports_lsp(methods.textDocument_inlayHint))
M.hint = M.lsp.hint:copy()

M.cancel = (M.stop_blockmode / M.completion_abort / M.snippet_stop / M.close_popup / M.escape + M.clear_highlights + M.clear_echo):named("Cancel")

return M
