local M = { }

function M.new(plugin, root)
    return
    {
        load = function(modname)
            modname = root and modname and string.format('%s.%s', root, modname) or modname or root

            local ok, module = pcall(require, modname)
            if ok then
                return module
            else
                return require("sacrilege.editor").notify("Plugin " .. (plugin or modname) .. " is not installed", vim.log.levels.WARN)
            end
        end,

        try = function(self, modname, func)
            if not func then
                func    = modname
                modname = nil
            end

            return function()
                local module = self.load(modname)

                if module then
                    func(module)
                end
            end
        end
    }
end

return M
