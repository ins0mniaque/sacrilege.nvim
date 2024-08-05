local M = { }

function M.commands(language)
    local sacrilege = require("sacrilege")
    local editor = require("sacrilege.editor")
    local completion = require("sacrilege.completion")
    local snippet = require("sacrilege.snippet")
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

    return
    {
        names = localized.names(),
        global =
        {
            escape = { i = sacrilege.escape },
            interrupt = { i = sacrilege.interrupt },
            tab = { sacrilege.tab, n = false },
            shifttab = { sacrilege.shifttab, n = false },
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
            saveall = "<Cmd>silent! wa<CR>",
            split = vim.cmd.split,
            vsplit = vim.cmd.vsplit,
            close = "<Cmd>confirm quit<CR>",
            quit = { "<Cmd>confirm quitall<CR>", c = true },

            tabprevious = "<Cmd>tabprevious<CR>",
            tabnext = "<Cmd>tabnext<CR>",

            select = { i = "<C-o>v<C-g><Arrow>", v = arrow_command("<Arrow>", "<C-v>gv<Arrow>v") },
            selectword = { i = "<C-o>v<C-g><C-Arrow>", v = arrow_command("<C-Arrow>", "<C-v>gv<C-Arrow>v") },
            blockselect ={ i = "<C-o><C-v><C-g><Arrow>", v = arrow_command("<C-v><Arrow><C-g>", "<Arrow>") },
            blockselectword ={ i = "<C-o><C-v><C-g><C-Arrow>", v = arrow_command("<C-v><C-Arrow><C-g>", "<C-Arrow>") },
            selectall = { n = "ggVG", i = "<C-Home><C-O>VG", v = "gg0oG$" },
            stopselect = { s = "<Esc><Arrow>", x = "<Esc><Arrow>" },

            mouseselect = "<S-LeftMouse>",
            mousestartselect = "<LeftMouse>",
            mousestartblockselect = "<4-LeftMouse>",
            mousedragselect = "<LeftDrag>",
            mousestopselect = "",

            completion_abort = { function(lhs) if not completion.abort() then editor.send(lhs) end end, lhs = true, n = false, v = false, c = true },
            completion_trigger = { function(lhs) if not completion.trigger() then editor.send(lhs) end end, lhs = true, n = false, v = false, c = true },
            completion_confirm = { function(lhs) if not completion.confirm({ select = false }) then editor.send(lhs) end end, lhs = true, n = false, v = false, c = true },
            completion_selectconfirm = { function(lhs) if not completion.confirm({ select = true }) then editor.send(lhs) end end, lhs = true, n = false, v = false, c = true },
            completion_select_previous = { function(lhs) if not completion.select(-1) then editor.send(lhs) end end, lhs = true, n = false, v = false, c = true },
            completion_select_next = { function(lhs) if not completion.select(1) then editor.send(lhs) end end, lhs = true, n = false, v = false, c = true },

            snippet_jump_previous = { v = function(lhs) if not snippet.jump(-1) then editor.send(lhs) end end, lhs = true },
            snippet_jump_next = { v = function(lhs) if not snippet.jump(1) then editor.send(lhs) end end, lhs = true },

            undo = vim.cmd.undo,
            redo = vim.cmd.redo,
            copy = { v = "\"+y" },
            cut = { v = "\"+x" },
            paste = { n = "\"+gP", i = "<C-\\><C-O>\"+gP", v = "\"_d\"+P", c = "<C-r>+", o = "<C-c>\"+gP<C-\\><C-g>" },
            delete = { v = "\"_d" },
            deleteword = { n = "cvb", i = "<C-\\><C-N>cvb", v = "\"_d" },

            find = ui.find,
            find_previous = "<C-\\><C-N><Left>gN",
            find_next = "<C-\\><C-N>gn",
            replace = ui.replace,
            find_in_files = ui.find_in_files,
            replace_in_files  = ui.replace_in_files,
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
            format = { function() vim.lsp.buf.format({ async = true }) end, method = methods.textDocument_formatting },
            format_selection = { function() vim.lsp.buf.format({ async = true, range = { start = vim.api.nvim_buf_get_mark(0, "<"), ["end"] = vim.api.nvim_buf_get_mark(0, ">") } }) end, method = methods.textDocument_rangeFormatting },

            hover =
            {
                { function() if not editor.try_close_popup() then vim.lsp.buf.hover() end end, method = methods.textDocument_hover },
                { function() if not editor.try_close_popup() then vim.lsp.buf.signature_help() end end, method = methods.textDocument_signatureHelp }
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
        saveas = "<M-s>",
        saveall = "<C-M-s>",
        split = "<F7>",
        vsplit = "<F8>",
        close = { "<C-w>", "<F28>" },
        quit = { "<C-q>", "<F52>" },

        tabprevious = "<C-S-Tab>",
        tabnext = "<C-Tab>",

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

        completion_abort = false,
        completion_trigger = "<C-Space>",
        completion_confirm = { "<Space>", "<CR>" },
        completion_selectconfirm = "<S-CR>",
        completion_select_previous = "<Up>",
        completion_select_next = "<Down>",

        snippet_jump_previous = false,
        snippet_jump_next = false,

        undo = "<C-z>",
        redo = { "<C-M-z>", "<C-y>" },
        copy = "<C-c>",
        cut = "<C-x>",
        paste = "<C-v>",
        delete = { "<BS>", "<Del>" },
        deleteword = { "<C-BS>", "<M-BS>" },

        find = "<C-f>",
        find_previous = "<F15>",
        find_next = "<F3>",
        replace = "<C-r>",
        find_in_files = "<C-M-f>",
        replace_in_files = "<C-M-r>",
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
        rename = { "<M-r>", "<F2>" },
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
