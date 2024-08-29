local M = {}

---@diagnostic disable: deprecated
local start = vim.health.start or vim.health.report_start
local warn = vim.health.warn or vim.health.report_warn
local ok = vim.health.ok or vim.health.report_ok

local function count(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

local function check_keymaps(buffer)
    local get_keymap = not buffer and vim.api.nvim_get_keymap or function(mode)
        return vim.api.nvim_buf_get_keymap(buffer, mode)
    end

    local keymaps =
    {
        n = get_keymap("n"),
        i = get_keymap("i"),
        v = get_keymap("v"),
        s = get_keymap("s"),
        x = get_keymap("x"),
        c = get_keymap("c"),
        t = get_keymap("t"),
        o = get_keymap("o")
    }

    local keymap_names =
    {
        n = "Normal Mode",
        i = "Insert Mode",
        v = "Visual/Select Mode",
        s = "Select Mode",
        x = "Visual Mode",
        c = "Command Line Mode",
        t = "Terminal Mode",
        o = "Operator-Pending Mode"
    }

    local has_keymap_issue = false

    local function format_rhs(rhs)
        if type(rhs) == "function" then
            local debug = debug.getinfo(rhs)
            return debug.name or debug.short_src or tostring(rhs)
        else
            return tostring(rhs)
        end
    end

    local function check_keymap(mode, lhs, rhs, opts)
        if type(mode) == "table" then
            for _, submode in pairs(mode) do
                check_keymap(submode, lhs, rhs, opts)
            end

            return
        end

        for _, keymap in pairs(keymaps[mode]) do
            if vim.api.nvim_replace_termcodes(keymap.lhs, true, true, true) == lhs then
                if keymap.desc ~= (opts and opts.desc) or ((type(keymap.rhs) == "string" or type(rhs) == "string") and keymap.rhs ~= rhs) then
                    if not has_keymap_issue then
                        start(string.format("sacrilege: Local Keymaps for %s (buffer %d)", vim.bo[buffer].filetype, buffer))
                    end

                    warn(string.format("Key %s in %s for \"%s\" was remapped to \"%s\": %s",
                                       keymap.lhs,
                                       keymap_names[mode],
                                       opts.desc,
                                       keymap.desc or "",
                                       format_rhs(keymap.rhs or keymap.callback)))

                    has_keymap_issue = true
                end
            end
        end
    end

    for _, mapping in pairs(require("sacrilege").keymap) do
        check_keymap(mapping.mode, vim.api.nvim_replace_termcodes(mapping.lhs, true, true, true), mapping.rhs, mapping.opts)
    end

    return not has_keymap_issue
end

M.check = function()
    local sacrilege = require("sacrilege")
    local localizer = require("sacrilege.localizer")
    local options   = sacrilege.options

    start("sacrilege: Setup")

    if not options.commands or not options.keys then
        warn("sacrilege.setup was not called")
        return
    else
        local language = options.language or localizer.detect()
        if language == localizer.language() then
            ok("Language: " .. language)
        else
            warn("Language: " .. language .. " not found (defaulted to " .. localizer.language() .. ")")
        end

        local presets = options.presets or options.preset or "None"
        if type(presets) == "string" then
            presets = { presets }
        end

        ok("Presets: " .. table.concat(presets, ", "))
        ok("Commands: " .. tostring(count(options.commands)))
        ok("Keys: " .. tostring(count(options.keys)))
    end

    start("sacrilege: Options")

    if sacrilege.insertmode then
        ok("insertmode active")
    else
        warn("insertmode not enabled")
    end

    if options.blockmode then
        ok("blockmode enabled")
    else
        warn("blockmode not enabled")
    end

    if options.autocomplete then
        ok("autocomplete enabled")
    else
        warn("autocomplete not enabled")
    end

    if options.autobreakundo then
        ok("autobreakundo enabled")
    else
        warn("autobreakundo not enabled")
    end

    if options.hover then
        ok("hover enabled")
    else
        warn("hover not enabled")
    end

    start("sacrilege: Keymap")

    if check_keymaps() then
        ok("Keys are correctly mapped")
    end

    local has_keymap_issue = false

    for _, buffer in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buffer) then
            if not check_keymaps(buffer) then
                has_keymap_issue = true
            end
        end
    end

    if not has_keymap_issue then
        start("sacrilege: Local Keymaps")

        ok("Keys are correctly mapped")
    end
end

return M
