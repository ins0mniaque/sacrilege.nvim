local M = { }

local defaults =
{
    insertmode = true,
    selectmode = true,
    mouse      = true,
    tab        = true,
    comment    = true,
    common     = true,
    clipboard  = true,
    undo       = true,
    find       = true,
    format     = true,
    treesitter = true,
    dap        = true,
    lsp        = true,
    tests      = true
}

local options = { }

local metakeys  = vim.tbl_keys(defaults)
local metatable =
{
    __index = function(table, key)
        return vim.list_contains(metakeys, key) and options[key] or rawget(table, key)
    end,

    __newindex = function(table, key, value)
        if key == "insertmode" then 
            options.insertmode = value

            M.trigger()
        elseif vim.list_contains(metakeys, key) then 
            vim.notify(key .. " cannot be changed after setup", vim.log.levels.ERROR, { title = "sacrilege.nvim" })
        else
            rawset(table, key, value)
        end
    end
}

setmetatable(M, metatable)

local function send(keys, remap)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), remap and "t" or "n", true)
end

local function input(prompt, callback, default)
    vim.ui.input({ prompt = prompt, default = default }, function(arg)
        if not arg then return end

        callback(arg)
    end)
end

local function select(prompt, items, sort)
    local function callback(choice)
        if not choice then return end

        local action = items[choice]

        if     type(action) == "function" then action()
        elseif type(action) == "string"   then vim.cmd(action)
        end
    end

    local keys = vim.tbl_keys(items)

    table.sort(keys, sort)

    vim.ui.select(keys, { prompt = prompt }, callback)
end

local function try_close_popup()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative == 'win' then
            vim.api.nvim_win_close(win, true)
            return true
        end
    end

    return false
end

local function get_selected_text()
    local s_start = vim.fn.getpos("v")
    local s_end = vim.fn.getpos(".")
    local n_lines = math.abs(s_end[2] - s_start[2]) + 1
    local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
    lines[1] = string.sub(lines[1], s_start[3], -1)
    if n_lines == 1 then
      lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3])
    else
      lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
    end
    return table.concat(lines, '\n')
  end

function M.setup(opts)
    if vim.fn.has("nvim-0.7.0") ~= 1 then
        return vim.notify("sacrilege.nvim requires Neovim >= 0.7.0", vim.log.levels.ERROR, { title = "sacrilege.nvim" })
    end

    options = vim.tbl_deep_extend("force", defaults, opts or { }) or { }

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TermLeave" },
    {
        group = vim.api.nvim_create_augroup("Sacrilege", { }),
        pattern = { "*" },
        callback = function(event)
            M.trigger()
        end
    })

    M.trigger()

    local function escape()
        if vim.snippet and vim.snippet.active() then
            vim.snippet.stop()
        end

        vim.cmd("nohl")
        vim.cmd("stopinsert")
        vim.cmd("startinsert")

        if not try_close_popup() and not options.insertmode then
            send("<Esc>")
        end
    end

    vim.keymap.set("i", "<Esc>", escape, { desc = "Escape" })
    vim.keymap.set("i", "<C-c>", function() return options.insertmode and "" or "<C-c>" end, { expr = true })
    vim.keymap.set("i", "<C-M-c>", "<Esc>:", { desc = "Command Line Mode" })
    vim.keymap.set("i", "<C-M-t>", "<Cmd>terminal<CR>", { desc = "Terminal" })

    if options.selectmode then
        vim.opt.keymodel    = { }
        vim.opt.selection   = "exclusive"
        vim.opt.selectmode  = { "mouse", "key", "cmd" }
        vim.opt.virtualedit = "block"

        if vim.snippet then
            vim.api.nvim_create_autocmd({ "ModeChanged" },
            {
                group = vim.api.nvim_create_augroup("Sacrilege.SnippetMode", { }),
                pattern = { "*:s" },
                callback = function(event)
                    vim.opt.selection = vim.snippet.active() and "inclusive" or "exclusive"
                end
            })
        end

        vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select All" })
        vim.keymap.set("v", "<C-a>", "gg0oG$", { desc = "Select All" })
        vim.keymap.set("i", "<C-a>", "<C-Home><C-O>VG", { desc = "Select All" })

        vim.keymap.set({ "n", "i", "s" }, "<M-LeftMouse>", "<4-LeftMouse>", { desc = "Start block selection" })
        vim.keymap.set({ "n", "i", "s" }, "<M-LeftDrag>", "<LeftDrag>", { desc = "Block selection" })
        vim.keymap.set({ "n", "i", "s" }, "<M-LeftRelease>", "", { desc = "End block selection" })

        local function map_mode(mode, rhs, otherwise)
            return function() return vim.fn.mode() == mode and rhs or otherwise or "" end
        end

        local function map_arrow_selection(arrow)
            vim.keymap.set("i", "<S-" .. arrow .. ">", "<C-o>v<C-g><" .. arrow .. ">", { desc = "Select character" })
            vim.keymap.set("i", "<C-S-" .. arrow .. ">", "<C-o>v<C-g><C-" .. arrow .. ">", { desc = "Select word" })
            vim.keymap.set("i", "<M-S-" .. arrow .. ">", "<C-o><C-v><C-g><" .. arrow .. ">", { desc = "Block select character" })
            vim.keymap.set("i", "<C-M-S-" .. arrow .. ">", "<C-o><C-v><C-g><C-" .. arrow .. ">", { desc = "Block select word" })
            vim.keymap.set("s", "<S-" .. arrow .. ">", "<" .. arrow .. ">", { desc = "Select character" })
            vim.keymap.set("s", "<C-S-" .. arrow .. ">", "<C-" .. arrow .. ">", { desc = "Select word" })
            vim.keymap.set("s", "<M-S-" .. arrow .. ">", map_mode("\19", "<" .. arrow .. ">", "<C-o><C-v><C-g><" .. arrow .. "><C-g>"), { expr = true, desc = "Block select character" })
            vim.keymap.set("s", "<C-M-S-" .. arrow .. ">", map_mode("\19", "<C-" .. arrow .. ">", "<C-o><C-v><C-g><C-" .. arrow .. "><C-g>"), { expr = true, desc = "Block select word" })
            vim.keymap.set("s", "<" .. arrow .. ">", "<Esc><" .. arrow .. ">", { desc = "Stop selection" })
            vim.keymap.set("s", "<C-" .. arrow .. ">", "<Esc><C-" .. arrow .. ">", { desc = "Stop selection" })
        end

        map_arrow_selection("Up")
        map_arrow_selection("Down")
        map_arrow_selection("Left")
        map_arrow_selection("Right")
    end

    -- TODO: Fix menu not working in SELECT mode
    if options.mouse then
        vim.opt.mouse      = "a"
        vim.opt.mousemodel = "popup_setpos"

        pcall(vim.cmd.aunmenu, "PopUp.-1-")
        pcall(vim.cmd.aunmenu, "PopUp.How-to\\ disable\\ mouse")

        local menus =
        {
            { "Command Palette...", "<C-p>", position = ".100" },
            { "Close", "<C-w>", position = ".100" },
            { "-top-", position = ".100" },
            { "-bottom-" },
            { "Go to Definition", "<F12>" },
            { "Find All References...", "<F24>" },
            { "Rename", "<C-r>" },
            { "Code Action", "<M-a>" },
            { "Hover", "<F1>" },
            { "Format Selection", "<M-f>", selection = true },
            { "Toggle Selection Line Comment", "<C-/>", selection = true }
        }

        for _, menu in pairs(menus) do
            local menucmd = menu.selection and vim.cmd.vmenu or vim.cmd.amenu

            if not menu[1]:find("^-") then
                menu[1] = menu[1]:gsub(" ", "\\ "):gsub("%.", "\\.")
                menucmd((menu.position or "") .. " PopUp." .. menu[1] .. " " .. menu[2])
                menucmd("disable PopUp." .. menu[1])
            else
                menucmd((menu.position or "") .. " PopUp." .. menu[1] .. " :")
            end
        end

        vim.api.nvim_create_autocmd({ "MenuPopup" },
        {
            group = vim.api.nvim_create_augroup("Sacrilege.PopUp", { }),
            pattern = { "*" },
            callback = function(event)
                local mode = vim.fn.mode()
                if     mode == "s" or mode == "S" or mode == "\19" then mode = "s"
                elseif mode == "v" or mode == "V" or mode == "\22" then mode = "x"
                elseif mode ~= "i"                                 then mode = "n"
                end

                for _, menu in pairs(menus) do
                    local menucmd = menu.selection and vim.cmd.vmenu or vim.cmd.amenu

                    if not menu[1]:find("^-") then
                        local verb = vim.fn.maparg(menu[2], mode) ~= "" and "enable" or "disable"

                        menucmd(verb .. " PopUp." .. menu[1])
                    end
                end
            end
        })
    end

    if options.tab then
        local function map_snippet(direction, rhs)
            return function() return rhs or "" end
        end

        if vim.snippet then
            map_snippet = function(direction, rhs)
                return function()
                    if vim.snippet.active({ direction = direction }) then
                        return "<Cmd>lua vim.snippet.jump(".. direction ..")<CR>"
                    end

                    return rhs or ""
                end
            end
        end

        vim.keymap.set("i", '<Tab>', map_snippet(1, "<Tab>"), { expr = true, desc = "Tab" })
        vim.keymap.set("s", '<Tab>', map_snippet(1, "<C-O>>gv"), { expr = true, desc = "Indent" })
        vim.keymap.set("i", '<S-Tab>', map_snippet(-1, "<C-d>"), { expr = true, desc = "Unindent" })
        vim.keymap.set("s", '<S-Tab>', map_snippet(-1, "<C-O><gv"), { expr = true, desc = "Unindent" })
    end

    if options.comment then
        vim.keymap.set("i", "<C-_>", "<C-\\><C-N>gcci", { desc = "Toggle Line Comment", remap = true })
        vim.keymap.set("s", "<C-_>", function() send("<C-g>") send("gc", true) send("<C-\\><C-N><C-g>gv") end, { desc = "Toggle Line Comment" })
    end

    if options.common then
        vim.keymap.set({ "n", "i", "s" }, "<C-n>", vim.cmd.tabnew, { desc = "New tab" })
        vim.keymap.set({ "n", "i", "s" }, "<C-o>", M.file_browser, { desc = "Open..." })
        vim.keymap.set({ "n", "i", "s" }, "<C-s>", function() if vim.fn.expand("%") == "" then input("Save to: ", vim.cmd.write) else vim.cmd.write() end end, { desc = "Save" })
        vim.keymap.set({ "n", "i", "s" }, "<C-M-s>", function() input("Save as: ", vim.cmd.saveas) end, { desc = "Save As..." })
        vim.keymap.set({ "n", "i", "s" }, "<C-w>", "<Cmd>confirm quit<CR>", { desc = "Close" })
        vim.keymap.set({ "n", "i", "s" }, "<F28>", "<Cmd>confirm quit<CR>", { desc = "Close" })
        vim.keymap.set({ "n", "i", "s" }, "<C-q>", "<Cmd>confirm quitall<CR>", { desc = "Quit" })
        vim.keymap.set({ "n", "i", "s" }, "<F52>", "<Cmd>confirm quitall<CR>", { desc = "Quit" })

        vim.keymap.set({ "n", "i", "s" }, "<C-p>", M.command_palette, { desc = "Command Palette..." })
        vim.keymap.set({ "n", "i", "s" }, "<C-d>", vim.diagnostic.setloclist, { desc = "Toggle Diagnostics" })
    end

    if options.clipboard then
        vim.keymap.set("v", "<C-C>", "\"+y", { desc = "Copy" })
        vim.keymap.set("v", "<C-X>", "\"+x", { desc = "Cut" })
        vim.keymap.set("v", "<C-V>", "\"+P", { desc = "Paste" })
        vim.keymap.set("n", "<C-V>", "\"+gP", { desc = "Paste" })
        vim.keymap.set("o", "<C-V>", "<C-C>\"+gP<C-\\><C-G>", { desc = "Paste" })
        vim.keymap.set("i", "<C-V>", "<C-\\><C-O>\"+gP", { desc = "Paste" })
        vim.keymap.set("c", "<C-V>", "<C-C>\"+gP<C-\\><C-G>", { desc = "Paste" })
        vim.keymap.set("v", "<C-V>", "\"_x", { desc = "Delete" })
    end

    if options.undo then
        vim.keymap.set({ "n", "i", "s" }, "<C-z>", "<C-O>u", { desc = "Undo" })
        vim.keymap.set({ "n", "i", "s" }, "<C-M-z>", "<C-O><C-r>", { desc = "Redo" })
        vim.keymap.set({ "n", "i", "s" }, "<C-y>", "<C-O><C-r>", { desc = "Redo" })
    end

    if options.find then
        vim.keymap.set({ "n", "i", "s" }, "<C-f>", function() input("Find: ", function(arg) send("<C-\\><C-N><C-\\><C-N>/"..arg.."<CR>") end, get_selected_text():gsub("\n", "\\n")) end, { desc = "Find..." })
        vim.keymap.set({ "n", "i", "s" }, '<F15>', '<C-\\><C-N><C-\\><C-N><Left>gN', { desc = "Find Previous" })
        vim.keymap.set({ "n", "i", "s" }, '<F3>', '<C-\\><C-N><C-\\><C-N>gn', { desc = "Find Next" })
        vim.keymap.set({ "n", "i", "s" }, "<C-h>", function() input("Replace: ", function(arg) input("Replace with: ", function(arg2) send("<Cmd>%s/" .. arg .. "/" .. arg2 .. "/g<CR>") end, arg) end, get_selected_text():gsub("\n", "\\n")) end, { desc = "Replace..." })
        vim.keymap.set({ "n", "i", "s" }, "<C-M-f>", function() input("Find in files: ", function(arg) vim.cmd("vimgrep " .. arg .. " **/*") end) end, { desc = "Find in files..." })
        vim.keymap.set({ "n", "i", "s" }, "<C-g>", function() input("Line Number: ", function(line) vim.api.nvim_win_set_cursor(0, { tonumber(line), 0 }) end) end, { desc = "Go to Line..." })
    end

    if options.format then
        vim.keymap.set("n", "<M-f>", "gg=G", { desc = "Format Buffer" })
        vim.keymap.set("i", "<M-f>", "<C-\\><C-N><C-\\><C-N>gg=G", { desc = "Format Buffer" })
        vim.keymap.set("s", "<M-f>", "<C-O>=gv", { desc = "Format Selection" })
    end

    if options.dap then
        vim.keymap.set({ "n", "i", "s" }, "<F5>", function() require("dap").continue() end, { desc = "Debug: Start/Continue" })
        vim.keymap.set({ "n", "i", "s" }, "<F11>", function() require("dap").step_into() end, { desc = "Debug: Step Into" })
        vim.keymap.set({ "n", "i", "s" }, "<F10>", function() require("dap").step_over() end, { desc = "Debug: Step Over" })
        vim.keymap.set({ "n", "i", "s" }, "<F23>", function() require("dap").step_out() end, { desc = "Debug: Step Out" })
        vim.keymap.set({ "n", "i", "s" }, "<F9>", function() require("dap").toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
        vim.keymap.set({ "n", "i", "s" }, "<F21>", function() input("Breakpoint condition: ", require("dap").set_breakpoint) end, { desc = "Debug: Set Conditional Breakpoint" })
    end

    if options.treesitter then
        local treesitter = require("sacrilege.treesitter")

        local function supports_lsp_method(bufnr, method)
            local clients = vim.lsp.get_clients()
            for _, client in pairs(clients) do
                if vim.lsp.buf_is_attached(bufnr, client.id) and client.supports_method(method) then 
                    return true
                end
            end

            return false
        end

        vim.api.nvim_create_autocmd("FileType",
        {
            group = vim.api.nvim_create_augroup("Sacrilege.Treesitter", { }),
            pattern = { "*" },
            callback = function(event)
                local ft   = vim.api.nvim_get_option_value("ft", { buf = event.buf })
                local lang = vim.treesitter.language.get_lang(ft)

                if not lang or #lang == 0 then
                    return
                end

                if not options.lsp or not supports_lsp_method(event.buf, vim.lsp.protocol.Methods.textDocument_definition) then
                    vim.keymap.set({ "n", "i", "s" }, "<F12>", treesitter.definition, { buffer = event.buf, desc = "Go to Definition" })
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>d", treesitter.definition, { buffer = event.buf, desc = "Go to Definition" })
                end

                if not options.lsp or not supports_lsp_method(event.buf, vim.lsp.protocol.Methods.textDocument_references) then
                    vim.keymap.set({ "n", "i", "s" }, "<F24>", treesitter.references, { buffer = event.buf, desc = "Find all references..." })
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>r", treesitter.references, { buffer = event.buf, desc = "Find all references..." })
                end

                if not options.lsp or not supports_lsp_method(event.buf, vim.lsp.protocol.Methods.textDocument_rename) then
                    vim.keymap.set({ "n", "i", "s" }, "<F2>", treesitter.rename, { buffer = event.buf, desc = "Rename..." })
                    vim.keymap.set({ "n", "i", "s" }, "<C-r>", treesitter.rename, { buffer = event.buf, desc = "Rename..." })
                end
            end
        })
    end

    if options.lsp then
        vim.api.nvim_create_autocmd("LspAttach",
        {
            group = vim.api.nvim_create_augroup("Sacrilege.Lsp", { }),
            callback = function(event)
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if not client then
                    return
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_hover) then
                    vim.keymap.set({ "n", "i", "s" }, "<F1>", function() try_close_popup() vim.lsp.buf.hover() end, { buffer = event.buf, desc = "Hover" })
                elseif client.supports_method(vim.lsp.protocol.Methods.textDocument_signatureHelp) then
                    vim.keymap.set({ "n", "i", "s" }, "<F1>", function() try_close_popup() vim.lsp.buf.signature_help() end, { buffer = event.buf, desc = "Hover" })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_definition) then
                    vim.keymap.set({ "n", "i", "s" }, "<F12>", vim.lsp.buf.definition, { buffer = event.buf, desc = "Go to Definition" })
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>d", vim.lsp.buf.definition, { buffer = event.buf, desc = "Go to Definition" })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_references) then
                    vim.keymap.set({ "n", "i", "s" }, "<F24>", vim.lsp.buf.references, { buffer = event.buf, desc = "Find all References..." })
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>r", vim.lsp.buf.references, { buffer = event.buf, desc = "Find all References..." })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_implementation) then
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>i", vim.lsp.buf.implementation, { buffer = event.buf, desc = "Go to Implementation" })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_typeDefinition) then
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>t", vim.lsp.buf.type_definition, { buffer = event.buf, desc = "Go to Type Definition" })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_documentSymbol) then
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>s", vim.lsp.buf.document_symbol, { buffer = event.buf, desc = "Find in Document Symbols..." })
                end

                if client.supports_method(vim.lsp.protocol.Methods.workspace_symbol) then
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>S", vim.lsp.buf.workspace_symbol, { buffer = event.buf, desc = "Find in Workspace Symbols..." })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_declaration) then
                    vim.keymap.set({ "n", "i", "s" }, "<C-g>D", vim.lsp.buf.declaration, { buffer = event.buf, desc = "Go to Declaration" })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_rename) then
                    vim.keymap.set({ "n", "i", "s" }, "<F2>", vim.lsp.buf.rename, { buffer = event.buf, desc = "Rename" })
                    vim.keymap.set({ "n", "i", "s" }, "<C-r>", vim.lsp.buf.rename, { buffer = event.buf, desc = "Rename" })
                end

                if client.supports_method(vim.lsp.protocol.Methods.textDocument_codeAction) then
                    vim.keymap.set({ "n", "i", "s" }, "<F49>", vim.lsp.buf.code_action, { buffer = event.buf, desc = "Code Action" })
                    vim.keymap.set({ "n", "i", "s" }, "<M-a>", vim.lsp.buf.code_action, { buffer = event.buf, desc = "Code Action" })
                end

                if options.format then
                    if client.supports_method(vim.lsp.protocol.Methods.textDocument_formatting) then
                        vim.keymap.set({ "n", "i" }, "<M-f>", function() vim.lsp.buf.format({ async = true }) end, { buffer = event.buf, desc = "Format Buffer" })
                    end

                    if client.supports_method(vim.lsp.protocol.Methods.textDocument_rangeFormatting) then
                        vim.keymap.set("s", "<M-f>", function() vim.lsp.buf.format({ async = true, range = { start = vim.api.nvim_buf_get_mark(0, "<"), ["end"] = vim.api.nvim_buf_get_mark(0, ">") } }) end, { buffer = event.buf, desc = "Format Selection" })
                    end
                end
 
                if client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                    vim.keymap.set({ "n", "i", "s" }, "<F13>", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, { buffer = event.buf, desc = "Toggle Hints" })
                end
            end
        })
    end

    if options.tests then
        vim.keymap.set({ "n", "i", "s" }, "<C-t>r", function() require("neotest").run.run() end, { desc = "Run Current Test" })
        vim.keymap.set({ "n", "i", "s" }, "<C-t>R", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run All Tests" })
        vim.keymap.set({ "n", "i", "s" }, "<C-t>d", function() require("neotest").run.run({strategy = "dap"}) end, { desc = "Debug Current Test" })
        vim.keymap.set({ "n", "i", "s" }, "<C-t>s", function() require("neotest").run.stop() end, { desc = "Stop Current Test" })
        vim.keymap.set({ "n", "i", "s" }, "<C-t>a", function() require("neotest").run.attach() end, { desc = "Attach Current Test" })
    end
end

function M.desecrate()
    if vim.bo.modifiable and
       not vim.bo.readonly and
       vim.bo.buftype ~= "nofile" or
       vim.bo.buftype == "terminal"
    then
        vim.cmd.startinsert()
    else
        vim.cmd.stopinsert()
    end
end

function M.trigger()
    if options.insertmode then
        vim.defer_fn(M.desecrate, 0)
    end
end

function M.command_palette()
    local commands = { }

    local selstart = vim.fn.getpos('v')
    local cursor   = vim.fn.getpos('.')

    local function parse(keymaps)
        for _, keymap in pairs(keymaps) do
            if keymap.desc then
                commands[string.format("%-48s %s", keymap.desc, keymap.lhs)] = function()
                    if keymap.mode == "i" then
                        vim.cmd.startinsert()
                    elseif keymap.mode == "n" then
                        vim.cmd("normal! :noh")
                    elseif keymap.mode == "v" or keymap.mode == "s" then
                        vim.fn.setpos('.', selstart)
                        vim.cmd("normal! v")
                        vim.fn.setpos('.', cursor)
                    end

                    send(keymap.lhs, true)
                end
            end
        end
    end

    local mode = vim.fn.mode()
    if     mode == "s" or mode == "S" or mode == "\19" then mode = "s"
    elseif mode == "v" or mode == "V" or mode == "\22" then mode = "v"
    elseif mode ~= "i"                                 then mode = "n"
    end

    parse(vim.api.nvim_get_keymap(mode))
    parse(vim.api.nvim_buf_get_keymap(0, mode))

    select("Commands", commands, function(l, r) return l:lower() < r:lower() end)
end

function M.file_browser()
    local cwdContent = vim.split(vim.fn.glob(vim.fn.getcwd() .. "/*"), '\n', { trimempty = true })

    local items = { [".."] = function() vim.cmd("cd ..") M.file_browser() end }

    for _, cwdItem in pairs(cwdContent) do
        if vim.fn.isdirectory(cwdItem) ~= 0 then
            items[cwdItem] = function()
                vim.cmd("cd " .. cwdItem)

                M.file_browser()
            end
        else
            items[cwdItem] = function()
                vim.cmd.tabnew(cwdItem)
            end
        end
    end

    select("Open File", items, function(l, r) return l:lower() < r:lower() end)
end

return M