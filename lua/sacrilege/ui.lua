local M = { }

-- TODO: metatable, setting nil resets to default

local function toprompt(opts)
    return opts.prompt or
           opts.title  and
           opts.title:gsub('%.%.%.$',  '')
                     :gsub('(%w)$',    '%1:')
                     :gsub('([^%s])$', '%1 ') or
           nil
end

local function totitle(opts)
    return opts.title  or
           opts.prompt and
           opts.prompt:gsub('%s*$', '')
                      :gsub(':$',   '') or
           nil
end

function M.browse(opts, on_choice)
    vim.validate {
        opts      = { opts,      'table',    true  },
        on_choice = { on_choice, 'function', false }
    }

    if vim.fn.has('browse') == 1 then
        local ok, file = pcall(vim.fn.browse,
                               opts.save     or 0,
                               totitle(opts) or '',
                               opts.initdir  or '',
                               opts.default  or '')

        on_choice(ok and file or nil)
    else
        local cwd = nil
        if opts.initdir then
            cwd = vim.fn.getcwd()
            vim.api.nvim_set_current_dir(opts.initdir)
        end

        local options = {
            prompt     = toprompt(opts) or 'File: ',
            completion = 'file',
            default    = opts.default
        }

        M.input(options, on_choice)

        if opts.initdir then
            vim.api.nvim_set_current_dir(cwd)
        end
    end
end

function M.browsedir(opts, on_choice)
    vim.validate {
        opts      = { opts,      'table',    true  },
        on_choice = { on_choice, 'function', false }
    }

    if vim.fn.has('browse') == 1 then
        local ok, directory = pcall(vim.fn.browsedir,
                                    totitle(opts) or '',
                                    opts.initdir  or '')

        on_choice(ok and directory or nil)
    else
        local cwd = nil
        if opts.initdir then
            cwd = vim.fn.getcwd()
            vim.api.nvim_set_current_dir(opts.initdir)
        end

        local options = {
            prompt     = toprompt(opts) or 'Directory: ',
            completion = 'dir',
            default    = opts.default
        }

        M.input(options, on_choice)

        if opts.initdir then
            vim.api.nvim_set_current_dir(cwd)
        end
    end
end

function M.confirm(opts, on_confirm)
    vim.validate {
        opts       = { opts,       'table',    true  },
        on_confirm = { on_confirm, 'function', false }
    }

    opts = opts or { }

    if type(opts.choices) == 'table' then
        local choices = nil
        for _, choice in ipairs(opts.choices) do
            choices = choices and choices..'\n'..choice or choice
        end
        opts.choices = choices
    end

    local ok, choice = pcall(vim.fn.confirm,
                             opts.msg     or '',
                             opts.choices or '',
                             opts.default or '',
                             opts.type    or '')

    on_confirm(ok and choice > 0 and choice or nil)
end

-- TODO: Use vim.fn.input if vim.ui.input is not available
function M.input(opts, on_confirm)
    vim.validate {
        opts       = { opts,       'table',    true  },
        on_confirm = { on_confirm, 'function', false }
    }

    -- NOTE: If vim.ui.input is mapped to vim.fn.input, passing nil or { } as opts fails
    if opts == nil or vim.tbl_isempty(opts) then
        opts = vim.empty_dict()
    end

    local ok, _ = pcall(vim.ui.input, opts, on_confirm)
    if not ok then
        on_confirm(nil)
    end
end

function M.inputsecret(opts, on_confirm)
    vim.validate {
        opts       = { opts,       'table',    true  },
        on_confirm = { on_confirm, 'function', false }
    }

    opts = opts or { }

    local ok, secret = pcall(vim.fn.inputsecret,
                             opts.prompt  or '',
                             opts.default or '')

    on_confirm(ok and secret or nil)
end

-- TODO: Use vim.fn.inputlist if vim.ui.select is not available
function M.select(items, opts, on_choice)
    vim.validate {
        opts      = { opts,      'table',    true  },
        on_choice = { on_choice, 'function', false }
    }

    local ok, _ = pcall(vim.ui.select, items, opts, on_choice)
    if not ok then
        on_choice(nil)
    end
end

function M.notify(msg, log_level, opts)
    vim.validate {
        msg       = { msg,       'string', false },
        log_level = { log_level, 'string', true  },
        opts      = { opts,      'table',  true  }
    }

    if vim.in_fast_event() then
        vim.schedule(function()
            vim.notify(msg, log_level, opts)
        end)
    else
        vim.notify(msg, log_level, opts)
    end
end

-- TODO: Use :popup if available
function M.popup(name, opts)
    vim.validate {
        name = { name, 'string', true },
        opts = { opts, 'table',  true }
    }

    name = name or 'PopUp'
    name = name ~= '' and name..'.' or name

    local wildemenu = vim.api.nvim_replace_termcodes('<C-\\><C-N>:emenu '..name..'<Tab>', true, true, true)
    local wildcharm = vim.opt.wildcharm

    vim.opt.wildcharm=vim.fn.char2nr('^I')
    vim.fn.feedkeys(wildemenu, 't')
    vim.opt.wildcharm=wildcharm
end

return M