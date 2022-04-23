local M = { }

local defaults = {
    preset = nil,
    insertmode = nil,
    mousemodel = nil,
    menubar = '',
    popup = 'PopUp',
    toolbar = 'ToolBar',
    bind  = { },
    menus = { },
    plugins = { 'autodetect' }
}

local delayed = nil

function M.setup(override)
    -- TODO: Check supported versions
    -- if vim.fn.has('nvim-0.5') ~= 1 then
    --     vim.api.nvim_err_writeln('sacrilege is only available for Neovim versions 0.5 and above')
    --     return
    -- end

    -- NOTE: Delay until VimEnter to detect plugin managers
    if vim.v.vim_did_enter ~= 1 then
        vim.cmd('augroup SacrilegeSetup\nautocmd!\nautocmd VimEnter * lua require(\'sacrilege\').setup()\naugroup end')

        delayed = override
        do return end
    else
        vim.cmd('augroup! SacrilegeSetup')

        override = override or delayed
        delayed  = nil
    end

    local config = defaults;

    if override and type(override) == 'string' then
        override = { preset = override }
    end

    if override and override.preset then
        local preset = require('sacrilege.presets').load(override.preset)

        if preset then
            config = vim.tbl_deep_extend('force', config, preset)
        else
            vim.api.nvim_err_writeln('Preset \''..override.preset..'\' not found')
        end
    end

    config = vim.tbl_deep_extend('force', config, override or { })

    -- if config.plugins then
    --     require('sacrilege.plugins').setup(config.plugins)
    -- end

    if config.menus then
        local menu = require('sacrilege.menu')

        for _, menus in pairs(config.menus) do
            if type(menus) == 'string' then
                vim.cmd(menus)
            else
                menu.set(menus)
            end
        end
    end

    -- TODO: config.remap option

    if config.bind then
        local menu = require('sacrilege.menu')

        for _, name in pairs(config.bind) do
            menu.bind(name)
        end
    end

    -- Desecrate Vim
    if config.insertmode ~= false then
        require('sacrilege.insertmode').enable()
    end
end

return M