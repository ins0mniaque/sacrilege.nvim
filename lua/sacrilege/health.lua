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

M.check = function()
    local sacrilege = require("sacrilege")
    local config    = require("sacrilege.config")
    local options   = sacrilege.options

    start("sacrilege: Setup")

    if not options.commands or not options.keys then
        warn("sacrilege.setup was not called")
        return
    else
        ok("Preset: " .. options.preset)
        ok("Commands: " .. tostring(count(options.commands)))
        ok("Keys: " .. tostring(count(options.keys)))
    end

    start("sacrilege: Options")

    if sacrilege.insertmode then
        ok("insertmode active")
    else
        warn("insertmode not enabled")
    end

    if sacrilege.selectmode then
        ok("selectmode active")
    else
        warn("selectmode not enabled")
    end

    start("sacrilege: Keymap")

    local keymaps =
    {
        n = vim.api.nvim_get_keymap("n"),
        i = vim.api.nvim_get_keymap("i"),
        v = vim.api.nvim_get_keymap("v"),
        s = vim.api.nvim_get_keymap("s"),
        x = vim.api.nvim_get_keymap("x"),
        c = vim.api.nvim_get_keymap("c"),
        t = vim.api.nvim_get_keymap("t"),
        o = vim.api.nvim_get_keymap("o")
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
            if keymap.lhs == lhs then
                if keymap.desc ~= (opts and opts.desc) or ((type(keymap.rhs) == "string" or type(rhs) == "string") and keymap.rhs ~= rhs) then
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

    for _, mapping in pairs(sacrilege.keymap) do
        check_keymap(mapping.mode, mapping.lhs, mapping.rhs, mapping.opts)
    end

    if not has_keymap_issue then
        ok("Keys are correctly mapped")
    end
end

return M
