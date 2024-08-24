local editor = require("sacrilege.editor")

local M = { }

local lastmouse
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
    local params = vim.lsp.util.make_position_params()

    params.position.line      = mouse.line   - 1
    params.position.character = mouse.column - 1

    local buffer = vim.api.nvim_get_current_buf()

    vim.lsp.buf_request_all(buffer, "textDocument/hover", params, function(results)
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
            _, window = vim.lsp.util.open_floating_preview(contents, format, { relative = "mouse" })
        end
    end)
end

local function mousemoved()
    local mouse = vim.fn.getmousepos()

    lastmouse = mouse

    if mouse.winid == window then
        return
    end

    if mouse.line   == 0 or
       mouse.winid  ~= vim.api.nvim_get_current_win() or
       mouse.column  > #vim.fn.getline(mouse.line) then
        close()
        return
    end

    local action = mouse.wincol <= vim.fn.getwininfo(mouse.winid)[1].textoff and diagnostic or
                   editor.supports_lsp_method(0, "textDocument/hover")       and hover or close

    vim.defer_fn(function()
        if mouse == lastmouse then
            action(mouse)
        end
    end, 500)
end

local mousemove = vim.api.nvim_replace_termcodes("<MouseMove>", true, true, true)

function M.setup()
    local namespace = vim.api.nvim_create_namespace("sacrilege/hover")

    vim.o.mousemoveevent = true

    vim.on_key(function(_, typed)
        if typed == mousemove then
            mousemoved()
        end
    end, namespace)
end

return M
