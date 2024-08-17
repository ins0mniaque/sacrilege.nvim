local M = { }

local keys =
{
    cancel = "<Esc>",
    interrupt = "<C-C>",
    snippet_jump_next_or_multilineindent_or_inserttab = "<Tab>",
    completion_selectconfirm_or_cmdline_completion_trigger_or_replayinput = "<Tab>",
    snippet_jump_previous_or_unindent = "<S-Tab>",
    completion_select_previous_or_replayinput = "<Up>",
    completion_select_next_or_replayinput = "<Down>",
    stopselect_and_replayinput = { "<Up>", "<Down>" },
    wildmenu_confirm_or_replayinput = { "<Left>", "<Right>" },
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
    movecursor = { "<Left>", "<Right>", "<C-Arrow>" },

    mousestartblockselect = "<M-LeftMouse>",
    mousedragselect = "<M-LeftDrag>",
    mousestopselect = "<M-LeftRelease>",

    autopair = { "(", ")", "[", "]", "{", "}", "\"", "'" },
    autounpair_or_replayinput = "<BS>",

    completion_trigger = "<C-Space>",
    completion_confirm_or_replayinput = { "<Space>", "<CR>" },
    completion_selectconfirm_or_replayinput = "<S-CR>",

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

    comment = "<C-_>",
    format = "<M-F>",
    format_selection = "<M-F>",

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

local popup =
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

function M.apply(options)
    -- TODO: Clone commands
    options.commands = options.commands or { }
    for id, command in pairs(require("sacrilege.commands")) do
        options.commands[id] = command
    end

    options.keys = options.keys or { }
    for command, keys in pairs(keys) do
        options.keys[command] = keys
    end

    options.popup = vim.deepcopy(popup)
end

return M
