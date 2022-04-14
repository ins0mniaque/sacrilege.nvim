local api = require('sacrilege.menu.api')

local M = { }

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

function M.execute(name, mode)
    mode = mode or modes[vim.api.nvim_get_mode().mode] or 'n'

    local menu = api.menu_get(name, mode)

    if menu and menu[1] and menu[1].mappings and menu[1].mappings[mode] then
        vim.input(menu[1].mappings[mode].rhs)
    end
end

return M