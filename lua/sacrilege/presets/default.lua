local M = { }

function M.commands(language)
    local sacrilege = require("sacrilege")
    local editor = require("sacrilege.editor")
    local completion = require("sacrilege.completion")
    local snippet = require("sacrilege.snippet")
    local autopair = require("sacrilege.autopair")
    local ui = require("sacrilege.ui")
    local plugin = require("sacrilege.plugin")
    local methods = vim.lsp.protocol.Methods

    local ok, localized = pcall(require, "sacrilege.presets.default." .. (language or editor.detect_language() or "en_US"))
    if not ok then
        localized = require("sacrilege.presets.default.en_US")
    end

    local dap     = plugin.new("mfussenegger/nvim-dap", "dap")
    local neotest = plugin.new("nvim-neotest/neotest", "neotest")

    local function arrow_command(rhs, block_rhs)
        return function(arrow)
            local mode = vim.fn.mode()
            local keys = mode == "\19" or mode == "\22" and block_rhs or rhs

            keys = keys:gsub("[Aa][rR][rR][oO][wW]>", arrow .. ">")

            editor.send(keys)
        end
    end

    local function completion_command(command)
        return { function(lhs) if not command() then editor.send(lhs) end end, lhs = true, n = false, v = false, c = true }
    end

    local function snippet_command(command)
        return { v = function(lhs) if not command() then editor.send(lhs) end end, lhs = true }
    end

    local function popup_command(command)
        return function() if not editor.try_close_popup() then command() end end
    end

    return
    {
        names = localized.names(),
        global =
        {
            escape = { sacrilege.escape, n = false, c = true },
            interrupt = { sacrilege.interrupt, n = false, v = false, c = true },
            tab = { sacrilege.tab, n = false, c = true },
            shifttab = { sacrilege.shifttab, n = false },
            up = { sacrilege.up, n = false, c = true },
            down = { sacrilege.down, n = false, c = true },
            left = { c = function() editor.send(vim.fn.pumvisible() == 1 and "<C-Y><Left>" or "<Left>") end },
            right = { c = function() editor.send(vim.fn.pumvisible() == 1 and "<C-Y><Right>" or "<Right>") end },
            popup = { s = "<C-\\><C-G>gv<Cmd>:popup! PopUp<CR>" },

            command_palette = { ui.command_palette, c = true },
            cmdline = "<Esc>:",
            terminal = { vim.cmd.terminal, c = true },
            diagnostics = { vim.diagnostic.setloclist, c = true },
            diagnostic = popup_command(function() vim.diagnostic.open_float({ scope = 'cursor', focus = false }) end),
            messages = function() editor.send("<C-\\><C-N>:messages<CR>") end,
            checkhealth = "<Cmd>checkhealth<CR>",

            new = { vim.cmd.tabnew, c = true },
            open = { ui.browse, c = true },
            save = ui.save,
            saveas = ui.saveas,
            saveall = "<Cmd>silent! wa<CR>",
            split = vim.cmd.split,
            vsplit = vim.cmd.vsplit,
            close = "<Cmd>confirm quit<CR>",
            quit = { "<Cmd>confirm quitall<CR>", c = true },

            tabprevious = "<Cmd>tabprevious<CR>",
            tabnext = "<Cmd>tabnext<CR>",

            select = { i = "<C-O>v<C-G><Arrow>", v = arrow_command("<Arrow>", "<C-V>gv<Arrow>v") },
            selectword = { i = "<C-O>v<C-G><C-Arrow>", v = arrow_command("<C-Arrow>", "<C-V>gv<C-Arrow>v") },
            blockselect ={ i = "<C-O><C-V><C-G><Arrow>", v = arrow_command("<C-V><Arrow><C-G>", "<Arrow>") },
            blockselectword ={ i = "<C-O><C-V><C-G><C-Arrow>", v = arrow_command("<C-V><C-Arrow><C-G>", "<C-Arrow>") },
            selectall = { n = "ggVG", i = "<C-Home><C-O>VG", v = "gg0oG$" },
            stopselect = { s = "<Esc><Arrow>", x = "<Esc><Arrow>" },

            mouseselect = "<S-LeftMouse>",
            mousestartselect = "<LeftMouse>",
            mousestartblockselect = "<4-LeftMouse>",
            mousedragselect = "<LeftDrag>",
            mousestopselect = "",

            autopair = { i = autopair.insert, v = autopair.surround, lhs = true },
            autounpair = { i = function(lhs) if not autopair.remove() then editor.send(lhs) end end, lhs = true },

            completion_abort = completion_command(completion.abort),
            completion_trigger = completion_command(completion.trigger),
            completion_confirm = completion_command(function() return completion.confirm({ select = false }) end),
            completion_selectconfirm = completion_command(function() return completion.confirm({ select = true }) end),
            completion_select_previous = completion_command(function() return completion.select(-1) end),
            completion_select_next = completion_command(function() return completion.select(1) end),

            snippet_jump_previous = snippet_command(function() return snippet.jump(-1) end),
            snippet_jump_next = snippet_command(function() return snippet.jump(1) end),

            undo = vim.cmd.undo,
            redo = vim.cmd.redo,
            copy = { v = "\"+y" },
            cut = { v = "\"+x" },
            paste = { n = "\"+gP", i = "<C-\\><C-O>\"+gP", v = "\"_d\"+P", c = "<C-R>+", o = "<C-C>\"+gP<C-\\><C-G>" },
            delete = { v = "\"_d" },
            deleteword = { n = "cvb", i = "<C-\\><C-N>cvb", v = "\"_d" },

            find = ui.find,
            find_previous = "<C-\\><C-N><Left>gN",
            find_next = "<C-\\><C-N>gn",
            replace = ui.replace,
            find_in_files = ui.find_in_files,
            replace_in_files  = ui.replace_in_files,
            line = ui.go_to_line,

            indent = { i = "<C-T>", s = "<C-O>>gv", x = "<C-G><C-O>>gv" },
            unindent = { i = "<C-D>", s = "<C-O><lt>gv", x = "<C-G><C-O><lt>gv" },
            comment =
            {
                i = function() editor.send("<C-\\><C-N>") editor.send("gcci", true) end,
                s = function() editor.send("<C-G>") editor.send("gc", true) editor.send("<C-\\><C-N>gv") end,
                x = function() editor.send("gc", true) editor.send("<C-\\><C-N>gv") end
            },
            format = { n = "gg=G", i = "<C-\\><C-N>gg=G" },
            format_selection = { s = "<C-O>=gv", x = "<C-G><C-O>=gv" },

            spellcheck = function() vim.o.spell = not vim.o.spell end,
            spellerror_previous = "<C-\\><C-N><Left>[s",
            spellerror_next =  "<C-\\><C-N><Right>]s",
            spellsuggest =  "<Cmd>startinsert<CR><Right><C-X>s",
            spellrepeat = "<Cmd>spellrepall<CR>",

            continue = dap:try(function(dap) dap.continue() end),
            step_into = dap:try(function(dap) dap.step_into() end),
            step_over = dap:try(function(dap) dap.step_over() end),
            step_out = dap:try(function(dap) dap.step_out() end),
            breakpoint = dap:try(function(dap) dap.toggle_breakpoint() end),
            conditional_breakpoint = dap:try(function(dap) ui.input("Breakpoint condition: ", dap.set_breakpoint) end),

            run_test = neotest:try(function(neotest) neotest.run.run() end),
            run_all_tests = neotest:try(function(neotest) neotest.run.run(vim.fn.expand("%")) end),
            debug_test = neotest:try(function(neotest) neotest.run.run({ strategy = "dap" }) end),
            stop_test = neotest:try(function(neotest) neotest.run.stop() end),
            attach_test = neotest:try(function(neotest) neotest.run.attach() end)
        },
        treesitter =
        {
            definition = { function() require("sacrilege.treesitter").definition() end, method = methods.textDocument_definition },
            references = { function() require("sacrilege.treesitter").references() end, method = methods.textDocument_references },
            rename = { function() require("sacrilege.treesitter").rename() end, method = methods.textDocument_rename },
        },
        lsp =
        {
            format = { function() vim.lsp.buf.format({ async = true }) end, method = methods.textDocument_formatting, v = false },
            format_selection = { function() vim.lsp.buf.format({ async = true, range = editor.get_selection_range() }) end, method = methods.textDocument_rangeFormatting, n = false, i = false },

            hover =
            {
                { popup_command(vim.lsp.buf.hover), method = methods.textDocument_hover },
                { popup_command(vim.lsp.buf.signature_help), method = methods.textDocument_signatureHelp }
            },
            definition = { vim.lsp.buf.definition, method = methods.textDocument_definition },
            references = { vim.lsp.buf.references, method = methods.textDocument_references },
            implementation = { vim.lsp.buf.implementation, method = methods.textDocument_implementation },
            type_definition = { vim.lsp.buf.type_definition, method = methods.textDocument_typeDefinition },
            document_symbol = { vim.lsp.buf.document_symbol, method = methods.textDocument_documentSymbol },
            workspace_symbol = { vim.lsp.buf.workspace_symbol, method = methods.workspace_symbol },
            declaration = { vim.lsp.buf.declaration, method = methods.textDocument_declaration },
            rename = { vim.lsp.buf.rename, method = methods.textDocument_rename },
            code_action = { vim.lsp.buf.code_action, method = methods.textDocument_codeAction },
            hint = { function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 }) end, method = methods.textDocument_inlayHint },
        }
    }
end

function M.keys()
    return
    {
        escape = "<Esc>",
        interrupt = "<C-C>",
        tab = "<Tab>",
        shifttab = "<S-Tab>",
        up = "<Up>",
        down = "<Down>",
        left = "<Left>",
        right = "<Right>",
        popup = "<RightMouse>",

        command_palette = "<C-P>",
        cmdline = "<C-M-C>",
        terminal = "<C-M-T>",
        diagnostics = "<C-D>",
        diagnostic = "<F49>",
        messages = "<C-M-L>",
        checkhealth = "<C-M-S-F1>",

        new = "<C-N>",
        open = "<C-O>",
        save = "<C-S>",
        saveas = "<M-S>",
        saveall = "<C-M-S>",
        split = "<F7>",
        vsplit = "<F8>",
        close = { "<C-W>", "<F28>" },
        quit = { "<C-Q>", "<F52>" },

        tabprevious = "<C-S-Tab>",
        tabnext = "<C-Tab>",

        select = "<S-Arrow>",
        selectword = "<C-S-Arrow>",
        blockselect = "<M-S-Arrow>",
        blockselectword = "<C-M-S-Arrow>",
        selectall = "<C-A>",
        stopselect = { "<Left>", "<Right>", "<C-Arrow>" },

        mouseselect = false,
        mousestartselect = false,
        mousestartblockselect = "<M-LeftMouse>",
        mousedragselect = "<M-LeftDrag>",
        mousestopselect = "<M-LeftRelease>",

        autopair = { "(", ")", "[", "]", "{", "}", "\"", "'" },
        autounpair = "<BS>",

        completion_abort = false,
        completion_trigger = "<C-Space>",
        completion_confirm = { "<Space>", "<CR>" },
        completion_selectconfirm = "<S-CR>",
        completion_select_previous = false,
        completion_select_next = false,

        snippet_jump_previous = false,
        snippet_jump_next = false,

        undo = { "<C-Z>", "<C-U>" },
        redo = { "<C-M-Z>", "<C-Y>" },
        copy = "<C-C>",
        cut = "<C-X>",
        paste = "<C-V>",
        delete = { "<BS>", "<Del>" },
        deleteword = { "<C-BS>", "<M-BS>" },

        find = "<C-F>",
        find_previous = "<F15>",
        find_next = "<F3>",
        replace = "<C-R>",
        find_in_files = "<C-M-F>",
        replace_in_files = "<C-M-R>",
        line = "<C-G>",

        indent = false,
        unindent = false,
        comment = "<C-_>",
        format = "<M-F>",
        format_selection = "<M-F>",

        spellcheck = false,
        spellerror_previous = false,
        spellerror_next = false,
        spellsuggest = false,
        spellrepeat = false,

        continue = "<F5>",
        step_into = "<F11>",
        step_over = "<F10>",
        step_out = "<F23>",
        breakpoint = "<F9>",
        conditional_breakpoint = "<F21>",

        hover = "<F1>",
        definition = { "<F12>", "<C-G>d" },
        references = { "<F24>", "<C-G>r" },
        implementation = "<C-G>i",
        type_definition = "<C-G>t",
        document_symbol = "<C-G>s",
        workspace_symbol = "<C-G>S",
        declaration = "<C-G>D",
        rename = { "<M-R>", "<F2>" },
        code_action = { "<M-A>", "<F49>" },
        hint = "<F13>",

        run_test = "<C-T>r",
        run_all_tests = "<C-T>R",
        debug_test = "<C-T>d",
        stop_test = "<C-T>s",
        attach_test = "<C-T>a"
    }
end

function M.popup()
    return
    {
        { "command_palette", position = ".100" },
        { "split", position = ".100" },
        { "vsplit", position = ".100" },
        { "close", position = ".100" },
        { "-top-", position = ".100" },
        "-bottom-",
        "definition",
        "references",
        "rename",
        "code_action",
        "hover",
        "format_selection",
        { "comment", i = false }
    }
end

return M
