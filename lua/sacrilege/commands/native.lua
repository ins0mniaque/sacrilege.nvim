local sacrilege = require("sacrilege")
local command = require("sacrilege.command")
local editor = require("sacrilege.editor")
local completion = require("sacrilege.completion")
local snippet = require("sacrilege.snippet")
local autohide = require("sacrilege.autohide")
local autopair = require("sacrilege.autopair")
local blockmode = require("sacrilege.blockmode")
local insertmode = require("sacrilege.insertmode")
local menu = require("sacrilege.menu")
local ui = require("sacrilege.ui")
local treesitter = require("sacrilege.treesitter")
local methods = vim.lsp.protocol.Methods

local M = { treesitter = { }, lsp = { } }

local function not_implemented()
    return false
end

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

local function clear_echo()
    if vim.o.cmdheight > 0 then
        vim.cmd("echon '\\r\\r'")
        vim.cmd("echon ''")
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

M.nothing = command.new():all(true)
M.replayinput = command.new("Replay Input", editor.send):requires({ input = true, modeless = true }):all(true)

M.clear_highlights = command.new("Clear Highlights", "<Cmd>nohl<CR>"):cmdline(true)
M.clear_echo = command.new("Clear Command Line Message", clear_echo):cmdline(true)
M.stop_blockmode = command.new("Stop Block Mode", blockmode.stop):cmdline(true)
M.close_popup = command.new("Close Popup", editor.try_close_popup):cmdline(true)
M.escape = command.new("Escape", insertmode.escape):cmdline(true)
M.interrupt = command.new("Interrupt", insertmode.interrupt):visual(false):cmdline(true)
M.inserttab = command.new("Insert Tab"):visual("<Space><BS><Tab>")
M.nativepopup = command.new("Popup Menu", "<Cmd>:popup! PopUp<CR>"):select("<C-\\><C-G>gv<Cmd>:popup! PopUp<CR>")
M.popup = command.new("Popup Menu", menu.popup):all(true)
M.openlink = command.new("Open Link...")
                    :normal(function() editor.send("gx", true) end)
                    :insert(function() editor.send("<C-\\><C-N>") editor.send("gxi", true) editor.send("<C-\\><C-N>gv") end)
                    :visual(function() editor.send("<C-\\><C-N>") editor.send("gx", true) editor.send("<C-\\><C-N>gv") end)
                    :select(function() editor.send("<C-\\><C-N>") editor.send("gx", true) editor.send("<C-\\><C-N>gv") end)

M.cmdline = command.new("Command Line Mode", "<Esc>:")
M.terminal = command.new("Terminal", vim.cmd.terminal):cmdline(true)
M.diagnostics = command.new("Toggle Diagnostics", vim.diagnostic.setloclist):cmdline(true)
M.diagnostic = "Toggle Diagnostic Popup" .. M.close_popup / command.new("Open Diagnostic Popup", function() vim.diagnostic.open_float({ scope = 'cursor', focus = false }) end)
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

M.autohide = command.new("Toggle Auto-Hide", autohide.toggle)

M.tabpin = command.new("Pin Tab", not_implemented)
M.tabrestore = command.new("Restore Tab", not_implemented)
M.tabclose = command.new("Close Tab", "<Cmd>confirm tabclose<CR>")
M.tabcloseall = command.new("Close All Tabs", "<Cmd>tabnew<CR><Cmd>confirm tabonly<CR>")
M.tabcloseothers = command.new("Close Other Tabs", "<Cmd>confirm tabonly<CR>")
M.tabcloseleft = command.new("Close Tabs to the Left", not_implemented)
M.tabcloseright = command.new("Close Tabs to the Right", not_implemented)
M.tabcloseunpinned = command.new("Close Unpinned Tabs", not_implemented)

M.tabprevious = command.new("Previous Tab", "<Cmd>tabprevious<CR>")
M.tabnext = command.new("Next Tab", "<Cmd>tabnext<CR>")
M.tablast = command.new("Last Tab", "<Cmd>tablast<CR>")
M.tab1 = command.new("First Tab", "<Cmd>tabfirst<CR>")
M.tab2 = command.new("Second Tab", "<Cmd>tabnext 2<CR>")
M.tab3 = command.new("Third Tab", "<Cmd>tabnext 3<CR>")
M.tab4 = command.new("Fourth Tab", "<Cmd>tabnext 4<CR>")
M.tab5 = command.new("Fifth Tab", "<Cmd>tabnext 5<CR>")
M.tab6 = command.new("Sixth Tab", "<Cmd>tabnext 6<CR>")
M.tab7 = command.new("Seventh Tab", "<Cmd>tabnext 7<CR>")
M.tab8 = command.new("Eighth Tab", "<Cmd>tabnext 8<CR>")
M.tab9 = command.new("Nineth Tab", "<Cmd>tabnext 9<CR>")

M.select = command.new("Select Character"):insert(select_command("<C-O>v<Arrow><C-G>")):visual(arrow_command("<Arrow>", "<C-V>gv<Arrow>v")):requires({ arrow = true })
M.selectword = command.new("Select Word"):insert(select_command("<C-O>v<C-Arrow><C-G>")):visual(arrow_command("<C-Arrow>", "<C-V>gv<C-Arrow>v")):requires({ arrow = true })
M.blockselect = command.new("Block Select Character"):insert(select_command("<C-O><C-V><Arrow><C-G>")):visual(arrow_command("<C-V><Arrow><C-G>", "<Arrow>")):requires({ arrow = true })
M.blockselectword = command.new("Block Select Word"):insert(select_command("<C-O><C-V><C-Arrow><C-G>")):visual(arrow_command("<C-V><C-Arrow><C-G>", "<C-Arrow>")):requires({ arrow = true })
M.selectall = command.new("Select All"):normal("ggVG"):insert("<C-Home><C-O>VG"):visual("gg0oG$")
M.stopselect = command.new("Stop Selection"):visual(function() editor.send("<Esc>") insertmode.interrupt() end)
M.movecursor = M.stopselect + M.replayinput

M.treesitter.selectnode = command.new("Select Node", treesitter.selectnode):when({ treesitter = true })
M.treesitter.selectscope = command.new("Select Scope", treesitter.selectscope):when({ treesitter = true })
M.treesitter.selectsubnode = command.new("Select Sub Node", treesitter.selectsubnode):when({ treesitter = true })

M.selecttag = command.new("Select Tag"):insert("<C-O>vit<C-G>"):visual("it")
M.selectsentence = command.new("Select Sentence"):insert("<C-O>vis<C-G>"):visual("is")
M.selectparagraph = command.new("Select Paragraph"):insert("<C-O>vip<C-G>"):visual("ip")
M.selectnode = M.treesitter.selectnode:copy()
M.selectscope = M.treesitter.selectscope:copy()
M.selectsubnode = M.treesitter.selectsubnode:copy()

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
M.cmdline_completion_trigger = "Trigger Command Line Completion" .. M.completion_trigger:clone():insert(false)
M.wildmenu_confirm = "Confirm Wild Menu" .. M.completion_confirm:clone():when(function() return vim.fn.wildmenumode() and vim.fn.pumvisible() == 1 end)

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
M.inspect = command.new("Inspect", "<C-C><Cmd>Inspect<CR><C-\\><C-G>"):cmdline(true):pending(true):normal("<Cmd>Inspect<CR>"):insert("<C-\\><C-O><Cmd>Inspect<CR>")

M.find = command.new("Find...", ui.find)
M.find_previous = command.new("Find Previous", "<C-\\><C-N><Left>gN")
M.find_next = command.new("Find Next", "<C-\\><C-N>gn")
M.replace = command.new("Replace", ui.replace)
M.find_in_files = command.new("Find in Files...", ui.find_in_files)
M.replace_in_files  = command.new("Replace in Files...", ui.replace_in_files)
M.line = command.new("Go to Line...", ui.go_to_line)

M.indent = command.new("Indent"):insert("<C-T>"):visual("<C-G><C-O>>gv"):select("<C-O>>gv<C-G>")
M.multilineindent = "Multi-Line Indent" .. M.indent:clone():insert(false):when(function() return vim.fn.getpos("v")[2] ~= vim.fn.getpos(".")[2] end)
M.unindent = command.new("Unindent"):insert("<C-D>"):visual("<C-G><C-O><lt>gv"):select("<C-O><lt>gv<C-G>")
M.comment = command.new("Toggle Line Comment")
                   :insert(function() editor.send("<C-\\><C-N>") editor.send("gcci", true) end)
                   :visual(function() editor.send("gc", true) editor.send("<C-\\><C-N>gv") end)
                   :select(function() editor.send("<C-G>") editor.send("gc", true) editor.send("<C-\\><C-N>gv") end)

M.uppercase = command.new("Uppercase"):visual("U")
M.lowercase = command.new("Lowercase"):visual("u")
M.switchcase = command.new("Toggle Case"):visual("~")
M.rot13 = command.new("ROT13"):visual("g?")

M.spellcheck = command.new("Toggle Spell Check", function() vim.o.spell = not vim.o.spell end)
M.spellerror_previous = command.new("Go to Previous Spelling Error", "<C-\\><C-N><Left>[s")
M.spellerror_next =  command.new("Go to Next Spelling Error", "<C-\\><C-N><Right>]s")
M.spellsuggest = command.new("Suggest Spelling Corrections", "<Cmd>startinsert<CR><Right><C-X>s")
M.spellrepeat = command.new("Repeat Spelling Correction", "<Cmd>spellrepall<CR>")

M.lsp.format = command.new("Format Document", function() vim.lsp.buf.format({ async = true }) end):visual(false)
                      :when({ lsp = methods.textDocument_formatting })

M.reindent = command.new("Reindent Document", function() editor.send(editor.mapmode() == "i" and "<C-\\><C-N>gg=G" or "gg=G") end):visual(false)

M.format = M.lsp.format / M.reindent

M.lsp.format_selection = command.new("Format Selection")
                                :visual(function() vim.lsp.buf.format({ async = true, range = editor.get_selection_range() }) end)
                                :when({ lsp = methods.textDocument_rangeFormatting })

M.reindent_selection = command.new("Reindent Selection")
                              :visual(function() editor.send(editor.mapmode() == "x" and "<C-G><C-O>=gv" or "<C-O>=gv") end)

M.format_selection = M.lsp.format_selection / M.reindent_selection

M.treesitter.definition = command.new("Go to Definition", treesitter.definition):when({ treesitter = true })
M.lsp.definition = command.new("Go to Definition", vim.lsp.buf.definition):when({ lsp = methods.textDocument_definition })
M.definition = M.lsp.definition / M.treesitter.definition

M.treesitter.references = command.new("Find All References...", treesitter.references):when({ treesitter = true })
M.lsp.references = command.new("Find All References...", vim.lsp.buf.references):when({ lsp = methods.textDocument_references })
M.references = M.lsp.references / M.treesitter.references

M.treesitter.rename = command.new("Rename...", treesitter.rename):when({ treesitter = true })
M.lsp.rename = command.new("Rename...", vim.lsp.buf.rename):when({ lsp = methods.textDocument_rename })
M.rename = M.lsp.rename / M.treesitter.rename

M.lsp.hover = command.new("Hover", vim.lsp.buf.hover):when({ lsp = methods.textDocument_hover })
M.lsp.signature_help = command.new("Signature Help", vim.lsp.buf.signature_help):when({ lsp = methods.textDocument_signatureHelp })
M.hover = "Hover" .. M.close_popup / M.lsp.hover / M.lsp.signature_help

M.lsp.implementation = command.new("Go to Implementation", vim.lsp.buf.implementation):when({ lsp = methods.textDocument_implementation })
M.implementation = M.lsp.implementation:copy()

M.lsp.type_definition = command.new("Go to Type Definition", vim.lsp.buf.type_definition):when({ lsp = methods.textDocument_typeDefinition })
M.type_definition = M.lsp.type_definition:copy()

M.lsp.document_symbol = command.new("Find in Document Symbols...", vim.lsp.buf.document_symbol):when({ lsp = methods.textDocument_documentSymbol })
M.document_symbol = M.lsp.document_symbol:copy()

M.lsp.workspace_symbol = command.new("Find in Workspace Symbols...", vim.lsp.buf.workspace_symbol):when({ lsp = methods.workspace_symbol })
M.workspace_symbol = M.lsp.workspace_symbol:copy()

M.lsp.declaration = command.new("Go to Declaration", vim.lsp.buf.declaration):when({ lsp = methods.textDocument_declaration })
M.declaration = M.lsp.declaration:copy()

M.lsp.code_action = command.new("Code Action", vim.lsp.buf.code_action):when({ lsp = methods.textDocument_codeAction })
M.code_action = M.lsp.code_action:copy()

local function toggle_lsp_inlay_hint()
    local buffer = vim.api.nvim_get_current_buf()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = buffer }, { bufnr = buffer })
end

M.lsp.hint = command.new("Toggle Hints", toggle_lsp_inlay_hint):when({ lsp = methods.textDocument_inlayHint })
M.hint = M.lsp.hint:copy()

M.cancel = "Cancel" .. M.stop_blockmode / M.completion_abort / M.snippet_stop / M.close_popup / M.escape + M.clear_highlights + M.clear_echo

return M
