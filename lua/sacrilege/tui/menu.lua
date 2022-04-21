local window = require('sacrilege.ui.window')
local button = require('sacrilege.ui.button')

local M = { }

local menu = nil
local buttons = { }

local function escaped(window)
    window:close()
end

local function clicked(window, args)
    if window.id ~= args.id then
        escaped(window)
        do return end
    end

    for _, button in ipairs(buttons) do
        if args.row >= button.row and args.row < button.row + button.height and
           args.col >= button.col and args.col < button.col + button.width then
            print('focus')
            button:focus()
        else
            button:unfocus()
        end
    end
end

local function resized(window, args)
    window:update({ width = vim.go.columns })
end

function M.open()
    if menu and not menu:disposed() then
        do return end
    end

    local lastBuffer     = vim.api.nvim_get_current_buf()
    local lastBufferType = vim.api.nvim_buf_is_valid(lastBuffer) and vim.api.nvim_buf_get_option(lastBuffer, 'ft') or ''

    menu = window:new({
        enter = true, -- TODO: Not working and prevent shortcuts from working
        row = 0, col = 0,
        width = vim.go.columns,
        height = 1,
        buffer = {
            modifiable = false,
            -- TODO: Move buffer creation outside window
            lines = {'                                                                                 '}
        }
    })

    buttons = {
        button:new({ buffer = menu.buffer, row = 0, col = 1, width = 6, height = 1, label = '&File'}),
        button:new({ buffer = menu.buffer, row = 0, col = 7, width = 6, height = 1, label = '&Edit'}),
        button:new({ buffer = menu.buffer, row = 0, col = 13, width = 11, height = 1, label = '&Selection'}),
        button:new({ buffer = menu.buffer, row = 0, col = 24, width = lastBufferType:len() + 2, height = 1, label = lastBufferType}),
        button:new({ buffer = menu.buffer, row = 0, col = lastBufferType:len() + 2 + 24, width = 6, height = 1, label = '&View'}),
        button:new({ buffer = menu.buffer, row = 0, col = lastBufferType:len() + 2 + 30, width = 6, height = 1, label = '&Help'})
    }

    for _, button in ipairs(buttons) do
        button:render()
    end

    menu:map('n', '<Esc>',       escaped)
    menu:map('n', '<Leader>',    escaped)
    menu:map('n', '<LeftMouse>', clicked)

    menu:autocmd('BufLeave',   escaped)
    menu:autocmd('VimResized', resized)
end

function M.close()
    if menu and not menu:disposed() then
        menu:close()
    end

    menu = nil
end

return M