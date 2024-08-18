local localize = require("sacrilege.localizer").localize

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
    log(string.format(localize(format), ...), vim.log.levels.TRACE)
end

function M.debug(format, ...)
    log(string.format(localize(format), ...), vim.log.levels.DEBUG)
end

function M.inform(format, ...)
    log(string.format(localize(format), ...), vim.log.levels.INFO)
end

function M.warn(format, ...)
    log(string.format(localize(format), ...), vim.log.levels.WARN)
end

function M.err(format, ...)
    log(string.format(localize(format), ...), vim.log.levels.ERROR)
end

return M
