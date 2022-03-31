local api = vim.api
local fn  = vim.fn

local M = { }

local enabled = false
local keymap  = { }

-- TODO: Rename methods and move to module
M.util = { }

local util = M.util

function M.util.normal(command)
    return "<C-\\><C-N><C-\\><C-N>"..(command or '')
end

function M.util.default(command)
    return "<C-\\><C-G>"..(command or '')
end

function M.util.single(command)
    return "<C-O>"..(command or '')
end

function M.util.cmd(command)
    return "<Cmd>"..command.."<CR>"
end

function M.util.lua(module, func)
    return func and util.cmd("lua require('"..module.."')."..func) or util.cmd(module)
end

-- TODO: Rename
local defaults = {
    actions = {
        newtab         = util.cmd("tabnew"),
        quit           = util.cmd("quitall"), -- TODO: Quit menu
        save           = util.cmd("update"),
        paste          = "<C-O>P",
        cut            = "<C-O>x",
        copy           = "<C-O>y",
        fileexplorer   = util.cmd("NvimTreeToggle"),
        commandpalette = util.cmd("Telescope"),
        open           = util.lua('telescope.builtin', 'find_files()'),
        close          = util.cmd("q"),
        find           = util.normal("/"),
        findprevious   = util.normal("gN"),
        findnext       = util.normal("gn"),
        undo           = "<C-O>u",
        redo           = "<C-O><C-r>",
        selectall      = util.normal("gggH<C-O>G"),
        blockselect    = { key     = util.normal("g<C-H>"),
                           -- TODO: Fix arrow block selection; needs stay in S-BLOCK for subsequent presses
                           -- left    = util.normal("g<C-H><S-Left>"),
                           -- right   = util.normal("g<C-H><S-Right>"),
                           -- up      = util.normal("g<C-H><S-Up>"),
                           -- down    = util.normal("g<C-H><S-Down>"),
                           mouse   = "<4-LeftMouse>",
                           drag    = "<LeftDrag>",
                           release = "" },
        -- TODO: Add viml commands
        vimkeyhelp     = util.cmd("WhichKey"),
        warnvimuser    = util.cmd("echomsg \"<Ctrl-L>:lua require('sacrilege').disable() to regain sanity\"")
    },

    -- TODO: Presets
    -- TODO: Special keys not mapped in every mode
    --       e.g. api.nvim_set_keymap('v', '<BS>', 'd', { noremap = true, silent = true })
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
            api.nvim_echo({{"Sacrilege: Invalid command type for key "..key, "WarningMsg"}}, true, {})
        end
    end

    for key, action in pairs(mapping) do
        local command = defaults.actions[normalize(action)] or action

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

-- TODO: Error handling
local function map(key, command)
    local options = { noremap = true, silent = true }

    api.nvim_set_keymap("n", key, command, options)
    api.nvim_set_keymap("i", key, command, options)
    api.nvim_set_keymap("x", key, command, options)
    api.nvim_set_keymap("s", key, command, options)
    api.nvim_set_keymap("c", key, command, options)
    api.nvim_set_keymap("o", key, "<C-C>"..command, options)
end

local function unmap(key)
    api.nvim_del_keymap("n", key)
    api.nvim_del_keymap("i", key)
    api.nvim_del_keymap("x", key)
    api.nvim_del_keymap("s", key)
    api.nvim_del_keymap("c", key)
    api.nvim_del_keymap("o", key)
end

local function augroup(name, autocmd)
    vim.cmd('augroup '..name..'\nautocmd!\n'..autocmd..'\naugroup end')
end

function M.enabled()
    return enabled
end

function M.enable()
    keymap  = configure(defaults.mapping)
    enabled = true

    for key, command in pairs(keymap) do
        map(key, command)
    end

    augroup('SacrilegeMode', "autocmd BufEnter,CmdlineLeave * lua require('sacrilege').callback.buffer_changed()")
    augroup('NeophyteMode',  "autocmd CursorHold * lua require('sacrilege').callback.cursor_hold()")
end

function M.disable()
    augroup('SacrilegeMode', '')
    augroup('NeophyteMode',  '')

    for key, _ in pairs(keymap) do
        unmap(key)
    end

    keymap  = { }
    enabled = false
end

function M.trigger(action)
    local command = defaults.actions[normalize(action)] or action
    if command then
        api.nvim_input(command)
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
function M.setup(config)
    -- TODO: Check supported versions
    -- if fn.has('nvim-0.5') ~= 1 then
    --     api.nvim_err_writeln('sacrilege is only available for Neovim versions 0.5 and above')
    --     return
    -- end

    -- TODO: Detect plugins
    -- local hasPlugin = package.loaded['plugin/id']

    -- TODO: Setup default actions into config

    -- TODO: Don't reuse defaults
    -- Merge configuration
    if config then
        if config.actions then
            for action, command in pairs(config.actions) do
                defaults.actions[normalize(action)] = command
            end
        end

        if config.mapping then
            for key, action in pairs(config.mapping) do
                defaults.mapping[key] = action
            end
        end

        if config.options then
            vim.tbl_deep_extend('force', defaults.options, config.options)
        end
    end

    -- Desecrate Vim
    if defaults.options.automatic then
        M.enable()
    end
end

return M