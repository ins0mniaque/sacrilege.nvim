local M = { }

-- TODO: Validate options.commands
function M.apply(options)
    local plugin = require("sacrilege.plugin")

    local barbar = plugin.new("romgrk/barbar.nvim", "barbar")

    options.commands.tabpin:override(barbar:try("<Cmd>BufferPin<CR>"))
    options.commands.tabrestore:override(barbar:try("<Cmd>BufferRestore<CR>"))
    options.commands.tabclose:override(barbar:try("<Cmd>BufferClose<CR>"))
    options.commands.tabcloseall:override(barbar:try("<Cmd>BufferWipeout<CR>"))
    options.commands.tabcloseothers:override(barbar:try("<Cmd>BufferCloseAllButCurrent<CR>"))
    options.commands.tabcloseleft:override(barbar:try("<Cmd>BufferCloseBuffersLeft<CR>"))
    options.commands.tabcloseright:override(barbar:try("<Cmd>BufferCloseBuffersRight<CR>"))
    options.commands.tabcloseunpinned:override(barbar:try("<Cmd>BufferCloseAllButPinned<CR>"))

    options.commands.tabprevious:override(barbar:try("<Cmd>BufferPrevious<CR>"))
    options.commands.tabnext:override(barbar:try("<Cmd>BufferNext<CR>"))
    options.commands.tablast:override(barbar:try("<Cmd>BufferLast<CR>"))
    options.commands.tab1:override(barbar:try("<Cmd>BufferGoto 1<CR>"))
    options.commands.tab2:override(barbar:try("<Cmd>BufferGoto 2<CR>"))
    options.commands.tab3:override(barbar:try("<Cmd>BufferGoto 3<CR>"))
    options.commands.tab4:override(barbar:try("<Cmd>BufferGoto 4<CR>"))
    options.commands.tab5:override(barbar:try("<Cmd>BufferGoto 5<CR>"))
    options.commands.tab6:override(barbar:try("<Cmd>BufferGoto 6<CR>"))
    options.commands.tab7:override(barbar:try("<Cmd>BufferGoto 7<CR>"))
    options.commands.tab8:override(barbar:try("<Cmd>BufferGoto 8<CR>"))
    options.commands.tab9:override(barbar:try("<Cmd>BufferGoto 9<CR>"))
end

function M.autodetect()
    return pcall(require, "barbar") and true or false
end

return M
