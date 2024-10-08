local completion = require("sacrilege.completion")

local M = { }

local defaults =
{
    insertmode = true,
    blockmode = true,
    autobreakundo = true,
    autocomplete = true,
    highlight = true,
    hover = true,
    selection =
    {
        mouse = true,
        virtual = true
    },
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
    command = "Cmd",
    keys =
    {
        ["<Esc>"] = "cancel",
        ["<Tab>"] = { "snippet_jump_next or multilineindent or inserttab", "completion_selectconfirm or cmdline_completion_trigger or replayinput" },
        ["<S-Tab>"] = "snippet_jump_previous or unindent",
        ["<Up>"] = { "completion_select_previous or replayinput", "stopselect and replayinput" },
        ["<Down>"] = { "completion_select_next or replayinput", "stopselect and replayinput" },
        ["<Left>"] = { "stopselect and replayinput", "wildmenu_confirm or replayinput" },
        ["<Right>"] = { "stopselect and replayinput", "wildmenu_confirm or replayinput" },
        ["<RightMouse>"] = "popup",
        ["<RightRelease>"] = "nothing",
        ["<C-LeftMouse>"] = "click and openurl or definition",

        ["<F1>"] = "commands",
        ["<C-P>"] = "commands",
        ["<C-E>"] = "file_explorer",
        ["<M-G>"] = "source_control",
        ["<M-O>"] = "code_outline",
        ["<C-M-U>"] = "undo_history",
        ["<F53>"] = "run_task",
        ["<C-M-O>"] = "task_output",
        ["<M-C>"] = "compilers",
        ["<M-D>"] = "debugger",
        ["<C-M-I>"] = "repl",
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
        ["<C-1>"] = "tab1",
        ["<C-2>"] = "tab2",
        ["<C-3>"] = "tab3",
        ["<C-4>"] = "tab4",
        ["<C-5>"] = "tab5",
        ["<C-6>"] = "tab6",
        ["<C-7>"] = "tab7",
        ["<C-8>"] = "tab8",
        ["<C-9>"] = "tab9",
        ["<C-0>"] = "tablast",

        ["<S-Arrow>"] = "select",
        ["<C-S-Arrow>"] = "selectword",
        ["<M-S-Arrow>"] = "blockselect",
        ["<C-M-S-Arrow>"] = "blockselectword",
        ["<C-A>"] = "selectall",
        ["<C-Arrow>"] = "stopselect and replayinput",

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

        ["<C-B>"] = "build",
        ["<C-M-B>"] = "rebuild",
        ["<F17>"] = "run",
        ["<F29>"] = "run",
        ["<F5>"] = "continue or run",
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
        ["<C-T>a"] = "attach_test",

        ["<F18>"] = "ai_chat",
        ["<F6>"] = "ai_prompt"
    },
    menus =
    {
        popup =
        {
            { "commands", position = ".100" },
            { "split", position = ".100" },
            { "vsplit", position = ".100" },
            { "autohide", position = ".100" },
            { "close", position = ".100" },
            { "-top-", position = ".100" },
            "cut",
            "copy",
            "paste",
            "delete",
            "selectall",
            "openurl",
            "inspect",
            "-bottom-",
            "definition",
            "references",
            "rename",
            "code_action",
            "format_selection",
            "comment"
        },
        statusline =
        {
            "file_explorer",
            "code_outline",
            "diagnostics",
            "debugger",
            "test_explorer",
            "test_output",
            "-",
            "terminal",
            "messages",
            "checkhealth"
        },
        tabline =
        {
            "tabpin",
            "tabrestore",
            "tabclose",
            "tabcloseall",
            "tabcloseothers",
            "tabcloseleft",
            "tabcloseright",
            "tabcloseunpinned"
        },
        cmdline =
        {
            "file_explorer",
            "code_outline",
            "diagnostics",
            "debugger",
            "test_explorer",
            "test_output",
            "-",
            "terminal",
            "messages",
            "checkhealth"
        },
        border =
        {
            "file_explorer",
            "code_outline",
            "diagnostics",
            "debugger",
            "test_explorer",
            "test_output",
            "-",
            "terminal",
            "messages",
            "checkhealth"
        }
    }
}

function M.apply(options)
    return vim.tbl_deep_extend("force", options, defaults)
end

return M
