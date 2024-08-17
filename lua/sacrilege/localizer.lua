local M = { }

local default = "en_US"
local locale

local function load(language)
    local ok, result = pcall(require, "sacrilege.locale." .. language)
    if not ok then
        language = vim.split(language, "_", { plain = true })[1]
        ok, result = pcall(require, "sacrilege.locale." .. language)
    end

    return ok and result
end

function M.setup(language)
    language = language or M.detect()

    if language and language ~= default then
        locale = load(language)
    else
        locale = nil
    end
end

function M.language()
    return locale and locale.language() or default
end

function M.localize(text)
    return locale and locale.localize(text) or text
end

function M.detect()
    local language = vim.o.langmenu

    if not language or #language == 0 then
        language = os.getenv("LANGUAGE")
    end

    if not language or #language == 0 then
        language = os.getenv("LANG")

        if language and #language > 0 then
            language = vim.split(language, ".", { plain = true })[1]
        end
    end

    return language and #language > 0 and language
end

return M
