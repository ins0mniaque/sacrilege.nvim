local M = { }

function M.names()
    return
    {
        escape = "Escape",
        interrupt = "Interrupt",
        tab = "Indent / Snippet Jump Next",
        shifttab = "Unindent / Snippet Jump Previous",
        up = "Up / Select Previous Completion",
        down = "Down / Select Next Completion",
        left = "Left / Wild Menu Left",
        right = "Right / Wild Menu Right",
        popup = "Popup Menu",

        command_palette = "Command Palette...",
        cmdline = "Command Line Mode",
        terminal = "Terminal",
        diagnostics = "Toggle Diagnostics",
        diagnostic = "Toggle Diagnostic Popup",
        messages = "Toggle Message Log",
        checkhealth = "Check Health",

        new = "New Tab",
        open = "Open...",
        save = "Save",
        saveas = "Save As...",
        saveall = "Save All",
        split = "Split Down",
        vsplit = "Split Right",
        close = "Close",
        quit = "Quit",

        tabprevious = "Previous Tab",
        tabnext = "Next Tab",

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

        autopair = "Insert Character Pair",

        completion_abort = "Abort Completion",
        completion_trigger = "Trigger Completion",
        completion_confirm = "Confirm Completion",
        completion_selectconfirm = "Select and Confirm Completion",
        completion_select_previous = "Select Previous Completion",
        completion_select_next = "Select Next Completion",

        snippet_jump_previous = "Snippet Jump Previous",
        snippet_jump_next = "Snippet Jump Next",

        undo = "Undo",
        redo = "Redo",
        copy = "Copy",
        cut = "Cut",
        paste = "Paste",
        delete = "Delete",
        deleteword = "Delete Word",

        find = "Find...",
        find_previous = "Find Previous",
        find_next = "Find Next",
        replace = "Replace",
        find_in_files = "Find in Files...",
        replace_in_files = "Replace in Files...",
        line = "Go to Line...",

        indent = "Indent",
        unindent = "Unindent",
        comment = "Toggle Line Comment",
        format = "Format Document",
        format_selection = "Format Selection",

        spellcheck = "Toggle Spell Check",
        spellerror_previous = "Go to Previous Spelling Error",
        spellerror_next = "Go to Next Spelling Error",
        spellsuggest = "Suggest Spelling Corrections",
        spellrepeat = "Repeat Spelling Correction",

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
