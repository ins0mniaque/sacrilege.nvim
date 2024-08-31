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

function M.menumode(mode)
    return mode == "t" and "tl" or mode
end

function M.create(name, keymaps)
    local distinct = { }

    keymaps = vim.tbl_filter(function(keymap)
        if not keymap.desc then
            return false
        end

        local key = keymap.mode .. "\0" .. keymap.desc
        if not distinct[key] then
            distinct[key] = true
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
        vim.cmd(M.menumode(keymap.mode) .. "menu " .. name .. "." .. M.escape(keymap.desc) .. " " .. keymap.lhs:gsub("%s", "<Space>"))
    end

    return true
end

local function convert_to_insert_mode(keymaps)
    local converted = { }

    for _, keymap in pairs(keymaps) do
        table.insert(converted, keymap)

        if keymap.mode == "n" then
            table.insert(converted, vim.tbl_deep_extend("force", keymap, { mode = "i", lhs = "<C-\\><C-N>" .. keymap.lhs .. "<Cmd>startinsert<CR>" }))
        end
    end

    return converted
end

local function create_buffer_keymap_menu(name, mapmode)
    if (mapmode == "n" and (not vim.bo.modifiable or vim.bo.readonly)) or
       (mapmode == "i" and vim.bo.buftype == "nofile") then
        local keymaps = vim.api.nvim_buf_get_keymap(0, mapmode)

        if M.create(name, keymaps) then
            return true
        end

        if mapmode == "i" then
            keymaps = convert_to_insert_mode(vim.api.nvim_buf_get_keymap(0, "n"))

            if M.create(name, keymaps) then
                return true
            end
        end
    end

    return false
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
        elseif vim.o.laststatus == 1 or
               vim.o.laststatus == 2 and
               mouse.winrow > vim.api.nvim_win_get_height(mouse.winid) then
            menu = "StatusLine"
        end
    elseif vim.bo.filetype ~= "" then
        menu = M.escape(vim.bo.filetype)
    end

    if not vim.fn.menu_info(menu, "").submenus then
        menu = "PopUp"

        if vim.bo.filetype ~= "" and create_buffer_keymap_menu(vim.bo.filetype, mapmode) then
            menu = M.escape(vim.bo.filetype)
        end
    end

    vim.api.nvim_exec_autocmds("MenuPopup", { })

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
