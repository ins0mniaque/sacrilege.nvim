local config = require("sacrilege.config")
local editor = require("sacrilege.editor")
local completion = require("sacrilege.completion")
local snippet = require("sacrilege.snippet")

local M = { }

local defaults =
{
    insertmode = true,
    selectmode = true,
    autocomplete = true,
    completion =
    {
        default = function(what)
            if what.line:find("/") and not what.line:find("[%s%(%)%[%]]") then
                return "path"
            elseif vim.bo.omnifunc ~= "" then
                return "omni"
            elseif vim.bo.completefunc ~= "" then
                return "user"
            -- elseif vim.bo.thesaurus ~= "" or vim.bo.thesaurusfunc ~= "" then
            --     return "thesaurus"
            -- elseif vim.bo.dictionary ~= "" then
            --     return "dictionary"
            -- elseif vim.wo.spell and vim.bo.spelllang ~= "" then
            --     return "spell"
            else
                return "keyword"
            end
        end,
        keyword = completion.native("<C-N>"),
        line = completion.native("<C-L>"),
        path = completion.native("<C-F>"),
        tags = completion.native("<C-]>"),
        definitions = completion.native("<C-D>"),
        keyword_included = completion.native("<C-I>"),
        dictionary = completion.native("<C-K>"),
        thesaurus = completion.native("<C-T>"),
        cmdline = completion.native("<C-V>"),
        user = completion.native("<C-U>"),
        omni = completion.native("<C-O>"),
        spell = completion.native("s")
    },
    snippet =
    {
        native = vim.snippet and
        {
            active = vim.snippet.active,
            jump = vim.snippet.jump,
            stop = vim.snippet.stop
        }
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
        elseif key == "options" then
            return vim.tbl_deep_extend("force", { }, options)
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
        elseif key == "options" then
            editor.notify("Cannot change options after setup", vim.log.levels.ERROR)
        else
            rawset(table, key, value)
        end
    end
}

setmetatable(M, metatable)

function M.setup(opts)
    if vim.fn.has("nvim-0.7.0") ~= 1 then
        return editor.notify("sacrilege.nvim requires Neovim >= 0.7.0", vim.log.levels.ERROR)
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

    completion.setup(options.completion)
    snippet.setup(options.snippet)

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

    if options.selection and options.snippet then
        vim.api.nvim_create_autocmd({ "ModeChanged" },
        {
            desc = "Fix Active Snippet Exclusive Selection",
            group = selectmode_group,
            pattern = { "*:s" },
            callback = function(_)
                if options.selectmode then
                    vim.opt.selection = snippet.active() and "inclusive" or "exclusive"
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

            -- Fix delayed mouse word selection
            vim.keymap.set("i", "<2-LeftMouse>", "<2-LeftMouse><2-LeftRelease>")
        end

        if options.selection.virtual then
            vim.opt.virtualedit = "block,onemore"
        end
    end

    config.map(options, options.commands.global)

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

                config.map(options, options.commands.treesitter, event.buf, function(definition)
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

                config.map(options, options.commands.lsp, event.buf, function(definition)
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

        local update_popup = config.build_popup(options, options.popup)

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
    if completion.abort() then return end
    if snippet.stop() then return end
    if editor.try_close_popup() then return end

    -- Clear highlights
    vim.cmd("nohl")

    -- Clear command-line echo
    vim.cmd("echon '\r\r'")
    vim.cmd("echon ''")

    if not options.insertmode then
        editor.send("<Esc>")
    end
end

function M.interrupt()
    if not options.insertmode then
        editor.send("<C-c>")
    end
end

function M.tab()
    if completion.confirm({ select = true }) then return end
    if snippet.jump(1) then return end

    local mode = editor.mapmode()

    if mode == "s" or mode == "x" then
        if vim.fn.getpos("v")[2] ~= vim.fn.getpos(".")[2] then
            editor.send("<C-O>>gv")
        else
            editor.send("<Space><BS><Tab>")
        end
    else
        editor.send("<Tab>")
    end
end

function M.shifttab()
    if snippet.jump(-1) then return end

    local mode = editor.mapmode()

    if mode == "i" then
        editor.send("<C-d>")
    elseif mode == "s" or mode == "x" then
        editor.send("<C-O><lt>gv")
    else
        editor.send("<S-Tab>")
    end
end

function M.up()
    if completion.select(-1) then return end

    local mode = editor.mapmode()

    if mode == "s" or mode == "x" then
        editor.send("<Esc><Up>")
    else
        editor.send("<Up>")
    end
end

function M.down()
    if completion.select(1) then return end

    local mode = editor.mapmode()

    if mode == "s" or mode == "x" then
        editor.send("<Esc><Down>")
    else
        editor.send("<Down>")
    end
end

return M
