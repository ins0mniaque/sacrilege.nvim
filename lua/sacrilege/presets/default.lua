local M = { }

function M.commands(language)
    local sacrilege -- require("sacrilege")
    local editor = require("sacrilege.editor")
    local ui = require("sacrilege.ui")

    local ok, localized = pcall(require, "sacrilege.presets.default." .. (language or editor.detect_language() or "en_US"))
    if not ok then
        localized = require("sacrilege.presets.default." .. "en_US")
    end

    return
    {
        names = localized.names(),
        global =
        {
            escape = { i = function() sacrilege = sacrilege or require("sacrilege") sacrilege.escape() end },
            interrupt = { i = function() sacrilege = sacrilege or require("sacrilege") sacrilege.interrupt() end },
            tab = { function() sacrilege = sacrilege or require("sacrilege") sacrilege.tab() end, n = false },
            shifttab = { function() sacrilege = sacrilege or require("sacrilege") sacrilege.shifttab() end, n = false },
            popup = { s = "<C-\\><C-g>gv<Cmd>:popup! PopUp<CR>" },

            command_palette = { ui.command_palette, c = true },
            cmdline = "<Esc>:",
            terminal = { vim.cmd.terminal, c = true },
            diagnostics = { vim.diagnostic.setloclist, c = true },
            diagnostic = function() if not editor.try_close_popup() then vim.diagnostic.open_float({ scope = 'cursor', focus = false }) end end,
            messages = function() editor.send("<C-\\><C-N>:messages<CR>") end,

            new = { vim.cmd.tabnew, c = true },
            open = { ui.browse, c = true },
            save = ui.save,
            saveas = ui.saveas,
            split = vim.cmd.split,
            vsplit = vim.cmd.vsplit,
            close = "<Cmd>confirm quit<CR>",
            quit = { "<Cmd>confirm quitall<CR>", c = true },

            select = { i = "<C-o>v<C-g><Arrow>", v = function(arrow) local mode = vim.fn.mode() editor.send(mode == "\19" or mode == "\22" and ("<C-v>gv<" .. arrow .. ">v") or ("<" .. arrow .. ">")) end },
            selectword = { i = "<C-o>v<C-g><C-Arrow>", v = function(arrow) local mode = vim.fn.mode() editor.send(mode == "\19" or mode == "\22" and ("<C-v>gv<C-" .. arrow .. ">v") or ("<C-" .. arrow .. ">")) end },
            blockselect ={ i = "<C-o><C-v><C-g><Arrow>", v = function(arrow) local mode = vim.fn.mode() editor.send(mode == "\19" or mode == "\22" and ("<" .. arrow .. ">") or ("<C-v><" .. arrow .. "><C-g>")) end },
            blockselectword ={ i = "<C-o><C-v><C-g><C-Arrow>", v = function(arrow) local mode = vim.fn.mode() editor.send(mode == "\19" or mode == "\22" and ("<C-" .. arrow .. ">") or ("<C-v><C-" .. arrow .. "><C-g>")) end },
            selectall = { n = "ggVG", i = "<C-Home><C-O>VG", v = "gg0oG$" },
            stopselect = { s = "<Esc><Arrow>", x = "<Esc><Arrow>" },

            mouseselect = "<S-LeftMouse>",
            mousestartselect = "<LeftMouse>",
            mousestartblockselect = "<4-LeftMouse>",
            mousedragselect = "<LeftDrag>",
            mousestopselect = "",

            undo = vim.cmd.undo,
            redo = vim.cmd.redo,
            copy = { v = "\"+y" },
            cut = { v = "\"+x" },
            paste = { n = "\"+gP", i = "<C-o>\"+gP", v = "\"+P", c = "<C-r>\"", o = "<C-c>\"+gP<C-\\><C-g>" },
            delete = { v = "\"_d" },

            find = ui.find,
            find_previous = "<C-\\><C-N><Left>gN",
            find_next = "<C-\\><C-N>gn",
            replace = ui.replace,
            find_in_files = ui.find_in_files,
            line = ui.go_to_line,

            indent = { s = "<C-O>>gv", x = "<C-g><C-O>>gv" },
            unindent = { i = "<C-d>", s = "<C-O><gv", x = "<C-g><C-O><gv" },
            comment =
            {
                i = function() editor.send("<C-\\><C-N>") editor.send("gcci", true) end,
                s = function() editor.send("<C-g>") editor.send("gc", true) editor.send("<C-\\><C-N>gv") end,
                x = function() editor.send("gc", true) editor.send("<C-\\><C-N>gv") end
            },
            format = { n = "gg=G", i = "<C-\\><C-N>gg=G" },
            format_selection = { s = "<C-O>=gv", x = "<C-g><C-O>=gv" },

            continue = function() require("dap").continue() end,
            step_into = function() require("dap").step_into() end,
            step_over = function() require("dap").step_over() end,
            step_out = function() require("dap").step_out() end,
            breakpoint = function() require("dap").toggle_breakpoint() end,
            conditional_breakpoint = function() ui.input("Breakpoint condition: ", require("dap").set_breakpoint) end,

            run_test = function() require("neotest").run.run() end,
            run_all_tests = function() require("neotest").run.run(vim.fn.expand("%")) end,
            debug_test = function() require("neotest").run.run({ strategy = "dap" }) end,
            stop_test = function() require("neotest").run.stop() end,
            attach_test = function() require("neotest").run.attach() end
        },
        treesitter =
        {
            definition = { function() require("sacrilege.treesitter").definition() end, method = vim.lsp.protocol.Methods.textDocument_definition },
            references = { function() require("sacrilege.treesitter").references() end, method = vim.lsp.protocol.Methods.textDocument_references },
            rename = { function() require("sacrilege.treesitter").rename() end, method = vim.lsp.protocol.Methods.textDocument_rename },
        },
        lsp =
        {
            format = { function() vim.lsp.buf.format({ async = true }) end, method = vim.lsp.protocol.Methods.textDocument_formatting },
            format_selection = { function() vim.lsp.buf.format({ async = true, range = { start = vim.api.nvim_buf_get_mark(0, "<"), ["end"] = vim.api.nvim_buf_get_mark(0, ">") } }) end, method = vim.lsp.protocol.Methods.textDocument_rangeFormatting },

            hover =
            {
                { function() if not editor.try_close_popup() then vim.lsp.buf.hover() end end, method = vim.lsp.protocol.Methods.textDocument_hover },
                { function() if not editor.try_close_popup() then vim.lsp.buf.signature_help() end end, method = vim.lsp.protocol.Methods.textDocument_signatureHelp }
            },
            definition = { vim.lsp.buf.definition, method = vim.lsp.protocol.Methods.textDocument_definition },
            references = { vim.lsp.buf.references, method = vim.lsp.protocol.Methods.textDocument_references },
            implementation = { vim.lsp.buf.implementation, method = vim.lsp.protocol.Methods.textDocument_implementation },
            type_definition = { vim.lsp.buf.type_definition, method = vim.lsp.protocol.Methods.textDocument_typeDefinition },
            document_symbol = { vim.lsp.buf.document_symbol, method = vim.lsp.protocol.Methods.textDocument_documentSymbol },
            workspace_symbol = { vim.lsp.buf.workspace_symbol, method = vim.lsp.protocol.Methods.workspace_symbol },
            declaration = { vim.lsp.buf.declaration, method = vim.lsp.protocol.Methods.textDocument_declaration },
            rename = { vim.lsp.buf.rename, method = vim.lsp.protocol.Methods.textDocument_rename },
            code_action = { vim.lsp.buf.code_action, method = vim.lsp.protocol.Methods.textDocument_codeAction },
            hint = { function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 }) end, method = vim.lsp.protocol.Methods.textDocument_inlayHint },
        }
    }
end

function M.keys()
    return
    {
        escape = "<Esc>",
        interrupt = "<C-c>",
        tab = "<Tab>",
        shifttab = "<S-Tab>",
        popup = "<RightMouse>",

        command_palette = "<C-p>",
        cmdline = "<C-M-c>",
        terminal = "<C-M-t>",
        diagnostics = "<C-d>",
        diagnostic = "<F49>",
        messages = "<C-l>",

        new = "<C-n>",
        open = "<C-o>",
        save = "<C-s>",
        saveas = "<C-M-s>",
        split = "<F7>",
        vsplit = "<F8>",
        close = { "<C-w>", "<F28>" },
        quit = { "<C-q>", "<F52>" },

        undo = "<C-z>",
        redo = { "<C-M-z>", "<C-y>" },
        copy = "<C-c>",
        cut = "<C-x>",
        paste = "<C-v>",
        delete = { "<BS>", "<Del>" },

        select = "<S-Arrow>",
        selectword = "<C-S-Arrow>",
        blockselect = "<M-S-Arrow>",
        blockselectword = "<C-M-S-Arrow>",
        selectall = "<C-a>",
        stopselect = { "<Arrow>", "<C-Arrow>" },

        mouseselect = false,
        mousestartselect = false,
        mousestartblockselect = "<M-LeftMouse>",
        mousedragselect = "<M-LeftDrag>",
        mousestopselect = "<M-LeftRelease>",

        find = "<C-f>",
        find_previous = "<F15>",
        find_next = "<F3>",
        replace = "<C-h>",
        find_in_files = "<C-M-f>",
        line = "<C-g>",

        indent = false,
        unindent = false,
        comment = "<C-_>",
        format = "<M-f>",
        format_selection = "<M-f>",

        continue = "<F5>",
        step_into = "<F11>",
        step_over = "<F10>",
        step_out = "<F23>",
        breakpoint = "<F9>",
        conditional_breakpoint = "<F21>",

        hover = "<F1>",
        definition = { "<F12>", "<C-g>d" },
        references = { "<F24>", "<C-g>r" },
        implementation = "<C-g>i",
        type_definition = "<C-g>t",
        document_symbol = "<C-g>s",
        workspace_symbol = "<C-g>S",
        declaration = "<C-g>D",
        rename = { "<C-r>", "<F2>" },
        code_action = { "<M-a>", "<F49>" },
        hint = "<F13>",

        run_test = "<C-t>r",
        run_all_tests = "<C-t>R",
        debug_test = "<C-t>d",
        stop_test = "<C-t>s",
        attach_test = "<C-t>a"
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
