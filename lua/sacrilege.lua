local config = require("sacrilege.config")
local editor = require("sacrilege.editor")

local M = { }

local defaults =
{
    insertmode = true,
    selectmode = true,
    snippet =
    {
        active = vim.snippet and vim.snippet.active,
        jump = vim.snippet and vim.snippet.jump,
        stop = vim.snippet and vim.snippet.stop
    },
    selection =
    {
        mouse = true,
        virtual = true
    },
    preset = "sacrilege.presets.default"
}

local options = { }

local metatable =
{
    __index = function(table, key)
        if key == "insertmode" or key == "selectmode" then
            return options[key]
        end

        return rawget(table, key)
    end,

    __newindex = function(table, key, value)
        if key == "insertmode" then
            options.insertmode = value

            if options.insertmode then
                vim.defer_fn(editor.toggleinsert, 0)
            end
        elseif key == "selectmode" then
            options.selectmode = value

            if options.selectmode then
                vim.defer_fn(editor.selectmode, 0)
            end
        else
            rawset(table, key, value)
        end
    end
}

setmetatable(M, metatable)

function M.setup(opts)
    if vim.fn.has("nvim-0.7.0") ~= 1 then
        return vim.notify("sacrilege.nvim requires Neovim >= 0.7.0", vim.log.levels.ERROR, { title = "sacrilege.nvim" })
    end

    local preset

    if opts and opts.preset and opts.preset ~= false and opts.preset ~= "" then
        local ok, result = pcall(require, opts.preset)
        if ok then
            preset = result
        end
    else
        preset = require(defaults.preset)
    end

    options = vim.tbl_deep_extend("force", defaults,
    {
        commands = preset and preset.commands(),
        keys = preset and preset.keys(),
        popup = preset and preset.popup()
    })

    options = vim.tbl_deep_extend("force", options, opts or { })

    local insertmode_group = vim.api.nvim_create_augroup("Sacrilege.InsertMode", { })

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TermLeave" },
    {
        desc = "Toggle Insert Mode",
        group = insertmode_group,
        pattern = { "*" },
        callback = function(_)
            if options.insertmode then
                vim.defer_fn(editor.toggleinsert, 0)
            end
        end
    })

    vim.api.nvim_create_autocmd({ "ModeChanged" },
    {
        desc = "Toggle Insert Mode",
        group = insertmode_group,
        pattern = { "*:n" },
        callback = function(_)
            if options.insertmode then
                vim.defer_fn(editor.toggleinsert, 0)
            end
        end
    })

    local selectmode_group = vim.api.nvim_create_augroup("Sacrilege.SelectMode", { })

    vim.api.nvim_create_autocmd({ "ModeChanged" },
    {
        desc = "Stop Visual Mode",
        group = selectmode_group,
        pattern = { "*:v", "*:V", "*:\22" },
        callback = function(_)
            if options.selectmode then
                vim.defer_fn(editor.stopvisual, 0)
            end
        end
    })

    if options.snippet and options.snippet.active and options.selection and options.selection.exclusive then
        vim.api.nvim_create_autocmd({ "ModeChanged" },
        {
            desc = "Fix Active Snippet Exclusive Selection",
            group = selectmode_group,
            pattern = { "*:s" },
            callback = function(_)
                if options.selectmode then
                    vim.opt.selection = options.snippet.active() and "inclusive" or "exclusive"
                end
            end
        })
    end

    if options.selection then
        vim.opt.keymodel = { }
        vim.opt.selection = "exclusive"
        vim.opt.virtualedit = "onemore"

        if options.selection.mouse then
            vim.opt.mouse = "a"
            vim.opt.selectmode = { "mouse", "key", "cmd" }
        end

        if options.selection.virtual then
            vim.opt.virtualedit = "block,onemore"
        end
    end

    config.parse(options, options.commands.global)

    if options.commands.treesitter then
        local treesitter = require("sacrilege.treesitter")

        vim.api.nvim_create_autocmd("FileType",
        {
            desc = "Map Treesitter Commands",
            group = vim.api.nvim_create_augroup("Sacrilege.Treesitter", { }),
            pattern = { "*" },
            callback = function(event)
                if not treesitter.has_parser(treesitter.get_buf_lang(event.buf)) then
                    return
                end

                config.parse(options, options.commands.treesitter, function(definition)
                    return not definition.method or not editor.supports_lsp_method(event.buf, definition.method)
                end)
            end
        })
    end

    if options.commands.lsp then
        vim.api.nvim_create_autocmd("LspAttach",
        {
            desc = "Map LSP Commands",
            group = vim.api.nvim_create_augroup("Sacrilege.Lsp", { }),
            callback = function(event)
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if not client then
                    return
                end

                config.parse(options, options.commands.lsp, function(definition)
                    return not definition.method or client.supports_method(definition.method)
                end)
            end
        })
    end

    if options.popup then
        vim.opt.mouse      = "a"
        vim.opt.mousemodel = "popup_setpos"

        pcall(vim.cmd.aunmenu, "PopUp.-1-")
        pcall(vim.cmd.aunmenu, "PopUp.How-to\\ disable\\ mouse")

        local update_popup = config.parse_popup(options, options.popup)

        vim.api.nvim_create_autocmd({ "MenuPopup" },
        {
            desc = "Synchronize Popup Menu Mode",
            group = vim.api.nvim_create_augroup("Sacrilege.Popup", { }),
            pattern = { "*" },
            callback = function(_)
                update_popup(editor.mapmode())
            end
        })
    end

    if options.insertmode then
        vim.defer_fn(editor.toggleinsert, 0)
    end
end

function M.escape()
    if options.snippet and options.snippet.active and options.snippet.stop and options.snippet.active() then
        options.snippet.stop()
    end

    -- Clear highlights
    vim.cmd("nohl")

    -- Clear command-line echo
    vim.cmd("echon '\r\r'")
    vim.cmd("echon ''")

    if not editor.try_close_popup() and not options.insertmode then
        editor.send("<Esc>")
    end
end

function M.interrupt()
    if not options.insertmode then
        editor.send("<C-c>")
    end
end

function M.tab()
    if options.snippet and options.snippet.active and options.snippet.jump and options.snippet.active({ direction = 1 }) then
        options.snippet.jump(1)
    else
        local mode = editor.mapmode()

        if mode == "s" or mode == "x" then
            editor.send("<C-O>>gv")
        else
            editor.send("<Tab>")
        end
    end
end

function M.shifttab()
    if options.snippet and options.snippet.active and options.snippet.jump and options.snippet.active({ direction = -1 }) then
        options.snippet.jump(-1)
    else
        local mode = editor.mapmode()

        if mode == "i" then
            editor.send("<C-d>")
        elseif mode == "s" or mode == "x" then
            editor.send("<C-O><gv")
        else
            editor.send("<S-Tab>")
        end
    end
end

return M
