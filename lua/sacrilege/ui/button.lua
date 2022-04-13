local button = { }

button.__index = button

local function configure(config)
    config.accessor, _ = config.label:find('&', 1, true)
    config.label       = config.label:gsub('&', '')
    config.padding     = math.floor((config.width - config.label:len()) / 2)

    return config
end

function button:new(config)
    local instance = configure(config)

    instance.focused = instance.focused or false

    setmetatable(instance, button)

    return instance
end

function button:render()
    vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)

    self.ns_id = self.ns_id or vim.api.nvim_create_namespace('')

    vim.api.nvim_buf_clear_namespace(self.buffer, self.ns_id, 0, -1)
    vim.api.nvim_buf_set_text(self.buffer, self.row, self.col, self.row + self.height - 1, self.col + self.width - 1, { string.rep(' ', self.padding)..self.label })
    if self.accessor then
        vim.api.nvim_buf_add_highlight(self.buffer, self.ns_id, 'Title', self.row, self.col + self.accessor + self.padding - 1, self.col + self.accessor + self.padding)
    end
    if self.focused then
        vim.api.nvim_buf_add_highlight(self.buffer, self.ns_id, 'Search', self.row, self.col, self.col + self.width)
    end
    if self.pressed then
        vim.api.nvim_buf_add_highlight(self.buffer, self.ns_id, 'Search', self.row, self.col, self.col + self.width)
    end
    if self.toggled then
        vim.api.nvim_buf_add_highlight(self.buffer, self.ns_id, 'Search', self.row, self.col, self.col + self.width)
    end

    vim.api.nvim_buf_set_option(self.buffer, 'modifiable', false)
end

function button:update(config)
    if config then
        self.config = vim.tbl_deep_extend('force', self.config, configure(config))
        self:render()
    end
end

function button:focus()
    self.focused = true
    self:render()
end

function button:unfocus()
    self.focused = false
    self:render()
end

function button:click(args)
    self:press()
    self:release()
end

function button:press(args)
    self.pressed = true
    self:render()
end

function button:drag(args)
    -- TODO: Unpress when dragged outside
    self.pressed = true
    self:render()
end

function button:release(args)
    if self.pressed then
        self.pressed = false
        if self.toggle then
            self.toggled = not self.toggled
        end

        self:render()

        self.action(self.toggled)
    end
end

return button