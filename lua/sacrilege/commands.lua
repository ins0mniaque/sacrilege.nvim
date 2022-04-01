local keymode = require('sacrilege.keymode')

local M = { }

local commands = { }
local mapping  = { }

local function initialize()
    local cmdmenu  = nil
    local cmdindex = 0

    local function menu(name)
        cmdmenu  = name
        cmdindex = 0
    end

    local function separator()
        cmdindex = cmdindex + 1
    end

    local function cmd(name, keymap)
        M.set(name, { menu = cmdmenu, index = cmdindex, keymap = keymap })
        cmdindex = cmdindex + 1
    end

    menu('File')
        cmd('New Tab', '<Cmd>tabnew<CR>')
        cmd('Open',    '<Cmd>lua require(\'telescope.builtin\').find_files()<CR>')
        cmd('Save',    '<Cmd>update<CR>')
        cmd('Close',   '<Cmd>q<CR>')       -- TODO: Close command
        cmd('Quit',    '<Cmd>quitall<CR>') -- TODO: Quit menu

    menu('Edit')
        cmd('Undo', '<C-O>u')
        cmd('Redo', '<C-O><C-r>')
        separator()
        cmd('Cut',    '<C-O>x')
        cmd('Copy',   '<C-O>y<C-O>gv')
        cmd('Paste',  '<C-O>P')
        cmd('Delete', '<C-O>d')
        separator()
        cmd('Find',          '<C-\\><C-N>/')
        cmd('Find Previous', '<C-\\><C-N>gN')
        cmd('Find Next',     '<C-\\><C-N>gn')

    menu('Selection')
        cmd('Select All',   '<Cmd>tabnew<CR>')
        cmd('Block Select', { key     = '<C-\\><C-N>g<C-H>',
                              left    = '<C-\\><C-N>g<C-H><S-Left>',
                              right   = '<C-\\><C-N>g<C-H><S-Right>',
                              up      = '<C-\\><C-N>g<C-H><S-Up>',
                              down    = '<C-\\><C-N>g<C-H><S-Down>',
                              mouse   = '<4-LeftMouse>',
                              drag    = '<LeftDrag>',
                              release = '' })

    menu('View')
        cmd('Command Palette', '<Cmd>Telescope<CR>')
        cmd('File Explorer',   '<Cmd>NvimTreeToggle<CR>')

    menu('Help')
        cmd('Show Manual Page', '<Cmd>Man<CR>')
        cmd('Shortcuts',        '<Cmd>WhichKey<CR>')
        cmd('Vim Help',         '<Cmd>help<CR>')
        separator()
        cmd('Vim Reference', '<Cmd>help quickref<CR>')
        cmd('Vim Tutorial',  '<Cmd>Tutor<CR>')
        separator()
        cmd('About', '<Cmd>help copying<CR>')

    menu(nil)
        cmd('Backspace',     { vs = 'd' })
        cmd('Warn Vim User', '<Cmd>echomsg "<Ctrl-L>:lua require(\'sacrilege\').disable() to regain sanity"<CR>')
end

local function normalize(name)
    return name:gsub('[%s%p]', ''):lower()
end

local function expand(command)
    if type(command) == 'string' then
        command = { keymap = command }
    end

    if not command.keymap and command[1] then
        command.keymap = command[1]
        command[1]     = nil
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
        vim.tbl_deep_extend('force', command, override)
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

-- function M.confirm() end
-- function M.close() end
-- function M.quit() end

initialize()

return M