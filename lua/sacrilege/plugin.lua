local log = require("sacrilege.log")
local editor = require("sacrilege.editor")

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
                return log.warn("Plugin %s is not installed", plugin or modname)
            end
        end,

        try = function(self, modname, rhs)
            if not rhs then
                rhs     = modname
                modname = nil
            end

            if type(rhs) == "string" then
                local keys = rhs
                rhs = function() editor.send(keys) end
            end

            return function(...)
                local module = self.load(modname)

                if module then
                    return rhs(module, ...)
                end
            end
        end
    }
end

function M.vim(plugin, check)
    return
    {
        try = function(self, rhs)
            if type(rhs) == "string" then
                local keys = rhs
                rhs = function() editor.send(keys) end
            end

            return function(...)
                if check() then
                    return rhs(...)
                else
                    return log.warn("Plugin %s is not loaded", plugin)
                end
            end
        end
    }
end

return M
