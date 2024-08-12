local M = { }

function M.commands()
    return require("sacrilege.commands")
end

function M.keys()
    return
    {
        cancel = "<Esc>",
        escape = false,
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
