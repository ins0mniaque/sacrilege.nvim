local M = { }

local function trigger()
    if vim.bo.modifiable and
       not vim.bo.readonly and
       vim.bo.buftype ~= 'nofile' or
       vim.bo.buftype == 'terminal'
    then
        vim.cmd('startinsert')
    else
        vim.cmd('stopinsert')
    end
end

function M.setup(override)
    if vim.fn.has("nvim-0.7.0") ~= 1 then
        return vim.notify("sacrilege.nvim requires Neovim >= 0.7.0", vim.log.levels.ERROR, { title = "sacrilege.nvim" })
    end

    local group = vim.api.nvim_create_augroup("Sacrilege", {})

    vim.api.nvim_create_autocmd({"BufEnter", "BufLeave", "CmdlineLeave"}, {
        group = group,
        pattern = {"*"},
        callback = function(event)
            vim.defer_fn(trigger, 0)
        end
    })

    vim.defer_fn(trigger, 0)

    vim.keymap.set('i', '<Esc>', "<Esc><Esc>:")
    vim.keymap.set('i', '<C-c>', "<Esc><Esc>:")
end

return M