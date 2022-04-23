local M = { }

local enabled  = false
local defaults = { }

local function augroup(name, autocmd)
    vim.cmd('augroup '..name..'\nautocmd!\n'..autocmd..'\naugroup end')
end

function M.enable()
    if enabled then
        do return end
    end

    defaults.insertmode                 = vim.opt.insertmode
    defaults.lsp_on_publish_diagnostics = vim.lsp.diagnostic.on_publish_diagnostics

    vim.lsp.handlers['textDocument/publishDiagnostics'] =
        vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, { update_in_insert = true })

    -- TODO: autocmd ModeChanged "advanced" mode, forward normal/cmd/macro modes to something else
    augroup('SacrilegeInsertMode', "autocmd BufEnter,BufLeave,CmdlineLeave * lua vim.defer_fn(require('sacrilege.insertmode').trigger, 0)")

    vim.defer_fn(require('sacrilege.insertmode').trigger, 0)

    enabled = true
end

function M.disable()
    if not enabled then
        do return end
    end

    augroup('SacrilegeInsertMode', '')

    vim.opt.insertmode                                  = defaults.insertmode
    vim.lsp.handlers['textDocument/publishDiagnostics'] = defaults.lsp_on_publish_diagnostics

    enabled  = false
    defaults = { }
end

function M.trigger()
    vim.opt.insertmode = vim.bo.modifiable and
                         not vim.bo.readonly and
                         vim.bo.buftype ~= 'nofile' or
                         vim.bo.buftype == 'terminal'
end

return M