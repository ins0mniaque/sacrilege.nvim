local M = { }

function M.send(keys, remap)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), remap and "t" or "n", true)
end

function M.input(prompt, defaultOrCallback, callback)
    if vim.fn.mode() == "c" then
        M.send("<C-r>")
    end

    vim.ui.input({ prompt = prompt, default = callback and defaultOrCallback }, function(arg)
        if not arg then return end

        (callback or defaultOrCallback)(arg)
    end)
end

function M.select(prompt, items, sort)
    if vim.fn.mode() == "c" then
        M.send("<C-r>")
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

function M.get_selected_text()
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

function M.try_close_popup()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative == 'win' then
            vim.api.nvim_win_close(win, true)
            return true
        end
    end

    return false
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

    M.select("Commands", commands, function(l, r) return l:lower() < r:lower() end)
end

function M.browse()
    local paths   = vim.split(vim.fn.glob(vim.fn.getcwd() .. "/*"), '\n', { trimempty = true })
    local entries = { [".."] = function() vim.cmd("cd ..") M.browse() end }

    for _, path in pairs(paths) do
        if vim.fn.isdirectory(path) ~= 0 then
            entries[path] = function()
                vim.cmd("cd " .. path)

                M.browse()
            end
        else
            entries[path] = function()
                vim.cmd.tabnew(path)
            end
        end
    end

    M.select("Open", entries, function(l, r) return l:lower() < r:lower() end)
end

function M.find()
    M.input("Find: ", M.get_selected_text():gsub("\n", "\\n"), function(text)
        M.send("<C-\\><C-N><C-\\><C-N>/" .. text .. "<CR>")
    end)
end

function M.replace()
    M.input("Replace: ", M.get_selected_text():gsub("\n", "\\n"), function(old_text)
        M.input("Replace with: ", old_text, function(new_text)
            M.send("<Cmd>%s/" .. old_text .. "/" .. new_text .. "/g<CR>")
        end)
    end)
end

function M.find_in_files()
    M.input("Find in files: ", M.get_selected_text():gsub("\n", "\\n"), function(text)
        vim.cmd("vimgrep " .. text .. " **/*")
    end)
end

function M.go_to_line()
    M.input("Line Number: ", function(line)
        vim.api.nvim_win_set_cursor(0, { tonumber(line), 0 })
    end)
end

function M.save()
    if vim.fn.expand("%") == "" then
        M.input("Save to: ", vim.cmd.write)
    else
        vim.cmd.write()
    end
end

function M.saveas()
    M.input("Save as: ", vim.cmd.saveas)
end

return M