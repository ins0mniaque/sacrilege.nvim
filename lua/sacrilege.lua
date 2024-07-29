local M = { }

local defaults =
{
    insertmode = true,
    selectmode = true,
    mouse      = true
}

local options = { }

local metatable =
{
    __index = function(table, key)
        if     key == "insertmode" then return options.insertmode
        elseif key == "selectmode" then return options.selectmode
        elseif key == "mouse"      then return options.mouse
        else                            return rawget(table, key)
        end
    end,

    __newindex = function(table, key, value)
        if key == "insertmode" then 
            options.insertmode = value

            M.trigger()
        elseif key == "selectmode" or key == "mouse" then 
            vim.notify(key .. " cannot be changed after setup", vim.log.levels.ERROR, { title = "sacrilege.nvim" })
        else
            rawset(table, key, value)
        end
    end
}

setmetatable(M, metatable)

function M.setup(opts)
    if vim.fn.has("nvim-0.7.0") ~= 1 then
        return vim.notify("sacrilege.nvim requires Neovim >= 0.7.0", vim.log.levels.ERROR, { title = "sacrilege.nvim" })
    end

    options = vim.tbl_deep_extend("force", defaults, opts or { }) or { }

    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "TermLeave" },
    {
        group = vim.api.nvim_create_augroup("Sacrilege", { }),
        pattern = { "*" },
        callback = function(event)
            M.trigger()
        end
    })

    M.trigger()

    vim.keymap.set("i", "<Esc>", function() return options.insertmode and ""       or "<Esc>" end, { expr = true, desc = "Escape" })
    vim.keymap.set("i", "<C-c>", function() return options.insertmode and "<Esc>:" or "<C-c>" end, { expr = true, desc = "Command Mode" })

    if options.selectmode then
        vim.opt.keymodel   = { }
        vim.opt.selection  = "exclusive"
        vim.opt.selectmode = { "mouse", "key", "cmd" }

        vim.keymap.set({ "n", "i", "s" }, "<M-LeftMouse>", "<4-LeftMouse>", { desc = "Start block selection" })
        vim.keymap.set({ "n", "i", "s" }, "<M-LeftDrag>", "<LeftDrag>", { desc = "Block selection" })
        vim.keymap.set({ "n", "i", "s" }, "<M-LeftRelease>", "", { desc = "End block selection" })

        local function map_mode(mode, rhs, otherwise)
            return function() return vim.fn.mode() == mode and rhs or otherwise or "" end
        end

        local function map_arrow_selection(arrow)
            vim.keymap.set("i", "<S-" .. arrow .. ">", "<C-o>v<C-g><" .. arrow .. ">", { desc = "Select character" })
            vim.keymap.set("i", "<C-S-" .. arrow .. ">", "<C-o>v<C-g><C-" .. arrow .. ">", { desc = "Select word" })
            vim.keymap.set("i", "<M-S-" .. arrow .. ">", "<C-o><C-v><C-g><" .. arrow .. ">", { desc = "Block select character" })
            vim.keymap.set("i", "<C-M-S-" .. arrow .. ">", "<C-o><C-v><C-g><C-" .. arrow .. ">", { desc = "Block select word" })
            vim.keymap.set("s", "<S-" .. arrow .. ">", "<" .. arrow .. ">", { desc = "Select character" })
            vim.keymap.set("s", "<C-S-" .. arrow .. ">", "<C-" .. arrow .. ">", { desc = "Select word" })
            vim.keymap.set("s", "<M-S-" .. arrow .. ">", map_mode("\19", "<" .. arrow .. ">", "<C-o><C-v><C-g><" .. arrow .. "><C-g>"), { expr = true, desc = "Block select character" })
            vim.keymap.set("s", "<C-M-S-" .. arrow .. ">", map_mode("\19", "<C-" .. arrow .. ">", "<C-o><C-v><C-g><C-" .. arrow .. "><C-g>"), { expr = true, desc = "Block select word" })
            vim.keymap.set("s", "<" .. arrow .. ">", "<Esc><" .. arrow .. ">", { desc = "Stop selection" })
            vim.keymap.set("s", "<C-" .. arrow .. ">", "<Esc><C-" .. arrow .. ">", { desc = "Stop selection" })
        end

        map_arrow_selection("Up")
        map_arrow_selection("Down")
        map_arrow_selection("Left")
        map_arrow_selection("Right")
    end

    if options.mouse then
        vim.opt.mouse      = "a"
        vim.opt.mousemodel = "popup_setpos"

        pcall(vim.cmd.aunmenu, "PopUp.How-to\\ disable\\ mouse")
    end
end

function M.desecrate()
    if vim.bo.modifiable and
       not vim.bo.readonly and
       vim.bo.buftype ~= "nofile" or
       vim.bo.buftype == "terminal"
    then
        vim.cmd.startinsert()
    else
        vim.cmd.stopinsert()
    end
end

function M.trigger()
    if options.insertmode then
        vim.defer_fn(M.desecrate, 0)
    end
end

return M