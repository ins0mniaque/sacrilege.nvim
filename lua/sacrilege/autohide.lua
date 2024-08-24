local M = { }

local windows

local function mousemoved()
    local mouse = vim.fn.getmousepos()
    local size  = mouse.winid ~= 0 and windows[mouse.winid]

    if size then
        local width = vim.api.nvim_win_get_width(mouse.winid)
        if width == 1 then
            vim.api.nvim_win_set_width(mouse.winid, size[1])
            return
        end

        local height = vim.api.nvim_win_get_height(mouse.winid)
        if height == 1 then
            vim.api.nvim_win_set_height(mouse.winid, size[2])
            return
        end

        size[1] = width
        size[2] = height
    else
        for window, size in pairs(windows) do
            if vim.api.nvim_win_is_valid(window) then
                local width  = vim.api.nvim_win_get_width(window)
                local height = vim.api.nvim_win_get_height(window)
                if width ~= 1 and height ~= 1 then
                    size[1] = width
                    size[2] = height
                end

                vim.api.nvim_win_set_width(window, 1)
                if vim.api.nvim_win_get_width(window) ~= 1 then
                    vim.api.nvim_win_set_height(window, 1)
                end
            else
                windows[window] = nil
            end
        end
    end
end

local mousemove = vim.api.nvim_replace_termcodes("<MouseMove>", true, true, true)

local function setup()
    if windows then
        return
    end

    windows = { }

    local namespace = vim.api.nvim_create_namespace("sacrilege/autohide")

    vim.o.mousemoveevent = true

    vim.on_key(function(_, typed)
        if typed == mousemove then
            mousemoved()
        end
    end, namespace)
end

function M.disable(window)
    if not window or window == 0 then
        window = vim.api.nvim_get_current_win()
    end

    if windows and windows[window] then
        local size = windows[window]

        vim.api.nvim_win_set_width(window, size[1])
        vim.api.nvim_win_set_height(window, size[2])

        windows[window] = nil
    end
end

function M.enable(window)
    if not window or window == 0 then
        window = vim.api.nvim_get_current_win()
    end

    setup()

    windows[window] = { vim.api.nvim_win_get_width(window),
                        vim.api.nvim_win_get_height(window) }
end

function M.toggle(window)
    if not window or window == 0 then
        window = vim.api.nvim_get_current_win()
    end

    if windows and windows[window] then
        M.disable(window)
    else
        M.enable(window)
    end
end

return M
