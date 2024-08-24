local localize = require("sacrilege.localizer").localize
local editor = require("sacrilege.editor")

local M = { }

local mousemove
local window

local function close()
    if window and vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_win_close(window, false)
    end

    window = nil
end

local function diagnostic(mouse)
    _, window = vim.diagnostic.open_float({ pos = { mouse.line - 1, mouse.column - 1 }, relative = "mouse" })
end

local function hover(mouse)
    local position_params = vim.lsp.util.make_position_params()

    position_params.position.line      = mouse.line - 1
    position_params.position.character = mouse.column - 1

    local buffer = vim.api.nvim_get_current_buf()

    vim.lsp.buf_request_all(buffer, "textDocument/hover", position_params, function(results)
        if mouse ~= mousemove or buffer ~= vim.api.nvim_get_current_buf() then
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
            _, window = vim.lsp.util.open_floating_preview(contents, format, { relative = "mouse" })
        end
    end)
end

function M.setup()
    vim.o.mousemoveevent = true

    vim.keymap.set({ "n", "i", "v" }, "<MouseMove>", function()
        local mouse = vim.fn.getmousepos()

        mousemove = mouse

        if mouse.winid == window then
            return
        end

        if mouse.line == 0 or mouse.winid ~= vim.api.nvim_get_current_win() or mouse.column > #vim.fn.getline(mouse.line) then
            close()
            return
        end

        local action = mouse.wincol <= vim.fn.getwininfo(mouse.winid)[1].textoff and diagnostic or
                       editor.supports_lsp_method(0, "textDocument/hover")       and hover or close

        vim.defer_fn(function()
            if mouse == mousemove then
                action(mouse)
            end
        end, 500)
    end, { desc = localize("Hover") })
end

return M
