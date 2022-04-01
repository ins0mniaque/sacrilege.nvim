local M = { }

-- TODO: Implement conditional mapping

-- Vim map modes
--
-- ''   Normal, Visual, Select, Operator-pending
-- n    Normal
-- v    Visual and Select
-- s    Select
-- x    Visual
-- o    Operator-pending
-- !    Insert and Command-line
-- i    Insert
-- l    Insert, Command-line, input() line, search pattern, text argument of command
-- c    Command-line
-- t    Terminal

local ctrlS = string.char(19)
local ctrlV = string.char(22)

local keymodes = {
    ['n']         = 'n',  -- Normal
    ['no']        = 'o',  -- Operator-pending
    ['nov']       = 'o',  -- Operator-pending (forced charwise |o_v|)
    ['noV']       = 'o',  -- Operator-pending (forced linewise |o_V|)
    ['no'..ctrlV] = 'o',  -- Operator-pending (forced blockwise |o_CTRL-V|)
    ['niI']       = 'n',  -- Normal using |i_CTRL-O| in |Insert-mode|
    ['niR']       = 'n',  -- Normal using |i_CTRL-O| in |Replace-mode|
    ['niV']       = 'n',  -- Normal using |i_CTRL-O| in |Virtual-Replace-mode|
    ['nt']        = 't',  -- Normal in |terminal-emulator| (insert goes to Terminal mode)
    ['v']         = 'x',  -- Visual by character
    ['vs']        = 'x',  -- Visual by character using |v_CTRL-O| in Select mode
    ['V']         = 'x',  -- Visual by line
    ['Vs']        = 'x',  -- Visual by line using |v_CTRL-O| in Select mode
    [ctrlV]       = 'x',  -- Visual blockwise
    [ctrlV..'s']  = 'x',  -- Visual blockwise using |v_CTRL-O| in Select mode
    ['s']         = 's',  -- Select by character
    ['S']         = 's',  -- Select by line
    [ctrlS]       = 's',  -- Select blockwise
    ['i']         = 'i',  -- Insert
    ['ic']        = 'i',  -- Insert mode completion |compl-generic|
    ['ix']        = 'i',  -- Insert mode |i_CTRL-X| completion
    ['R']         = nil,  -- Replace |R|
    ['Rc']        = nil,  -- Replace mode completion |compl-generic|
    ['Rx']        = nil,  -- Replace mode |i_CTRL-X| completion
    ['Rv']        = nil,  -- Virtual Replace |gR|
    ['Rvc']       = nil,  -- Virtual Replace mode completion |compl-generic|
    ['Rvx']       = nil,  -- Virtual Replace mode |i_CTRL-X| completion
    ['c']         = 'c',  -- Command-line editing
    ['cv']        = 'c',  -- Vim Ex mode |gQ|
    ['r']         = nil,  -- Hit-enter prompt
    ['rm']        = nil,  -- The -- more -- prompt
    ['r?']        = nil,  -- A |: confirm| query of some sort
    ['!']         = nil,  -- Shell or external command is executing
    ['t']         = 't'   -- Terminal mode: keys go to the job
}

local function normalize(mode)
    return mode == '_' and '' or mode
end

local function unnormalize(mode)
    return mode == '' and '_' or mode
end

local function expand(mode)
    mode = normalize(mode)

    if     mode == ''  then return 'nxso'
    elseif mode == 'v' then return 'xs'
    elseif mode == '!' then return 'ic'
    elseif mode == 'l' then return 'icl'
    else                    return mode
    end
end

function M.get()
    return keymodes[vim.api.nvim_get_mode().mode];
end

function M.match(mode, other)
    mode  = unnormalize(mode)
    other = unnormalize(other)

    return mode == other or expand(mode):find('['..expand(other)..']')
end

function M.map(modes, key, input, options)
    for i = 1, #modes do
        vim.api.nvim_set_keymap(normalize(modes:sub(i,i)), key, input, options)
    end
end

function M.unmap(modes, key)
    for i = 1, #modes do
        vim.api.nvim_del_keymap(normalize(modes:sub(i,i)), key)
    end
end

return M