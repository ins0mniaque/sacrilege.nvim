local M = { }

local defaults = {
    autodetect = true
}

local plugins = {
    'browse',
    'clipboard',
    'filetype',
    'keymap',
    'netrw',
    'nvim-dap',
    'nvim-dap-ui',
    'nvim-tree',
    'spell',
    'termdebug',
    'vim-test',
    'vim-ultest'
}

local function has_command(name)
    return vim.fn.exists(':'..name) == 2
end

local function has_feature(name)
    return vim.fn.has(name) == 1
end

local function has_plugin(name)
    if packer_plugins and packer_plugins[name] then
        return true
    end

    -- TODO: Support other plugin managers

    return false
end

local function has_package(name)
    if package.loaded[name] or package.preload[name] then
        return true
    end

    for _, searcher in ipairs(package.searchers or package.loaders) do
        local ok, loader = pcall(searcher, name)
        if ok and type(loader) == 'function' then
            package.preload[name] = loader
            return true
        end
    end

    return false
end

function M.has(plugin)
    if     plugin == 'browse'      then return has_feature('browse')
    elseif plugin == 'clipboard'   then return true
    elseif plugin == 'filetype'    then return true
    elseif plugin == 'keymap'      then return true
    elseif plugin == 'netrw'       then return has_command('Explore')
    elseif plugin == 'nvim-dap'    then return has_plugin ('nvim-dap')   or
                                               has_package('dap')
    elseif plugin == 'nvim-dap-ui' then return has_plugin ('nvim-dap')   or
                                               has_package('dapui')
    elseif plugin == 'nvim-tree'   then return has_plugin ('nvim-tree')  or
                                               has_package('nvim-tree')  or
                                               has_command('NvimTree')
    elseif plugin == 'spell'       then return has_feature('spell')
    elseif plugin == 'termdebug'   then return has_command('Termdebug')
    elseif plugin == 'vim-test'    then return has_plugin ('vim-test')   or
                                               has_command('TestSuite')
    elseif plugin == 'vim-ultest'  then return has_plugin ('vim-ultest') or
                                               has_package('ultest')     or
                                               has_command('Ultest')
    end

    return false
end

-- TODO: Setup menu lazy loading
-- augroup SetupLazyloadMenus
--     au!
--     au CursorHold,CursorHoldI * call <SID>SetupLazyloadMenus() | au! SetupLazyloadMenus
-- augroup END

-- TODO: Setup buffer handling
--     vim.cmd([[
-- augroup SacrilegeFileType
-- autocmd!
-- autocmd BufNewFile,BufRead,FileType * lua require('sacrilege.menu.context').context(vim.fn.expand('<abuf>'))
-- autocmd BufEnter * lua require('sacrilege.menu.context').show(vim.fn.expand('<abuf>'))
-- augroup end
-- ]])

function M.setup(override)
    local config = vim.tbl_deep_extend('force', defaults, override or { })

    for key, value in pairs(config) do
        if type(key) == 'number' then
            config[key]   = nil
            config[value] = { }
        end
    end

    for _, plugin in ipairs(plugins) do
        local plugin_config = config[plugin]
        if not plugin_config and config.autodetect and M.has(plugin) then
            plugin_config = { }
        end

        if plugin_config then
            require('sacrilege.plugins.'..plugin).setup(plugin_config)
        end
    end
end

return M