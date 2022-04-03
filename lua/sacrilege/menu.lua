local window = require('sacrilege.ui.window')

local M = { }

local menu = nil

local function escaped(window)
    window:close()
end

local function clicked(window, args)
    if window.id ~= args.id then
        escaped(window)
    end
end

local function resized(window, args)
    window:update({ width = vim.go.columns })
end

function M.open()
    if menu and not menu:disposed() then
        do return end
    end

    menu = window:new({
        row = 0, col = 0,
        width = vim.go.columns,
        height = 1,
        buffer = {
            modifiable = false,
            lines = {' File  Edit  Selection  View  Help '}
        }
    })

    menu:map('n', '<Esc>',       escaped)
    menu:map('n', '<Leader>',    escaped)
    menu:map('n', '<LeftMouse>', clicked)

    menu:autocmd('BufLeave',   escaped)
    menu:autocmd('VimResized', resized)

    -- vim.fn.matchaddpos('PmenuSel', {{ 1, 6 }})
    vim.fn.matchaddpos('Title', {{ 1, 2 }})
end

function M.close()
    if menu and not menu:disposed() then
        menu:close()
    end

    menu = nil
end

-- TODO: Only when insertmode is on using autocmd OptionSet
function M.setup(config)
    if not config or config.enabled ~= false then
        vim.api.nvim_set_keymap('i', '<Esc>', '<Cmd>lua require(\'sacrilege.menu\').open()<CR>', { silent = true, noremap = true })
    else
        vim.api.nvim_del_keymap('i', '<Esc>')
    end
end

return M