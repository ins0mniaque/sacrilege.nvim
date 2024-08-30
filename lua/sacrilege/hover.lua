local localize = require("sacrilege.localizer").localize
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
    _, window = vim.diagnostic.open_float({ pos = { mouse.line - 1, mouse.column - 1 }, relative = "mouse", offset_x = 1 })
end

local function fold(mouse)
    local foldstart = vim.fn.foldclosed(mouse.line)
    local foldend   = vim.fn.foldclosedend(mouse.line)
    if foldstart == -1 or foldend == -1 then
        return
    end

    local lines  = vim.api.nvim_buf_get_lines(0, foldstart - 1, foldend, true)
    local syntax = vim.bo.syntax == "" and vim.bo.filetype or vim.bo.syntax

    if #lines > 0 then
        _, window = vim.lsp.util.open_floating_preview(lines, syntax, { relative = "mouse", offset_x = 1 })
    else
        close()
    end
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

        local contents, syntax
        for _, result in pairs(results) do
            if result.result and result.result.contents then
                if type(result.result.contents) == 'table' and result.result.contents.kind == 'plaintext' then
                    syntax   = 'plaintext'
                    contents = vim.split(result.result.contents.value or '', '\n', { trimempty = true })
                else
                    syntax   = 'markdown'
                    contents = vim.lsp.util.convert_input_to_markdown_lines(result.result.contents)
                end
            end
        end

        if contents and #contents > 0 then
            _, window = vim.lsp.util.open_floating_preview(contents, syntax, { relative = "mouse", offset_x = 1 })
        else
            close()
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
                   vim.fn.foldclosed(mouse.line) ~= -1                       and fold or
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
    local group     = vim.api.nvim_create_augroup("sacrilege/hover", { })

    vim.o.mousemoveevent = true

    vim.on_key(function(_, typed)
        if typed == mousemove then
            mousemoved()
        end
    end, namespace)

    vim.api.nvim_create_autocmd("WinScrolled",
    {
        desc = localize("Close Hover Window"),
        group = group,
        callback = function(event)
            if window and tonumber(event.match) ~= window then
                close()
            end
        end
    })
end

return M
