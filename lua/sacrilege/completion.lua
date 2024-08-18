local log = require("sacrilege.log")
local editor = require("sacrilege.editor")

local M = { }

local engines = { }
local trigger

function M.setup(opts)
    engines = vim.tbl_deep_extend("force", engines, opts or { })

    trigger = engines.trigger
    engines.trigger = nil
end

function M.what()
    local line

    return setmetatable({ },
    {
        __index = function(table, key)

            line = line or string.sub(vim.fn.getline("."), 1, vim.fn.getpos(".")[3] - 1) .. vim.v.char

            if key == "line" then
                rawset(table, "line", line:match("^%s*(.-)%s*$"))
            elseif key == "keyword" then
                rawset(table, "keyword", line:sub(vim.fn.match(line, "\\k*$", -1) + 1))
            elseif key == "char" then
                rawset(table, "char", line:sub(-1))
            end

            return rawget(table, key)
        end
    })
end

function M.trigger()
    if trigger then
        return trigger(M.what()) ~= false
    end

    log.warn("Completion trigger is not configured")

    return false
end

function M.visible()
    for _, engine in pairs(engines) do
        if engine.visible and engine.visible() then
            return engine
        end
    end

    return nil
end

function M.abort()
    for _, engine in pairs(engines) do
        if engine.abort and engine.visible and engine.visible() then
            return engine.abort() ~= false
        end
    end

    return false
end

function M.confirm(opts)
    for _, engine in pairs(engines) do
        if engine.confirm and engine.visible and engine.visible() then
            return engine.confirm(opts) ~= false
        end
    end

    return false
end

function M.select(direction)
    for _, engine in pairs(engines) do
        if engine.select and engine.visible and engine.visible() then
            return engine.select(direction) ~= false
        end
    end

    return false
end

M.native = { trigger = { } }

local function native(key)
    if vim.fn.pumvisible() ~= 1 then
        editor.send("<C-X>" .. key)
    end
end

function M.native.trigger.keyword() native("<C-N>") end
function M.native.trigger.line() native("<C-L>") end
function M.native.trigger.path() native("<C-F>") end
function M.native.trigger.tags() native("<C-]>") end
function M.native.trigger.definitions() native("<C-D>") end
function M.native.trigger.keyword_included() native("<C-I>") end
function M.native.trigger.dictionary() native("<C-K>") end
function M.native.trigger.thesaurus() native("<C-T>") end
function M.native.trigger.cmdline() native("<C-V>") end
function M.native.trigger.user() native("<C-U>") end
function M.native.trigger.omni() native("<C-O>") end
function M.native.trigger.spell() native("s") end

function M.native.visible()
    return vim.fn.pumvisible() == 1 and vim.fn.wildmenumode() ~= 1
end

function M.native.abort()
    if vim.fn.pumvisible() ~= 1 then
        return false
    end

    editor.send("<C-E>")

    return true
end

function M.native.confirm(opts)
    if vim.fn.pumvisible() ~= 1 then
        return false
    end

    local selected = vim.fn.complete_info({ "selected" }).selected ~= -1

    if opts and opts.select and not selected then
        editor.send("<C-N>")
        selected = true
    end

    if selected then
        editor.send("<C-Y>")
    else
        editor.send("<C-X>")
    end

    return selected
end

function M.native.select(direction)
    if vim.fn.pumvisible() ~= 1 then
        return false
    end

    if direction == -1 then
        return editor.send("<C-P>")
    elseif direction == 1 then
        return editor.send("<C-N>")
    end

    return false
end

M.wildmenu = { }

function M.wildmenu.trigger()
    if vim.fn.wildmenumode() == 1 then
        return
    end

    local wildcharm = vim.o.wildcharm
    vim.o.wildcharm = 255
    editor.send(string.char(vim.o.wildcharm), true)

    vim.defer_fn(function()
        vim.o.wildcharm = wildcharm
        if vim.fn.wildmenumode() == 1 and vim.tbl_contains(vim.opt.completeopt:get(), "noselect") then
            editor.send("<Left>")
        end
    end, 0)
end

function M.wildmenu.visible()
    return vim.fn.wildmenumode() == 1
end

function M.wildmenu.abort()
    if vim.fn.wildmenumode() ~= 1 then
        return false
    end

    editor.send("<C-E>")

    return true
end

function M.wildmenu.confirm(opts)
    if vim.fn.wildmenumode() ~= 1 then
        return false
    end

    -- TODO: Detect wildmenu selection
    local selected = true

    if opts and opts.select and not selected then
        editor.send("<C-N>")
        selected = true
    end

    if selected then
        editor.send("<C-Y>")
    else
        editor.send("<C-E>")
    end

    return selected
end

function M.wildmenu.select(direction)
    if vim.fn.wildmenumode() ~= 1 then
        return false
    end

    if direction == -1 then
        return editor.send("<C-P>")
    elseif direction == 1 then
        return editor.send("<C-N>")
    end

    return false
end

return M
