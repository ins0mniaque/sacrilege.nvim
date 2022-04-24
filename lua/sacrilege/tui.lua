local menu = require('sacrilege.tui.menu')

local M = { menu = { }, toolbar = { } }

function M.menu.show(name, opts)
    menu.open()
end

function M.menu.hide(name, opts)
    menu.close()
end

function M.menu.toggle(name, opts)
    menu.open()
end

function M.toolbar.show(name, opts)

end

function M.toolbar.hide(name, opts)

end

function M.toolbar.toggle(name, opts)

end

function M.setup(override)
    -- TODO: Setup menu, toolbars and popups
    -- TODO: Integrate popup into ui module
end

return M