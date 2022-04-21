local M = { }

local defaults = {
    preset = nil,
    insertmode = nil,
    mousemodel = nil,
    menubar = '',
    popup = { '$(BufType)', '$(FileType)', 'PopUp' },
    context = { '$(BufType)', '$(FileType)', bind = true },
    toolbar = false,
    bind =  { },
    menus = { }
}

-- TODO: Move
function M.os()
    local uname = vim.loop.os_uname()

    if     uname.sysname:find('Windows') then return 'Windows'
    elseif uname.sysname == 'Darwin'     then return 'macOS'
    else                                      return uname.sysname
    end
end

function M.setup(override)
    -- TODO: Check supported versions
    -- if vim.fn.has('nvim-0.5') ~= 1 then
    --     vim.api.nvim_err_writeln('sacrilege is only available for Neovim versions 0.5 and above')
    --     return
    -- end

    local config = defaults;

    if override and type(override) == 'string' then
        override = { preset = override }
    end

    -- TODO: Allow presets outside 'sacrilege.presets.'
    if override and override.preset then
        local exists, preset = pcall(require, 'sacrilege.presets.'..override.preset:lower())
        if exists then
            config = vim.tbl_deep_extend('force', config, preset.setup(config.os or M.os()))
        else
            vim.api.nvim_err_writeln('Preset \''..config.preset..'\' not found')
        end
    end

    config = vim.tbl_deep_extend('force', config, override or { })

    -- TODO: Detect plugins
    -- local hasPlugin = package.loaded['user/repository']

    -- TODO: Integrate with plugins

    -- TODO: config.remap option
    -- TODO: option to bind context menus

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

    if config.bind then
        local menu = require('sacrilege.menu')

        for _, name in pairs(config.bind) do
            menu.bind(name)
        end
    end

    -- TODO: Config
    if config.context then
        require('sacrilege.menu.context').setup()
    end

    -- Desecrate Vim
    if config.insertmode ~= false then
        require('sacrilege.insertmode').enable()
    end
end

return M