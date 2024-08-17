local command = require("sacrilege.command")
local cmd = require("sacrilege.cmd")
local editor = require("sacrilege.editor")
local insertmode = require("sacrilege.insertmode")
local completion = require("sacrilege.completion")
local snippet = require("sacrilege.snippet")

local M = { }

local defaults =
{
    presets = { "default" }
}

local options = { }
local keymap  = { }

local metatable =
{
    __index = function(table, key)
        if key == "insertmode" then
            return options[key]
        elseif key == "blockmode" then
            return require("sacrilege.blockmode").active()
        elseif key == "options" then
            return vim.tbl_deep_extend("force", { }, options)
        elseif key == "keymap" then
            return vim.tbl_deep_extend("force", { }, keymap)
        end

        return rawget(table, key)
    end,

    __newindex = function(table, key, value)
        if key == "insertmode" then
            insertmode.enable(value)
        elseif key == "blockmode" or key == "options" or key == "keymap" then
            editor.notify("sacrilege." .. key .. " is read-only", vim.log.levels.ERROR)
        else
            rawset(table, key, value)
        end
    end
}

setmetatable(M, metatable)

local function extend(dst, src, predicate)
    for key, value in pairs(src) do
        if type(value) == "table" and predicate(value) then
            dst[key] = dst[key] or { }
            extend(dst[key], value, predicate)
        else
            dst[key] = value
        end
    end
end

local function recurse(t, when, callback)
    local prefixes = { }

    for key, value in pairs(t) do
        local prefixes = vim.list_slice(prefixes, 1, #prefixes)

        table.insert(prefixes, key)

        if type(value) == "table" and when(value) then
            recurse(value, when, callback)
        else
            callback(prefixes, value)
        end
    end
end

function M.setup(opts)
    if vim.fn.has("nvim-0.7.0") ~= 1 then
        return editor.notify("sacrilege.nvim requires Neovim >= 0.7.0", vim.log.levels.ERROR)
    end

    options = vim.deepcopy(defaults)

    local presets = opts and (opts.presets or opts.preset) or options.presets or options.preset
    if type(presets) == "string" then
        presets = { presets }
    end

    if type(presets) == "table" then
        for _, preset in pairs(presets) do
            local ok, result = pcall(require, "sacrilege.presets." .. preset)
            if ok then
                options = result.apply(options) or options
            else
                editor.notify("Preset \"" .. preset .. "\" not found", vim.log.levels.WARN)
            end
        end
    end

    if opts and type(opts.commands) == "function" then
        opts = vim.deepcopy(opts)
        opts.commands = opts.commands(options.commands or { })
    end

    extend(options, opts, command.isnot)

    completion.setup(options.completion)
    snippet.setup(options.snippet)
    insertmode.setup(options)

    if options.autobreakundo then
        require("sacrilege.undo").setup()
    end

    if options.autocomplete then
        require("sacrilege.autocomplete").setup()
    end

    if options.blockmode then
        require("sacrilege.blockmode").setup()
    end

    keymap = { }

    if options.commands then
        for id, command in pairs(options.commands) do
            cmd[id] = command
        end

        -- TODO: Localize all commands
    end

    if options.keys then
        recurse(options.keys, function(table) return not table[1] end, function(prefixes, keys)
            local cmd = vim.tbl_get(cmd, unpack(prefixes))
            if command.is(cmd) then
                cmd:map(keys, function(mode, lhs, rhs, opts)
                    table.insert(keymap, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
                end)
            else
                -- TODO: Add to health check issues instead
                editor.notify("Key command not found: " .. table.concat(prefixes, "."), vim.log.levels.WARN)
            end
        end)
    end

    if options.popup then
        vim.opt.mouse      = "a"
        vim.opt.mousemodel = "popup_setpos"

        pcall(vim.cmd.aunmenu, "PopUp.-1-")
        pcall(vim.cmd.aunmenu, "PopUp.How-to\\ disable\\ mouse")

        local menus = { }

        for _, definition in pairs(options.popup) do
            if type(definition) == "string" then
                definition = { definition }
            end

            if not definition[1]:find("^-") then
                local cmd = vim.tbl_get(cmd, unpack(vim.split(definition[1], "%.")))

                if command.is(cmd) then
                    table.insert(menus, cmd:menu("PopUp", definition.position))
                else
                    -- TODO: Add to health check issues instead
                    editor.notify("Popup command not found: " .. definition[1], vim.log.levels.WARN)
                end
            else
                vim.cmd.amenu((definition.position or "") .. " PopUp." .. definition[1] .. " <Nop>")
            end
        end

        vim.api.nvim_create_autocmd("MenuPopup",
        {
            desc = "Synchronize Popup Menu Mode",
            group = vim.api.nvim_create_augroup("sacrilege/popup", { }),
            callback = function(_)
                local mapmode = editor.mapmode()
                for _, menu in pairs(menus) do
                    menu.update(mapmode)
                end
            end
        })
    end
end

function M.escape()
    if vim.fn.mode() == "c" then
        editor.send("<C-U><Esc>")
    elseif not options.insertmode then
        editor.send("<Esc>")
    end
end

function M.interrupt()
    if options.insertmode then
        editor.toggleinsert()
    else
        editor.send("<C-c>")
    end
end

return M
