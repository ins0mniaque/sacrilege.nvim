local commands = require('sacrilege.commands')
local presets  = require('sacrilege.presets')

local M = { }

local config = { mapping = { } }

local function augroup(name, autocmd)
    vim.cmd('augroup '..name..'\nautocmd!\n'..autocmd..'\naugroup end')
end

local function map(command, keys)
    local mapping = config.mapping[command]
    if not mapping then
        mapping = { }
        config.mapping[command] = mapping
    end

    if type(keys) == 'table' then
        for _, key in ipairs(keys) do
            table.insert(mapping, key)
        end
    else
        table.insert(mapping, keys)
    end
end

function M.enabled()
    return config.enabled
end

function M.enable()
    augroup('SacrilegeMode', "autocmd BufEnter,BufLeave,CmdlineLeave * lua vim.defer_fn(require('sacrilege').trigger, 0)")

    for command, keys in pairs(config.mapping) do
        for _, key in ipairs(keys) do
            commands.map(key, command)
        end
    end

    config.enabled = true
end

function M.disable()
    augroup('SacrilegeMode', '')

    for _, keys in ipairs(config.mapping) do
        for _, key in ipairs(keys) do
            commands.unmap(key)
        end
    end

    config.enabled = false
end

function M.trigger()
    vim.opt.insertmode = vim.bo.modifiable and
                         not vim.bo.readonly and
                         vim.bo.buftype ~= 'nofile' or
                         vim.bo.buftype == 'terminal'
end

-- Desecrate Vim using the provided configuration options
function M.setup(override)
    -- TODO: Check supported versions
    -- if vim.fn.has('nvim-0.5') ~= 1 then
    --     vim.api.nvim_err_writeln('sacrilege is only available for Neovim versions 0.5 and above')
    --     return
    -- end

    config   = { mapping = { } }
    override = override or { }

    -- TODO: Detect plugins
    -- local hasPlugin = package.loaded['user/repository']

    -- TODO: Integrate with plugins

    if override.commands then
        for name, command in pairs(override.commands) do
            commands.set(name, command)
        end
    end

    if override.preset ~= '' and override.preset ~= 'none' then
        local preset = presets[override.preset or 'default']
        if preset then
            for command, keys in pairs(preset) do
                map(command, keys)
            end
        else
            vim.api.nvim_err_writeln('Preset \''..override.preset..'\' not found')
        end
    end

    if override.mapping then
        for command, keys in pairs(override.mapping) do
            map(command, keys)
        end
    end

    -- Desecrate Vim
    if override.enabled ~= false then
        M.enable()
    end
end

return M