local define = require('sacrilege.define')
local input  = require('sacrilege.input')

-- TODO: Add viml commands
local M = { }

local enabled = false
local keymap  = { }
local config  = {
    actions = {
        newtab         = define.cmd("tabnew"),
        quit           = define.cmd("quitall"), -- TODO: Quit menu
        save           = define.cmd("update"),
        paste          = "<C-O>P",
        cut            = "<C-O>x",
        copy           = "<C-O>y",
        fileexplorer   = define.cmd("NvimTreeToggle"),
        commandpalette = define.cmd("Telescope"),
        open           = define.lua('telescope.builtin', 'find_files()'),
        close          = define.cmd("q"),
        find           = define.input('n', "/"),
        findprevious   = define.input('n', "gN"),
        findnext       = define.input('n', "gn"),
        undo           = "<C-O>u",
        redo           = "<C-O><C-r>",
        selectall      = define.input('n', "gggH<C-O>G"),
        blockselect    = { key     = define.input('n', "g<C-H>"),
                           -- TODO: Fix arrow block selection; needs stay in S-BLOCK for subsequent presses
                           -- left    = define.input('n', "g<C-H><S-Left>"),
                           -- right   = define.input('n', "g<C-H><S-Right>"),
                           -- up      = define.input('n', "g<C-H><S-Up>"),
                           -- down    = define.input('n', "g<C-H><S-Down>"),
                           mouse   = "<4-LeftMouse>",
                           drag    = "<LeftDrag>",
                           release = "" },
        vimkeyhelp     = define.cmd("WhichKey"),
        warnvimuser    = define.cmd("echomsg \"<Ctrl-L>:lua require('sacrilege').disable() to regain sanity\"")
    },

    -- TODO: Presets
    -- TODO: Special keys not mapped in every mode
    --       e.g. vim.api.nvim_set_keymap('v', '<BS>', 'd', { noremap = true, silent = true })
    mapping = {
        ["<C-t>"]         = "New Tab",
        ["<M-LeftMouse>"] = "Block Select",
        ["<M-S-Arrow>"]   = "Block Select",
        ["<C-q>"]         = "Quit",
        ["<C-s>"]         = "Save",
        ["<C-v>"]         = "Paste",
        ["<C-x>"]         = "Cut",
        ["<C-c>"]         = "Copy",
        ["<C-b>"]         = "File Explorer",
        ["<C-p>"]         = "Command Palette",
        ["<C-o>"]         = "Open",
        ["<C-F4>"]        = "Close",
        ["<C-W>"]         = "Close",
        ["<C-f>"]         = "Find",
        ["<S-F3>"]        = "Find Previous",
        ["<F3>"]          = "Find Next",
        ["<C-z>"]         = "Undo",
        ["<C-S-z>"]       = "Redo",
        ["<C-y>"]         = "Redo",
        ["<C-a>"]         = "Select All",
        -- TODO: Find better key combination
        -- ["<Esc><Leader>"] = "Warn Vim User"
    },

    options = {
        automatic = true
    }
}

local function normalize(action)
    return action:gsub('[%s%p]', ''):lower()
end

local function configure(mapping)
    local keymap = { }

    local function assign(key, command)
        -- TODO: Validate keycode
        if type(command) == "string" then
            keymap[key] = command
        elseif command then
            vim.api.nvim_echo({{"Sacrilege: Invalid command type for key "..key, "WarningMsg"}}, true, {})
        end
    end

    for key, action in pairs(mapping) do
        local command = config.actions[normalize(action)] or action

        if type(command) ~= "table" then
            command = { key = command }
        end

        if key:match("Arrow>") then
            assign(key:gsub("Arrow>", "Left>"),  command.left  or command.key)
            assign(key:gsub("Arrow>", "Right>"), command.right or command.key)
            assign(key:gsub("Arrow>", "Up>"),    command.up    or command.key)
            assign(key:gsub("Arrow>", "Down>"),  command.down  or command.key)
        elseif key:match("Mouse>") then
            assign(key,                          command.mouse or command.key)
            assign(key:gsub("Mouse", "Drag"),    command.drag)
            assign(key:gsub("Mouse", "Release"), command.release)
        else
            assign(key, command.key)
        end
    end

    return keymap
end

local function augroup(name, autocmd)
    vim.cmd('augroup '..name..'\nautocmd!\n'..autocmd..'\naugroup end')
end

function M.enabled()
    return enabled
end

function M.enable()
    keymap  = configure(config.mapping)
    enabled = true

    for key, command in pairs(keymap) do
        input.map(key, command)
    end

    augroup('SacrilegeMode', "autocmd BufEnter,CmdlineLeave * lua require('sacrilege').callback.buffer_changed()")
    augroup('NeophyteMode',  "autocmd CursorHold * lua require('sacrilege').callback.cursor_hold()")
end

function M.disable()
    augroup('SacrilegeMode', '')
    augroup('NeophyteMode',  '')

    for key, _ in pairs(keymap) do
        input.unmap(key)
    end

    keymap  = { }
    enabled = false
end

function M.trigger(action)
    local command = config.actions[normalize(action)] or action
    if command then
        input.send(command)
    end
end

M.callback = { }

function M.callback.buffer_changed()
    vim.opt.insertmode = vim.bo.modifiable and
                         not vim.bo.readonly and
                         vim.bo.buftype ~= 'nofile' or
                         vim.bo.buftype == 'terminal'
end

function M.callback.cursor_hold()
    if vim.bo.modifiable and not vim.bo.readonly and vim.bo.buftype ~= 'nofile' then
        M.trigger('vimkeyhelp')
    end
end

-- Desecrate Vim using the provided configuration options
function M.setup(override)
    -- TODO: Check supported versions
    -- if vim.fn.has('nvim-0.5') ~= 1 then
    --     vim.api.nvim_err_writeln('sacrilege is only available for Neovim versions 0.5 and above')
    --     return
    -- end

    -- TODO: Detect plugins
    -- local hasPlugin = package.loaded['plugin/id']

    -- TODO: Setup default actions into config

    -- Merge configuration
    if override then
        if override.actions then
            for action, command in pairs(override.actions) do
                config.actions[normalize(action)] = command
            end
        end

        if override.mapping then
            for key, action in pairs(override.mapping) do
                config.mapping[key] = action
            end
        end

        if override.options then
            vim.tbl_deep_extend('force', config.options, override.options)
        end
    end

    -- Desecrate Vim
    if config.options.automatic then
        M.enable()
    end
end

return M