local localizer = require("sacrilege.localizer")

local M = { }

local redirect

local function log(msg, level)
    if redirect then
        redirect(msg, level)
    else
        vim.notify(msg, level, { title = localize("sacrilege.nvim") })
    end
end

function M.redirect(callback)
    redirect = callback
end

function M.trace(format, ...)
    log(localizer.format(format, ...), vim.log.levels.TRACE)
end

function M.debug(format, ...)
    log(localizer.format(format, ...), vim.log.levels.DEBUG)
end

function M.inform(format, ...)
    log(localizer.format(format, ...), vim.log.levels.INFO)
end

function M.warn(format, ...)
    log(localizer.format(format, ...), vim.log.levels.WARN)
end

function M.err(format, ...)
    log(localizer.format(format, ...), vim.log.levels.ERROR)
end

return M
