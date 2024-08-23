local editor = require("sacrilege.editor")

local M = { }

local function longest_common_prefix(left, right)
    local length = 1
    local prefix = ""

    while length <= #left and length <= #right do
        local sub = right:sub(1, length)
        if left:sub(1, length) ~= sub then
            return prefix
        end
        prefix = sub
        length = length + 1
    end

    return prefix
end

local function longest_common_suffix(left, right)
    local length = 1
    local suffix = ""

    while length <= #left and length <= #right do
        local sub = right:sub(-length)
        if left:sub(-length) ~= sub then
            return suffix
        end
        suffix = sub
        length = length + 1
    end

    return suffix
end

local function remove_affixes(keymaps)
    local prefix, suffix

    for _, keymap in pairs(keymaps) do
        if keymap.desc then
            if not prefix then
                prefix = keymap.desc
                suffix = keymap.desc
            else
                prefix = longest_common_prefix(prefix, keymap.desc)
                suffix = longest_common_suffix(suffix, keymap.desc)
            end
        end
    end

    if prefix and prefix:match("[%s%p]$") then
        for _, keymap in pairs(keymaps) do
            if keymap.desc then
                keymap.desc = keymap.desc:sub(#prefix + 1)
            end
        end
    end

    if suffix and suffix:match("^[%s%p]") then
        for _, keymap in pairs(keymaps) do
            if keymap.desc then
                keymap.desc = keymap.desc:sub(1, -#suffix)
            end
        end
    end
end

function M.escape(name)
    return name:gsub(" ", "\\ "):gsub("%.", "\\."):gsub("&", "&&")
end

function M.create(name, keymaps)
    local distinct = { }

    keymaps = vim.tbl_filter(function(keymap)
        if keymap.desc and keymap.mode ~= "t" and not distinct[keymap.desc] then
            distinct[keymap.desc] = true
            return true
        end

        return false
    end, keymaps)

    -- TODO: Add "More..." menu and resize menus on screen height change
    if #keymaps > vim.o.lines / 2 then
        table.sort(keymaps, function(l, r) return #l.desc < #r.desc end)
        keymaps = vim.list_slice(keymaps, 1, vim.o.lines / 2)
    end

    remove_affixes(keymaps)

    table.sort(keymaps, function(l, r) return l.desc:lower() < r.desc:lower() end)

    name = M.escape(name)

    pcall(vim.cmd.aunmenu, name)

    if #keymaps == 0 then
        return false
    end

    for _, keymap in pairs(keymaps) do
        vim.cmd(keymap.mode .. "menu " .. name .. "." .. M.escape(keymap.desc) .. " " .. keymap.lhs)
    end

    return true
end

function M.popup()
    local mouse = vim.fn.getmousepos()

    if mouse.winid ~= 0 and mouse.winid ~= vim.api.nvim_get_current_win() then
        editor.send("<LeftMouse><LeftRelease>")
        vim.schedule(M.popup)
        return
    end

    local mapmode = editor.mapmode()
    local menu    = "PopUp"

    if mouse.winid == 0 then
        menu = "Border"

        if vim.o.lines - mouse.screenrow + 1 <= vim.o.cmdheight then
            menu = "CmdLine"
        elseif vim.o.laststatus == 3 then
            menu = "StatusLine"
        end
    elseif mouse.line == 0 then
        menu = "Border"

        if mouse.screenrow == 1 then
            menu = "TabLine"
        elseif vim.o.laststatus == 1 or vim.o.laststatus == 2 and mouse.winrow > vim.api.nvim_win_get_height(mouse.winid) then
            menu = "StatusLine"
        end
    elseif vim.bo.filetype ~= "" then
        menu = M.escape(vim.bo.filetype)
    end

    if not vim.fn.menu_info(menu, "").submenus then
        menu = "PopUp"

        if mapmode == "n" and (not vim.bo.modifiable or vim.bo.readonly) and vim.bo.filetype ~= "" then
            local keymaps = vim.api.nvim_buf_get_keymap(0, "n")

            if M.create(vim.bo.filetype, keymaps) then
                menu = M.escape(vim.bo.filetype)
            end
        end
    end

    if mapmode == "x" or mapmode == "s" then
        local start, cursor = editor.get_selection()
        if (mouse.line >= start[2] and mouse.line <= cursor[2]) or
           (mouse.line >= cursor[2] and mouse.line <= start[2]) then
            vim.cmd("popup! " .. menu)
            return
        end
    end

    editor.send("<LeftMouse><LeftRelease><Cmd>popup! " .. menu .. "<CR>")
end

return M
