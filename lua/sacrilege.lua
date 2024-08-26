local localizer = require("sacrilege.localizer")
local log = require("sacrilege.log")
local command = require("sacrilege.command")
local editor = require("sacrilege.editor")
local insertmode = require("sacrilege.insertmode")
local completion = require("sacrilege.completion")
local snippet = require("sacrilege.snippet")

local M = { }

local defaults =
{
    presets = { "default", "dap", "dap-ui", "neotest" }
}

local options = { }
local cmd     = { }
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
        elseif key == "cmd" then
            return cmd
        elseif key == "keymap" then
            return vim.tbl_deep_extend("force", { }, keymap)
        end

        return rawget(table, key)
    end,

    __newindex = function(table, key, value)
        if key == "insertmode" then
            insertmode.enable(value)
        elseif key == "blockmode" or key == "options" or key == "cmd" or key == "keymap" then
            log.err("sacrilege.%s is read-only", key)
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

function M.setup(opts)
    localizer.setup(opts and opts.language)

    if vim.fn.has("nvim-0.7.0") ~= 1 then
        return log.err("sacrilege.nvim requires Neovim >= %s", "0.7.0")
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
                log.warn("Preset \"%s\" not found", preset)
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

    if options.hover then
        require("sacrilege.hover").setup()
    end

    if options.selection then
        require("sacrilege.selection").setup(options.selection)
    end

    keymap = { }
    cmd    = { }

    if options.commands then
        require("sacrilege.commands.metatable").set(cmd)

        for id, command in pairs(options.commands) do
            cmd[id] = command
        end

        local function execute(args)
            local cmd = cmd[args.args]

            if cmd then
                if args.bang then
                    pcall(cmd.execute, cmd)
                else
                    cmd:execute()
                end
            else
                log.err("Command \"%s\" not found", args.args)
            end
        end

        vim.api.nvim_create_user_command("Cmd", execute,
        {
            nargs = 1,
            bang = true,
            desc = localizer.localize("Execute Sacrilege Command"),
            complete = function(_)
                return vim.tbl_keys(cmd)
            end,
        })
    end

    if options.keys then
        for key, commands in pairs(options.keys) do
            local keys = key
            if type(commands) == "string" then
                commands = { commands }
            end

            for _, id in pairs(commands) do
                local cmd = cmd[id]
                if command.is(cmd) then
                    cmd:map(keys, function(mode, lhs, rhs, opts)
                        table.insert(keymap, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
                    end)
                else
                    log.warn("Key command not found: %s", id)
                end
            end
        end
    end

    if options.menus then
        vim.opt.mouse      = "a"
        vim.opt.mousemodel = "popup_setpos"

        local menus = { }

        local function parse(name, definition)
            pcall(vim.cmd.aunmenu, name)

            for _, menu in pairs(definition) do
                if type(menu) == "string" then
                    menu = { menu }
                end

                if not menu[1]:find("^-") then
                    local cmd = cmd[menu[1]]

                    if command.is(cmd) then
                        table.insert(menus, cmd:menu(name, menu.position))
                    else
                        log.warn(name .. " command not found: %s", menu[1])
                    end
                else
                    vim.cmd.amenu((menu.position or "") .. " " .. name .. "." .. menu[1] .. " <Nop>")
                end
            end
        end

        if options.menus.popup then
            parse("PopUp", options.menus.popup)
        end

        if options.menus.statusline then
            parse("StatusLine", options.menus.statusline)
        end

        if options.menus.tabline then
            parse("TabLine", options.menus.tabline)
        end

        if options.menus.cmdline then
            parse("CmdLine", options.menus.cmdline)
        end

        if options.menus.border then
            parse("Border", options.menus.border)
        end

        -- TODO: Add support for filetype menus

        vim.api.nvim_create_autocmd("MenuPopup",
        {
            desc = localizer.localize("Synchronize Popup Menu Mode"),
            group = vim.api.nvim_create_augroup("sacrilege/popup", { }),
            callback = function()
                local mapmode = editor.mapmode()
                for _, menu in pairs(menus) do
                    menu.update(mapmode)
                end
            end
        })
    end
end

return M
