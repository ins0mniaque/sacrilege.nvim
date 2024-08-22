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

    local keys = vim.tbl_keys(items)

    table.sort(keys, sort)

    vim.ui.select(keys, { prompt = prompt }, callback)
end

function M.command_palette(buffer)
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
        parse(vim.api.nvim_get_keymap(mode))
        parse(vim.api.nvim_buf_get_keymap(0, mode))
    else
        parse(vim.api.nvim_buf_get_keymap(buffer, mode))
    end

    M.select(localize("Commands"), commands, function(l, r) return l:lower() < r:lower() end)
end

function M.command_menu(buffer)
    local function generate(keymaps)
        for _, keymap in pairs(keymaps) do
            if keymap.desc then
                vim.cmd.amenu("Sacrilege.CommandMenu." .. keymap.desc:gsub(" ", "\\ "):gsub("%.", "\\."):gsub("&", "&&") .. " " .. keymap.lhs)
            end
        end
    end

    local mode = vim.fn.mode()
    if     mode == "s" or mode == "S" or mode == "\19" then mode = "s"
    elseif mode == "v" or mode == "V" or mode == "\22" then mode = "v"
    elseif mode ~= "i"                                 then mode = "n"
    end

    pcall(vim.cmd.aunmenu, "Sacrilege.CommandMenu")

    if not buffer then
        generate(vim.api.nvim_get_keymap(mode))
        generate(vim.api.nvim_buf_get_keymap(0, mode))
    else
        generate(vim.api.nvim_buf_get_keymap(buffer, mode))
    end

    return pcall(vim.cmd.popup, "Sacrilege.CommandMenu")
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
