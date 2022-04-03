local keymode = require('sacrilege.keymode')

-- TODO: Add Dashboard command (Dashboard/Alpha, etc...)
-- TODO: Add Menu command
-- TODO: Add build commands (configurable)

local M = { }

local commands = { }
local mapping  = { }

local function initialize()
    -- File
    M.set('New Tab', '<Cmd>tabnew<CR>')
    M.set('Open',    '<Cmd>lua require(\'telescope.builtin\').find_files()<CR>')
    M.set('Save',    '<Cmd>update<CR>')
    M.set('Close',   '<Cmd>q<CR>')       -- TODO: Close command
    M.set('Quit',    '<Cmd>quitall<CR>') -- TODO: Quit menu

    -- Edit
    M.set('Undo',          '<C-O>u')
    M.set('Redo',          '<C-O><C-r>')
    M.set('Cut',           '<C-O>x')
    M.set('Copy',          '<C-O>y<C-O>gv')
    M.set('Paste',         '<C-O>P')
    M.set('Delete',        '<C-O>d')
    M.set('Find',          '<C-\\><C-N>/')
    M.set('Find Previous', '<C-\\><C-N>gN')
    M.set('Find Next',     '<C-\\><C-N>gn')

    -- Selection
    M.set('Select All',   '<C-\\><C-N>gggH<C-O>G')
    M.set('Block Select', { key     = '<C-\\><C-N>g<C-H>',
                            left    = '<C-\\><C-N>g<C-H><S-Left>',
                            right   = '<C-\\><C-N>g<C-H><S-Right>',
                            up      = '<C-\\><C-N>g<C-H><S-Up>',
                            down    = '<C-\\><C-N>g<C-H><S-Down>',
                            mouse   = '<4-LeftMouse>',
                            drag    = '<LeftDrag>',
                            release = '' })

    -- View
    M.set('Command Palette', '<Cmd>Telescope<CR>')
    M.set('File Explorer',   '<Cmd>NvimTreeToggle<CR>')

    -- Help
    M.set('Show Manual Page', '<Cmd>Man<CR>')
    M.set('Shortcuts',        '<Cmd>WhichKey<CR>')
    M.set('Vim Help',         '<Cmd>help<CR>')
    M.set('Vim Reference',    '<Cmd>help quickref<CR>')
    M.set('Vim Tutorial',     '<Cmd>Tutor<CR>')
    M.set('About',            '<Cmd>help copying<CR>')

    -- Other
    M.set('Backspace',     { vs = 'd' })
    M.set('Warn Vim User', '<Cmd>echomsg "<Ctrl-L>:lua require(\'sacrilege\').disable() to regain sanity"<CR>')
end

local function normalize(name)
    return name:gsub('[%s%p]', ''):lower()
end

local function expand(command)
    if type(command) ~= 'table' or not command.keymap then
        command = { keymap = command[1] or command }
    end

    if not command.keymap.key then
        command.keymap = { key = command.keymap }
    end

    for key, input in pairs(command.keymap) do
        if type(input) == 'string' then
            command.keymap[key] = { nvic = input, o = '<C-C>'..input }
        end
    end

    return command
end

function M.get(name)
    return commands[normalize(name)]
end

function M.set(name, override)
    local cmdkey  = normalize(name)
    local command = commands[cmdkey]

    override = expand(override)

    if command then
        command = vim.tbl_deep_extend('force', command, override)
    else
        command          = override
        commands[cmdkey] = command
    end

    command.name = command.name or name
end

function M.reset()
    initialize()
end

function M.map(key, name)
    M.unmap(key)

    local command = commands[normalize(name)]
    if not command then
        vim.api.nvim_err_writeln('Command \''..name..'\' not found')
        do return end
    end

    local options = { noremap = true, silent = true }
    local keymap  = command.keymap
    local keys    = nil

    if     key:match('Left>')    then keys = { [key]                            = keymap.left    or keymap.key }
    elseif key:match('Right>')   then keys = { [key]                            = keymap.right   or keymap.key }
    elseif key:match('Up>')      then keys = { [key]                            = keymap.up      or keymap.key }
    elseif key:match('Down>')    then keys = { [key]                            = keymap.down    or keymap.key }
    elseif key:match('Arrow>')   then keys = { [key:gsub('Arrow>', 'Left>')]    = keymap.left    or keymap.key,
                                               [key:gsub('Arrow>', 'Right>')]   = keymap.right   or keymap.key,
                                               [key:gsub('Arrow>', 'Up>')]      = keymap.up      or keymap.key,
                                               [key:gsub('Arrow>', 'Down>')]    = keymap.down    or keymap.key }
    elseif key:match('Mouse>')   then keys = { [key]                            = keymap.mouse   or keymap.key,
                                               [key:gsub('Mouse>', 'Drag>')]    = keymap.drag,
                                               [key:gsub('Mouse>', 'Release>')] = keymap.release }
    elseif key:match('Drag>')    then keys = { [key]                            = keymap.drag    or keymap.key }
    elseif key:match('Release>') then keys = { [key]                            = keymap.release or keymap.key }
    else                              keys = { [key]                            = keymap.key }
    end

    for key, keymap in pairs(keys) do
        local mapped = ''
        for modes, input in pairs(keymap) do
            keymode.map(modes, key, input, options)
            mapped = mapped..modes
        end

        mapping[key] = mapped
    end
end

function M.unmap(key)
    local modes = mapping[key]
    if modes then
        keymode.unmap(modes, key)
        mapping[key] = nil
    end
end

function M.run(name)
    local command = commands[normalize(name)]
    if not command then
        vim.api.nvim_err_writeln('Command \''..name..'\' not found')
        do return end
    end

    local mode = keymode.get()
    for modes, input in pairs(command.keymap.key) do
        for i = 1, #modes do
            if keymode.match(mode, modes:sub(i,i)) then
                vim.api.nvim_input(input)
                return
            end
        end
    end
end

initialize()

return M