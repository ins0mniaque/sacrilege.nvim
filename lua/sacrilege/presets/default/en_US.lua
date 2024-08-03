local M = { }

function M.names()
    return
    {
        escape = "Escape",
        interrupt = "Interrupt",
        tab = "Indent / Snippet Jump Next",
        shifttab = "Unindent / Snippet Jump Previous",
        popup = "Popup Menu",

        command_palette = "Command Palette...",
        cmdline = "Command Line Mode",
        terminal = "Terminal",
        diagnostic = "Toggle Diagnostics",
        messages = "Toggle Message Log",

        new = "New Tab",
        open = "Open...",
        save = "Save",
        saveas = "Save As...",
        close = "Close",
        quit = "Quit",

        undo = "Undo",
        redo = "Redo",
        copy = "Copy",
        cut = "Cut",
        paste = "Paste",
        delete = "Delete",

        select = "Select Character",
        selectword = "Select Word",
        blockselect = "Block Select Character",
        blockselectword = "Block Select Word",
        selectall = "Select All",
        stopselect = "Stop Selection",

        mouseselect = "Set Selection End",
        mousestartselect = "Start Selection",
        mousestartblockselect = "Start Block Selection",
        mousedragselect = "Drag Select",
        mousestopselect = "Stop Selection",

        find = "Find...",
        find_previous = "Find Previous",
        find_next = "Find Next",
        replace = "Replace",
        find_in_files = "Find in Files...",
        line = "Go to Line...",

        comment = "Toggle Line Comment",
        format = "Format Document",
        format_selection = "Format Selection",

        continue = "Start Debugging / Continue",
        step_into = "Step Into",
        step_over = "Step Over",
        step_out = "Step Out",
        breakpoint = "Toggle Breakpoint",
        conditional_breakpoint = "Set Conditional Breakpoint",

        hover = "Hover",
        definition = "Go to Definition",
        references = "Find All References...",
        implementation = "Go to Implementation",
        type_definition = "Go to Type Definition",
        document_symbol = "Find in Document Symbols...",
        workspace_symbol = "Find in Workspace Symbols...",
        declaration = "Go to Declaration",
        rename = "Rename...",
        code_action = "Code Action",
        hint = "Toggle Hints",

        run_test = "Run Test",
        run_all_tests = "Run All Tests",
        debug_test = "Debug Test",
        stop_test = "Stop Test",
        attach_test = "Attach Test"
    }
end

return M
