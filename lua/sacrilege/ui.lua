local localize = require("sacrilege.localizer").localize
local editor = require("sacrilege.editor")

local M = { }

function M.input(prompt, defaultOrCallback, callback)
    if vim.fn.mode() == "c" then
        editor.send("<C-r>")
    end

    vim.ui.input({ prompt = prompt, default = callback and defaultOrCallback }, function(arg)
        if not arg then return end

        (callback or defaultOrCallback)(arg)
    end)
end

function M.select(prompt, items, sort)
    if vim.fn.mode() == "c" then
        editor.send("<C-r>")
    end

    local function callback(choice)
        if not choice then return end

        local action = items[choice]

        if     type(action) == "function" then action()
        elseif type(action) == "string"   then vim.cmd(action)
        end
    end

    local keys = type(sort) == "table" and sort or vim.tbl_keys(items)

    if type(sort) == "function" then
        table.sort(keys, sort)
    end

    vim.ui.select(keys, { prompt = prompt }, callback)
end

function M.quickfix(title, items, opts)
    vim.fn.setqflist(items, "r")
    vim.cmd("botright copen")
end

function M.make(args, background)
    vim.cmd.make { args = args, bang = not background }
end

function M.commands(buffer, opts)
    local commands = { }
    local title    = opts and opts.title or "Commands"

    local selstart = vim.fn.getpos('v')
    local cursor   = vim.fn.getpos('.')

    local function parse_commands(cmds)
        -- NOTE: Remove non-command entry from nvim_buf_get_commands
        cmds[true] = nil

        for _, cmd in pairs(cmds) do
            if cmd.nargs == "0" or cmd.nargs == "?" or cmd.nargs == "*" then
                local desc = cmd.name

                if #cmd.definition > 0 and
                   not cmd.definition:match("^:") and
                   not cmd.definition:match("^lua") and
                   not cmd.definition:match("^call") and
                   not cmd.definition:match("^exe") and
                   not cmd.definition:match("|") then
                    desc = cmd.definition
                end

                commands[string.format("%-48s %s", desc, ":" .. cmd.name)] = vim.cmd[cmd.name]
            end
        end
    end

    local function parse_keymaps(keymaps)
        for _, keymap in pairs(keymaps) do
            if keymap.desc then
                commands[string.format("%-48s %s", keymap.desc, keymap.lhs:gsub("%s", "<Space>"))] = function()
                    if keymap.mode == "i" then
                        vim.cmd.startinsert()
                    elseif keymap.mode == "n" then
                        vim.cmd("normal! :noh")
                    elseif keymap.mode == "v" or keymap.mode == "s" then
                        vim.fn.setpos('.', selstart)
                        vim.cmd("normal! v")
                        vim.fn.setpos('.', cursor)
                    end

                    editor.send(keymap.lhs, true)
                end
            end
        end
    end

    local mode = vim.fn.mode()
    if     mode == "s" or mode == "S" or mode == "\19" then mode = "s"
    elseif mode == "v" or mode == "V" or mode == "\22" then mode = "v"
    elseif mode ~= "i"                                 then mode = "n"
    end

    if not buffer then
        parse_commands(vim.api.nvim_get_commands({ }))
        parse_commands(vim.api.nvim_buf_get_commands(0, { }))
        parse_keymaps(vim.api.nvim_get_keymap(mode))
        parse_keymaps(vim.api.nvim_buf_get_keymap(0, mode))
    else
        parse_commands(vim.api.nvim_buf_get_commands(0, { }))
        parse_keymaps(vim.api.nvim_buf_get_keymap(buffer, mode))
    end

    M.select(localize(title), commands, function(l, r) return l:lower() < r:lower() end)
end

function M.tasks()
    local keys =
    {
        localize("Build"),
        localize("Run"),
        localize("Run Tests"),
        localize("Clean")
    }

    local tasks =
    {
        [keys[1]] = function() M.make()        end,
        [keys[2]] = function() M.make("run")   end,
        [keys[3]] = function() M.make("check") end,
        [keys[4]] = function() M.make("clean") end
    }

    M.select(localize("Tasks"), tasks, keys)
end

function M.compilers()
    local compilers = { }

    for _, compiler in pairs(vim.fn.getcompletion("", "compiler")) do
        compilers[compiler] = function()
            pcall(vim.cmd.compiler, compiler)
        end
    end

    M.select(localize("Compilers"), compilers, function(l, r) return l:lower() < r:lower() end)
end

function M.themes()
    local colorschemes = { }

    for _, colorscheme in pairs(vim.fn.getcompletion("", "color")) do
        colorschemes[colorscheme] = function()
            pcall(vim.cmd.colorscheme, colorscheme)
        end
    end

    M.select(localize("Themes"), colorschemes, function(l, r) return l:lower() < r:lower() end)
end

function M.browse(directory)
    directory = directory or vim.fn.getcwd()

    local paths   = vim.split(vim.fn.glob(directory:gsub("/$", "") .. "/*"), '\n', { trimempty = true })
    local entries = { }

    local parent = vim.fn.fnamemodify(directory, ":h")
    if parent and parent ~= directory then
        entries[".."] = function() M.browse(parent) end
    end

    for _, path in pairs(paths) do
        entries[path] = function()
            if vim.fn.isdirectory(path) ~= 0 then
                M.browse(path)
            else
                vim.cmd.tabnew(path)
            end
        end
    end

    M.select(localize("Open"), entries, function(l, r) return l:lower() < r:lower() end)
end

function M.find()
    M.input(localize("Find: "), editor.get_selected_text():gsub("\n", "\\n"), function(text)
        vim.cmd("/" .. text)
    end)
end

function M.replace()
    M.input(localize("Replace: "), editor.get_selected_text():gsub("\n", "\\n"), function(old_text)
        vim.cmd("/" .. old_text)

        M.input("Replace with: ", old_text, function(new_text)
            vim.cmd("%s/" .. old_text .. "/" .. new_text .. "/g")
        end)
    end)
end

function M.find_in_files()
    M.input(localize("Find in files: "), editor.get_selected_text():gsub("\n", "\\n"), function(text)
        vim.cmd("silent vimgrep " .. text .. " **/*")
        vim.cmd.cwindow()
        vim.cmd.wincmd("p")
    end)
end

function M.replace_in_files()
    M.input(localize("Replace in files: "), editor.get_selected_text():gsub("\n", "\\n"), function(old_text)
        vim.cmd("silent vimgrep " .. old_text .. " **/*")
        vim.cmd.cwindow()
        vim.cmd.wincmd("p")

        vim.defer_fn(function()
            M.input("Replace with: ", old_text, function(new_text)
                vim.cmd.cfdo("%s/" .. old_text .. "/" .. new_text .. "/g")
            end)
        end, 0)
    end)
end

function M.go_to_line()
    M.input(localize("Line Number: "), function(line)
        vim.api.nvim_win_set_cursor(0, { tonumber(line), 0 })
    end)
end

function M.save()
    if vim.fn.expand("%") == "" then
        M.input(localize("Save to: "), vim.cmd.write)
    else
        vim.cmd.write()
    end
end

function M.saveas()
    M.input(localize("Save as: "), vim.cmd.saveas)
end

return M
