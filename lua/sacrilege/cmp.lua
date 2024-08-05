local cmp = require("cmp")

local function abort(fallback)
    if not cmp.abort() then
        fallback()
    end
end

local function complete(fallback)
    if not cmp.complete() then
        fallback()
    end
end

local function confirm(fallback)
    if not cmp.confirm({ select = false }) then
        fallback()
    end
end

local function select_and_confirm(fallback)
    if not cmp.confirm({ select = true }) then
        fallback()
    end
end

local function select_previous(fallback)
    if not cmp.select_prev_item() then
        local release = cmp.core:suspend()
        fallback()
        vim.schedule(release)
    end
end

local function select_next(fallback)
    if not cmp.select_next_item() then
        local release = cmp.core:suspend()
        fallback()
        vim.schedule(release)
    end
end

local defaults =
{
    completion = { completeopt = "menu,menuone,noinsert,noselect" },
    mapping =
    {
        ['<Esc>'] =
        {
            i = abort,
            c = abort
        },
        ['<C-Space>'] =
        {
            i = complete,
            c = complete
        },
        ['<CR>'] =
        {
            i = confirm,
            c = confirm
        },
        ["<Space>"] =
        {
            i = confirm,
            c = confirm
        },
        ["<Tab>"] =
        {
            i = select_and_confirm,
            c = select_and_confirm
        },
        ['<S-CR>'] =
        {
            i = select_and_confirm,
            c = select_and_confirm
        },
        ["<Up>"] =
        {
            i = select_previous,
            c = select_previous
        },
        ["<Down>"] =
        {
            i = select_next,
            c = select_next
        }
    }
}

return function(opts)
    return vim.tbl_deep_extend("force", defaults, opts or { })
end
