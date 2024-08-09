local editor = require("sacrilege.editor")

local M = { }

-- TODO: Configuration
local breaks =
{
    " ",
    vim.api.nvim_replace_termcodes("<CR>", true, false, true)
}

function M.setup()
    local namespace = vim.api.nvim_create_namespace("sacrilege/undo")

    vim.on_key(function(key, _)
        if vim.fn.mode() == "i" and vim.tbl_contains(breaks, key) then
            editor.send("<C-G>u")
        end
    end, namespace)
end

return M
