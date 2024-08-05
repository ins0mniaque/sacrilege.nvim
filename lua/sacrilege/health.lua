local M = {}

---@diagnostic disable: deprecated
local start = vim.health.start or vim.health.report_start
local warn = vim.health.warn or vim.health.report_warn
local ok = vim.health.ok or vim.health.report_ok

M.check = function()
    start("sacrilege: Options")

    local sacrilege = require("sacrilege")

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
end

return M
