local M = { }

-- function M.escape() end
--   Closes quick fix, lists, floating windows and nofile buffers
--     See https://github.com/tombh/novim-mode/blob/master/autoload/novim_mode.vim
--   Opens menu if in insert mode (option = always, insertmode, no)
--   Sends Esc otherwise
-- function M.prompt() end  -- vim.cmd('confirm qall')
-- function M.confirm() end  -- vim.cmd('confirm qall')
-- function M.close() end
-- function M.quit() end

local function close_floating_windows()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if config.relative ~= "" then
            vim.api.nvim_win_close(win, false)
        end
    end
end

return M