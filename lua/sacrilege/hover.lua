local localize = require("sacrilege.localizer").localize
local editor = require("sacrilege.editor")

local M = { }

local lastmouse

local function hover(mouse)
    local position_params = vim.lsp.util.make_position_params()

    position_params.position.line      = mouse.line - 1
    position_params.position.character = mouse.column - 1

    local buffer = vim.api.nvim_get_current_buf()

    vim.lsp.buf_request_all(buffer, "textDocument/hover", position_params, function(results)
        if mouse ~= lastmouse or buffer ~= vim.api.nvim_get_current_buf() then
            return
        end

        local contents, format
        for _, result in pairs(results) do
            if result.result and result.result.contents then
                if type(result.result.contents) == 'table' and result.result.contents.kind == 'plaintext' then
                    format   = 'plaintext'
                    contents = vim.split(result.result.contents.value or '', '\n', { trimempty = true })
                else
                    format   = 'markdown'
                    contents = vim.lsp.util.convert_input_to_markdown_lines(result.result.contents)
                end
            end
        end

        if contents then
            vim.lsp.util.open_floating_preview(contents, format, { relative = "mouse" })
        end
    end)
end

function M.setup()
    vim.o.mousemoveevent = true

    vim.keymap.set({ "n", "i", "v" }, "<MouseMove>", function()
        if not editor.supports_lsp_method(0, "textDocument/hover") then
            editor.try_close_popup()
            return
        end

        local mouse = vim.fn.getmousepos()

        lastmouse = mouse

        if mouse.line == 0 or mouse.winid ~= vim.api.nvim_get_current_win() or mouse.column > #vim.fn.getline(mouse.line)  then
            editor.try_close_popup()
            return
        end

        vim.defer_fn(function()
            if mouse ~= lastmouse then
                return
            end

            editor.try_close_popup()

            hover(mouse)
        end, 500)
    end, { desc = localize("Hover") })
end

return M
