local completion = require("sacrilege.completion")

local M = { }

local defaults =
{
    insertmode = true,
    blockmode = true,
    autobreakundo = true,
    autocomplete = true,
    hover = true,
    completion =
    {
        trigger = function(what)
            if vim.fn.mode() == "c" then
                completion.wildmenu.trigger()
            elseif what.line:find("/") and not what.line:find("[%s%(%)%[%]]") then
                completion.native.trigger.path()
            elseif vim.bo.omnifunc ~= "" then
                completion.native.trigger.omni()
            elseif vim.bo.completefunc ~= "" then
                completion.native.trigger.user()
            -- elseif vim.bo.thesaurus ~= "" or vim.bo.thesaurusfunc ~= "" then
            --     return "thesaurus"
            -- elseif vim.bo.dictionary ~= "" then
            --     return "dictionary"
            -- elseif vim.wo.spell and vim.bo.spelllang ~= "" then
            --     return "spell"
            else
                completion.native.trigger.keyword()
            end
        end,
        native = completion.native,
        wildmenu = completion.wildmenu
    },
    snippet =
    {
        expand = vim.snippet and vim.snippet.expand,
        native = vim.snippet
    },
    selection =
    {
        mouse = true,
        virtual = true
    },
    keys =
    {
        ["<Esc>"] = "cancel",
        ["<Tab>"] = { "snippet_jump_next or multilineindent or inserttab", "completion_selectconfirm or cmdline_completion_trigger or replayinput" },
        ["<S-Tab>"] = "snippet_jump_previous or unindent",
        ["<Up>"] = { "completion_select_previous or replayinput", "stopselect and replayinput" },
        ["<Down>"] = { "completion_select_next or replayinput", "stopselect and replayinput" },
        ["<Left>"] = { "movecursor", "wildmenu_confirm or replayinput" },
        ["<Right>"] = { "movecursor", "wildmenu_confirm or replayinput" },
        ["<RightMouse>"] = "popup",
        ["<RightRelease>"] = "nothing",

        ["<F1>"] = "command_palette",
        ["<C-P>"] = "command_palette",
        ["<C-b>"] = "file_explorer",
        ["<M-o>"] = "code_outline",
        ["<M-d>"] = "debugger",
        ["<C-M-C>"] = "cmdline",
        ["<C-M-T>"] = "terminal",
        ["<C-D>"] = "diagnostics",
        ["<C-M-L>"] = "messages",
        ["<C-M-S-F1>"] = "checkhealth",

        ["<C-N>"] = "new",
        ["<C-O>"] = "open",
        ["<C-S>"] = "save",
        ["<M-S>"] = "saveas",
        ["<C-M-S>"] = "saveall",
        ["<F7>"] = "split",
        ["<F8>"] = "vsplit",
        ["<C-W>"] = "close",
        ["<F28>"] = "close",
        ["<C-Q>"] = "quit",
        ["<F52>"] = "quit",

        ["<C-S-Tab>"] = "tabprevious",
        ["<C-Tab>"] = "tabnext",

        ["<S-Arrow>"] = "select",
        ["<C-S-Arrow>"] = "selectword",
        ["<M-S-Arrow>"] = "blockselect",
        ["<C-M-S-Arrow>"] = "blockselectword",
        ["<C-A>"] = "selectall",
        ["<C-Arrow>"] = "movecursor",

        ["<M-Right>"] = "selectnode",
        ["<M-Down>"] = "selectscope",
        ["<M-Left>"] = "selectsubnode",
        ["<M-Up>"] = "selectsubnode",

        ["<M-LeftMouse>"] = "mousestartblockselect",
        ["<M-LeftDrag>"] = "mousedragselect",
        ["<M-LeftRelease>"] = "mousestopselect",

        ["("] = "autopair",
        [")"] = "autopair",
        ["["] = "autopair",
        ["]"] = "autopair",
        ["{"] = "autopair",
        ["}"] = "autopair",
        ["\""] = "autopair",
        ["'"] = "autopair",
        ["<BS>"] = "autounpair or replayinput",

        ["<C-Space>"] = "completion_trigger",
        ["<Space>"] = "completion_confirm or replayinput",
        ["<CR>"] = "completion_confirm or replayinput",
        ["<S-CR>"] = "completion_selectconfirm or replayinput",

        ["<C-Z>"] = "undo",
        ["<C-U>"] = "undo",
        ["<C-M-Z>"] = "redo",
        ["<C-Y>"] = "redo",
        ["<C-C>"] = { "copy", "interrupt" },
        ["<C-X>"] = "cut",
        ["<C-V>"] = "paste",
        ["<C-BS>"] = "deleteword",
        ["<M-BS>"] = "deleteword",

        ["<C-F>"] = "find",
        ["<F15>"] = "find_previous",
        ["<F3>"] = "find_next",
        ["<C-R>"] = "replace",
        ["<C-M-F>"] = "find_in_files",
        ["<C-M-R>"] = "replace_in_files",
        ["<C-G>"] = "line",

        ["<C-_>"] = "comment",
        ["<M-F>"] = { "format", "format_selection" },

        ["<F5>"] = "continue",
        ["<F11>"] = "step_into",
        ["<F10>"] = "step_over",
        ["<F23>"] = "step_out",
        ["<F9>"] = "breakpoint",
        ["<F21>"] = "conditional_breakpoint",

        ["<C-K>"] = "hover",
        ["<F12>"] = "definition",
        ["<C-G>d"] = "definition",
        ["<F24>"] = "references",
        ["<C-G>r"] = "references",
        ["<C-G>i"] = "implementation",
        ["<C-G>t"] = "type_definition",
        ["<C-G>s"] = "document_symbol",
        ["<C-G>S"] = "workspace_symbol",
        ["<C-G>D"] = "declaration",
        ["<M-R>"] = "rename",
        ["<F2>"] = "rename",
        ["<M-A>"] = "code_action or diagnostic",
        ["<F49>"] = "code_action or diagnostic",
        ["<F13>"] = "hint",

        ["<C-T>r"] = "run_test",
        ["<C-T>R"] = "run_all_tests",
        ["<C-T>d"] = "debug_test",
        ["<C-T>s"] = "stop_test",
        ["<C-T>a"] = "attach_test"
    },
    popup =
    {
        { "command_palette", position = ".100" },
        { "split", position = ".100" },
        { "vsplit", position = ".100" },
        { "autohide", position = ".100" },
        { "close", position = ".100" },
        { "-top-", position = ".100" },
        "-bottom-",
        "definition",
        "references",
        "rename",
        "code_action",
        "hover",
        "format_selection",
        "comment"
    }
}

function M.apply(options)
    options.commands = options.commands or { }

    for id, command in pairs(require("sacrilege.commands.native")) do
        options.commands[id] = command
    end

    for id, command in pairs(require("sacrilege.commands.ide")) do
        options.commands[id] = command
    end

    return vim.tbl_deep_extend("force", options, defaults)
end

return M
