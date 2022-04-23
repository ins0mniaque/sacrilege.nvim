local M = { }

local function totitle(opts)
    return opts.title  or
           opts.prompt and
           opts.prompt:gsub('%s*$', '')
                      :gsub(':$',   '') or
           nil
end

local function browse(opts, on_choice)
    vim.validate {
        opts      = { opts,      'table',    true  },
        on_choice = { on_choice, 'function', false }
    }

    local ok, file = pcall(vim.fn.browse,
                           opts.save     or 0,
                           totitle(opts) or '',
                           opts.initdir  or '',
                           opts.default  or '')

    on_choice(ok and file or nil)
end

local function browsedir(opts, on_choice)
    vim.validate {
        opts      = { opts,      'table',    true  },
        on_choice = { on_choice, 'function', false }
    }

    local ok, directory = pcall(vim.fn.browsedir,
                                totitle(opts) or '',
                                opts.initdir  or '')

    on_choice(ok and directory or nil)
end

function M.setup(override)
    if vim.fn.has('browse') ~= 1 then
        error('Browse feature is not available')
    end

    local ui = require('sacrilege.ui')

    ui.browse    = browse
    ui.browsedir = browsedir
end

return M