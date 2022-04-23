local M = { keymap = { }, popup = { } }

-- Vim map modes
--
-- ''   Normal, Visual, Select, Operator-pending
-- a    Normal, Visual, Select, Operator-pending, Insert, Command-line  (Menu only)
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

local modes = {
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
    ['R']         = 'R',  -- Replace |R|
    ['Rc']        = 'R',  -- Replace mode completion |compl-generic|
    ['Rx']        = 'R',  -- Replace mode |i_CTRL-X| completion
    ['Rv']        = 'R',  -- Virtual Replace |gR|
    ['Rvc']       = 'R',  -- Virtual Replace mode completion |compl-generic|
    ['Rvx']       = 'R',  -- Virtual Replace mode |i_CTRL-X| completion
    ['c']         = 'c',  -- Command-line editing
    ['cv']        = 'c',  -- Vim Ex mode |gQ|
    ['r']         = 'r',  -- Hit-enter prompt
    ['rm']        = 'r',  -- The -- more -- prompt
    ['r?']        = 'r',  -- A |: confirm| query of some sort
    ['!']         = '!',  -- Shell or external command is executing
    ['t']         = 't'   -- Terminal mode: keys go to the job
}

function M.get()
    return modes[vim.api.nvim_get_mode().mode]
end

function M.keymap.get()
    local mode = modes[vim.api.nvim_get_mode().mode]

    if mode == 'r' or mode == 'R' or mode == '!' then
        return nil
    end

    return mode
end

function M.popup.get()
    local mode = modes[vim.api.nvim_get_mode().mode]

    if mode == 'r' or mode == 'R' or mode == '!' or mode == 't' then
        return nil
    end

    if mode == 'x' or node == 's' then
        return 'v'
    end

    return mode
end

return M