local window = { }

window.__index = window

-- TODO: Make local
windows = { }

local function serialize(value)
    local valueType = type(value)
    if valueType == 'table' then
        local table = '{ '

        local separator = ''
        for k, v in pairs(value) do
            table = table .. separator .. k .. ' = ' .. serialize(v)
            separator = ', '
        end

        return table .. ' }'
    elseif valueType == 'number' then
        return tostring(val)
    elseif valueType == 'string' then
        return string.format('%q', val)
    elseif valueType == 'boolean' then
        return value and 'true' or 'false'
    elseif valueType == 'nil' then
        return 'nil'
    end

    -- TODO: Error: cannot serialize valueType
    return 'nil'
end

-- TODO: Use serialize to pass arguments
local function cmd(self, callback, args)
    local index = #self.callback + 1
    self.callback[index] = callback
    return string.format('lua require(%q).event(%d, %d, { %s })', 'sacrilege.ui.window', self.id, index, args or '')
end

local function keycmd(self, key, callback)
    if key then
        -- Convert key to allow passing as keymap argument
        key = string.format('key = string.gsub(%q, %q, %q)', key:gsub('<([^<>]*)>', '«%1»'), '«([^«»]*)»', '<%1>')
    end

    return '<Cmd>'..cmd(self, callback, key)..'<CR>'
end

local function find(self)
    self = type(self) == 'table' and self or windows[tonumber(self)]

    if self and self.id and not vim.api.nvim_win_is_valid(self.id) then
        dispose(self)
    end

    if not self or not self.id or not self.buffer then
        return nil
    end

    return self
end

local function dispose(self)
    print('Disposing of '..tostring(self.id))

    vim.cmd('autocmd! * <buffer='..self.buffer..'>')

    if vim.api.nvim_win_is_valid(self.id) then
        vim.api.nvim_win_close(self.id, true)
    end

    windows[self.id] = nil

    self.id     = nil
    self.buffer = nil
end

local function create_buffer(config)
    config = vim.tbl_deep_extend('keep', config, { buftype = 'nofile', bufhidden = 'wipe' })

    local buffer = vim.api.nvim_create_buf(false, true)

    if config.lines then
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, config.lines)
        config.lines = nil
    end

    for option, value in pairs(config) do
        vim.api.nvim_buf_set_option(buffer, option, value)
    end

    return buffer
end

local function parse(config)
    local buffer = config.buffer
    local enter  = config.enter

    config.buffer = nil
    config.enter  = nil

    if type(buffer) == 'table' then
        buffer = create_buffer(buffer)
    end

    config = vim.tbl_deep_extend('keep', config, { style = 'minimal', relative = 'editor' })

    return { buffer = buffer, config = config, callback = { } }, enter or true
end

function window:new(config)
    local instance, enter = parse(config)

    -- TODO: Enter config not working
    instance.id = vim.api.nvim_open_win(instance.buffer, true, instance.config)

    windows[instance.id] = instance

    setmetatable(instance, window)

    instance:autocmd('BufHidden,BufLeave', dispose)

    return instance
end

function window:disposed()
    return not find(self)
end

function window:autocmd(event, callback)
    self = find(self)
    if not self then
        do return end
    end

    vim.cmd('autocmd '..event..' <buffer='..self.buffer..'>'..' '..cmd(self, callback))
end

function window:map(mode, key, callback, options)
    self = find(self)
    if not self then
        do return end
    end

    options = vim.tbl_deep_extend('keep', options or { }, { noremap = true, silent = true })

    vim.api.nvim_buf_set_keymap(self.buffer, mode, key, keycmd(self, key, callback), options)
end

function window:update(config)
    self = find(self)
    if not self then
        do return end
    end

    if config then
        self.config = vim.tbl_deep_extend('force', self.config, config)
    end

    vim.api.nvim_win_set_config(self.id, self.config)
end

function window:close(force)
    self = find(self)
    if not self then
        do return end
    end

    vim.api.nvim_win_close(self.id, force or true)
end

function window.find(id)
    return find(id)
end

function window.event(id, callback, args)
    self = find(id)
    if not self or not self.callback[callback] then
        do return end
    end

    local mouse = args.key and args.key:match('Mouse')

    if mouse then
        vim.api.nvim_input(args.key)
        vim.fn.getchar()

        args.id  = vim.v.mouse_winid
        args.row = vim.v.mouse_lnum - 1
        args.col = vim.v.mouse_col  - 1
    else
        args.id            = self.id
        args.row, args.col = vim.api.nvim_win_get_cursor(self.id)
    end

    self.callback[callback](self, args)
end

return window